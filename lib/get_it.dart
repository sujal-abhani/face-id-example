import 'package:get_it/get_it.dart';
import 'package:workspace/camera_service.dart';
import 'package:workspace/face_id_service.dart';

final getIt = GetIt.instance;

void registerSingletons() {
  getIt.registerSingleton(FaceIdService());
  getIt.registerSingleton(CameraService());
}
