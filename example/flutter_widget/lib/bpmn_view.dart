import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart' show PickedFile;
import 'package:universal_html/html.dart';
import 'package:uuid/uuid.dart';

import 'package:bpmn_dart/bpmnjs_navigated_viewer.dart';
// import 'package:bpmn_dart/bpmnjs_modeler.dart';

class BpmnView extends StatefulWidget {
  const BpmnView({super.key});

  @override
  State<BpmnView> createState() => _BpmnViewState();
}

class _BpmnViewState extends State<BpmnView> {
  late final String id;

  @override
  void initState() {
    super.initState();

    final area = DivElement()
      ..style.position = "relative"
      ..style.left = "0"
      ..style.top = "0"
      ..style.right = "0"
      ..style.bottom = "0"
      ..style.width = '100%'
      ..style.height = '100%';

    final viewer = NavigatedViewer(BpmnOptions(container: area));
    // final viewer = BpmnJS(BpmnOptions(container: area)); // modeler!

    id = const Uuid().v4();

    ui.platformViewRegistry.registerViewFactory(
      id,
      (int viewId) => area,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final xml = await getDiagramXml('diagram.bpmn');
      viewer
        ..importXML(xml)
        ..canvas().fitViewport();
    });
  }

  Future<String> getDiagramXml(String path) async {
    PickedFile localFile = PickedFile(path);
    return await localFile.readAsString(); // default encoding utf8
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key("bpmn_view"),
      children: [
        Expanded(
          child: HtmlElementView(
            key: const Key("bpmn_view_area"),
            viewType: id,
          ),
        ),
      ],
    );
  }
}
