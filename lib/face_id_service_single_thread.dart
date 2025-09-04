import 'dart:developer' as dev;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_face_sdk/flutter_face_sdk.dart' as fsdk;
import 'package:flutter_face_sdk/converter.dart' as f_converter;

final converter = f_converter.ImageConverter();

void faceProcessSingleThread(CameraImage image) {
  fsdk.Image? fsdkImage;
  fsdk.FacePosition? fp;
  try {
    fsdkImage = converter.convert(image);
    if (Platform.isAndroid) {
      var rotatedImage = fsdkImage.rotate90(-1);
      fsdkImage.free();
      fsdkImage = rotatedImage;
    }
    fp = fsdkImage.detectFace();
    fp.free();
    fsdkImage.free();
  } catch (e) {
    dev.log('error processing face id frame $e');
    fp?.free();
    fsdkImage?.free();
  }
}

class FaceIdServiceSingleThread {
  void activate() {
    fsdk.ActivateLibrary('');
    fsdk.Initialize();
    fsdk.SetFaceDetectionParameters(true, true, 256);
  }

  Future<void> process(CameraImage image) async {
    faceProcessSingleThread(image);
    return;
  }
}
