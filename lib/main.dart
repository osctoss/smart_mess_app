import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  try {
    if (!kIsWeb) {
       await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
      );
    }
  } catch (e) {
    debugPrint('App Check initialization failed: $e');
  }

  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
  }

  runApp(const SmartMessApp());
}
