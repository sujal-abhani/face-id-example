import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _cameraController;
  bool _processing = false;

  Future<void> init() async {
    try {
      if (_cameraController != null) {
        return;
      }

      final cameras = await availableCameras();
      var camera = cameras.firstWhereOrNull((e) => e.lensDirection == CameraLensDirection.front);

      if (camera == null) {
        throw Exception('No front camera found');
      }

      _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      if (_cameraController == null) {
        throw Exception('Camera controller not set');
      }
      // _cameraController!.lockCaptureOrientation(DeviceOrientation.la);
    } catch (e, s) {
      log('error while initializing camera service');
      log(e.toString());
    }
  }

  Future<void> startCamera() async {
    if (_cameraController == null) {}
    await _cameraController!.initialize();
  }

  void startImageStream(Future<void> Function(CameraImage image) onImage) {
    if (_cameraController == null) {
      throw Exception('Camera controller initiliazed');
    }
    _startImageStream(onImage);
  }

  void _startImageStream(Future<void> Function(CameraImage image) onImage) {
    _cameraController!.startImageStream((image) async {
      // if (_processing) return;
      // _processing = true;

      try {
        await onImage(image);
      } catch (e, s) {
        log('error processing frame');
        log('$e');
        log('strack $s');
      } finally {
        _processing = false;
      }
    });
  }

  Future<void> stopImageStream() async {
    if (_cameraController == null) {
      throw Exception('Camera controller initiliazed');
    }

    if (_cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
  }

  CameraController? get controller => _cameraController;

  Future<void> dispose() async {
    if (_cameraController == null) {
      return;
      // throw Exception('Camera controller initiliazed');
    }
    if (_cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
