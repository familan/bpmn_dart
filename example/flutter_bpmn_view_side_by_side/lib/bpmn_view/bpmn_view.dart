import 'dart:async';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_html/html.dart';

import 'package:bpmn_dart/bpmnjs_navigated_viewer.dart';

import 'bloc/bpmn_view_bloc.dart';
import 'bpmn_view_footer.dart';

class BpmnView extends StatefulWidget {
  final BpmnViewBlocInterface bloc;
  final String? saveFileName;

  const BpmnView({
    super.key,
    required this.bloc,
    this.saveFileName,
  });

  @override
  State<BpmnView> createState() => _BpmnViewState();
}

class _BpmnViewState extends State<BpmnView> {
  late BpmnViewBlocInterface bpmnViewBloc;
  BpmnCanvas? bpmnCanvas;

  StreamSubscription<BpmnViewState>? streamSubscription;
  NavigatedViewer? navigatedViewer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bpmnViewBloc = widget.bloc;
    bpmnViewBloc.getController().add(const ReadXml());

    streamSubscription = bpmnViewBloc.getStream().listen((state) {
      if (state is ViewboxUpdate) {
        final viewer = navigatedViewer;
        if (viewer == null) return;
        final canvas = bpmnCanvas;
        if (canvas == null) return;

        final updatedViewbox = state.viewbox;
        final viewbox = canvas.viewbox();

        if (updatedViewbox.compareTo(viewbox)) return;
        canvas.viewbox(updatedViewbox);
      }
    });
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BpmnViewState>(
      stream:
          bpmnViewBloc.getStream().where((state) => state is XmlReadSuccessful),
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null) return Container();

        if (state is XmlReadSuccessful) {
          final xml = state.xml;
          final area = DivElement()
            ..style.position = "relative"
            ..style.left = "0"
            ..style.top = "0"
            ..style.right = "0"
            ..style.bottom = "0"
            ..style.width = '100%'
            ..style.height = '100%';

          final viewer = NavigatedViewer(BpmnOptions(container: area));
          navigatedViewer = viewer;

          final canvas = viewer.canvas();
          bpmnCanvas = canvas;

          final id = const Uuid().v4();

          ui.platformViewRegistry.registerViewFactory(id, (int viewId) => area);

          SchedulerBinding.instance.addPostFrameCallback((_) async {
            await viewer.importXML(xml);
            canvas.zoom('fit-viewport');

            viewer.onViewboxChange((_) {
              final canvas = bpmnCanvas;
              if (canvas == null) return;
              final viewbox = canvas.viewbox();

              final event = ViewboxChanged(viewbox: viewbox);
              bpmnViewBloc.getController().add(event);
            });
          });

          return Stack(
            children: [
              Positioned.fill(
                child: Column(
                  key: const Key("bpmn_view"),
                  children: [
                    Expanded(
                      child: HtmlElementView(
                        key: const Key("bpmn_view_area"),
                        viewType: id,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: BpmnViewFooter(
                  navigatedViewer: viewer,
                  saveFileName: widget.saveFileName,
                ),
              ),
            ],
          );
        }

        return Container();
      },
    );
  }
}
