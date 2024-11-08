// ignore_for_file: prefer-match-file-name
@JS()
library;

import 'dart:math';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@anonymous
class BpmnOptions {
  external String get container;
  external factory BpmnOptions({container});
}

@JS()
@anonymous
class SaveXMLOptions {
  external bool get format;
  external factory SaveXMLOptions({format});
}

@JS()
@anonymous
class SaveSvgOptions {
  external bool get format;
  external factory SaveSvgOptions({format});
}

@JS()
@anonymous
class CanvasViewbox {
  external int get x;
  external int get y;
  external int get width;
  external int get height;

  external factory CanvasViewbox({x, y, width, height});
}

extension Compare on CanvasViewbox {
  bool compareTo(CanvasViewbox other) {
    if (x == other.x &&
        y == other.y &&
        width == other.width &&
        height == other.height) {
      return true;
    }
    return false;
  }
}

@JS()
@anonymous
class BpmnCanvas {
  external factory BpmnCanvas();

  // ignore: no-object-declaration
  external Object zoom([
    Object type,
    Point point,
  ]);

  external CanvasViewbox viewbox([CanvasViewbox viewbox]);
}

extension BpmnCanvasUtils on BpmnCanvas {
  void fitViewport() {
    callMethod(this, "zoom", [
      "fit-viewport",
    ]);
  }

  void centerViewport() {
    callMethod(this, "zoom", [
      "center",
    ]);
  }

  void autoViewport() {
    callMethod(this, "zoom", [
      "auto",
    ]);
  }
}

@JS()
@anonymous
class BpmnSavedXmlResponse {
  external String get xml;
  external factory BpmnSavedXmlResponse();
}

@JS()
@anonymous
class BpmnSavedSvgResponse {
  external String get svg;
  external factory BpmnSavedSvgResponse();
}

@JS('BpmnJS')
class NavigatedViewer {
  external NavigatedViewer(BpmnOptions options);

  /// importXml - needed to display bpmn in html element.
  /// If you need to do something with NavigatedViewer after importing xml,
  /// Future must be used and the same NavigatedViewer (not the one returned
  /// from importXML).
  ///
  /// Example:
  ///   void importXML(String xml) {
  //     _navigator.importXML(xml);
  //     Future(() {
  //       final canvas = _navigator.get('canvas');
  //       canvas.zoom('fit-viewport');
  //     });
  //   }
  external Future<NavigatedViewer> importXML(String xml);

  external Future<BpmnSavedXmlResponse> saveXML(SaveXMLOptions options);
  external Future<BpmnSavedSvgResponse> saveSVG(SaveSvgOptions options);
}

extension NavigatedViewerUtils on NavigatedViewer {
  BpmnCanvas canvas() => callMethod(this, "get", ["canvas"]);
}

typedef OnCallbackCallback = Function(NavigatedViewer);

extension OnCallback on NavigatedViewer {
  void onViewboxChange(OnCallbackCallback callback) {
    callMethod(this, "on", [
      "canvas.viewbox.changed",
      allowInterop((_, __) {
        callback(this);
      }),
    ]);
  }

  void onImportRenderComplete(OnCallbackCallback callback) {
    callMethod(this, "on", [
      "import.render.complete",
      allowInterop((_, __) {
        callback(this);
      }),
    ]);
  }
}

/// It takes a NavigatedViewer and returns a Future that resolves to the
/// XML of the modeler.
///
/// Args:
///   viewer (NavigatedViewer): The NavigatedViewer instance
Future<String> getXmlFromViewer(NavigatedViewer viewer) async =>
    promiseToFuture(viewer.saveXML(SaveXMLOptions(format: true)))
        .then((response) => response.xml);

/// It takes a NavigatedViewer and returns a Future that resolves to
/// a String containing the SVG.
///
/// Args:
///   viewer (NavigatedViewer): The NavigatedViewer object from which you
///   want to get the SVG.
Future<String> getSvgFromViewer(NavigatedViewer viewer) async =>
    promiseToFuture(viewer.saveSVG(SaveSvgOptions(format: true)))
        .then((response) => response.svg);

/// It sets the viewbox of the canvas to be centered around the given point.
///
/// Args:
///   point (Point): The point around which the viewbox should be centered.
///   canvas (BpmnCanvas): The canvas that you want to set the viewbox for.
Future<void> setViewboxCenteredAroundPoint(
  Point point,
  BpmnCanvas canvas,
) async {
  // get cached viewbox to preserve zoom
  final cachedViewbox = canvas.viewbox(),
      cachedViewboxWidth = cachedViewbox.width,
      cachedViewboxHeight = cachedViewbox.height;

  canvas.viewbox(CanvasViewbox(
    x: point.x - cachedViewboxWidth / 2, //ignore: no-magic-number
    y: point.y - cachedViewboxHeight / 2, // ignore: no-magic-number
    width: cachedViewboxWidth,
    height: cachedViewboxHeight,
  ));
}
