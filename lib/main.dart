import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workspace/camera_service.dart';
import 'package:workspace/face_id_service.dart';
import 'package:workspace/get_it.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerSingletons();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CameraPage());
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final cameraService = getIt<CameraService>();
  final faceIdService = getIt<FaceIdService>();
  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!(cameraService.controller?.value.isInitialized ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(body: CameraPreview(cameraService.controller!));
  }

  void init() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      return;
    }
    faceIdService.activate();
    await faceIdService.initIsolate();
    await cameraService.init();
    await cameraService.startCamera();
    cameraService.startImageStream((image) async {
      faceIdService.processInIsolate(image);
    });
    setState(() {});
  }
}
