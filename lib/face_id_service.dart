import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter_face_sdk/flutter_face_sdk.dart' as fsdk;
import 'package:flutter_face_sdk/converter.dart' as f_converter;

void faceProcessIsolateFunction(Map<String, dynamic> message) {
  final image = message['image'];
  final SendPort sendPort = message['sendPort'];
  fsdk.Image? fsdkImage;
  fsdk.FacePosition? fp;
  try {
    fsdkImage = fsdk.Image.fromHandle(image);

    if (Platform.isAndroid) {
      var rotatedImage = fsdkImage.rotate90(-1);
      fsdkImage.free();
      fsdkImage = rotatedImage;
    }

    fp = fsdkImage.detectFace();
    fp.free();
    fsdkImage.free();
    sendPort.send(null);
  } catch (e) {
    dev.log('error processing face id frame in isolate $e');
    fp?.free();
    fsdkImage?.free();
    sendPort.send(null);
  }
}

class FaceIdService {
  Isolate? _isolate;
  SendPort? _sendPort;
  bool _isolateReady = false;
  final _isolateInitPort = ReceivePort();
  final converter = f_converter.ImageConverter();
  late fsdk.Image _fsdkImage;

  void activate() {
    fsdk.ActivateLibrary('');
    fsdk.Initialize();
    fsdk.SetFaceDetectionParameters(true, true, 256);
  }

  Future<void> initIsolate() async {
    if (_isolateReady) return;
    _isolate = await Isolate.spawn(_isolateEntry, _isolateInitPort.sendPort);
    _sendPort = await _isolateInitPort.first as SendPort;
    _isolateReady = true;
  }

  static void _isolateEntry(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);
    isolateReceivePort.listen((message) {
      faceProcessIsolateFunction(message);
    });
  }

  Future<void> processInIsolate(CameraImage image) async {
    if (!_isolateReady || _sendPort == null) {
      throw Exception('Isolate not initialized. Call initIsolate() first.');
    }
    final responsePort = ReceivePort();
    _fsdkImage = converter.convert(image);
    _sendPort!.send({'image': _fsdkImage.handle, 'sendPort': responsePort.sendPort});
    await responsePort.first;
    responsePort.close();
    return;
  }
}
