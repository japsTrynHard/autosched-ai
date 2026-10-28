import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/auth_gate.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  runApp(const AuthGate());
}
