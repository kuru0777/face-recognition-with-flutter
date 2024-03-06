import 'package:camera/camera.dart';
import 'package:face_recognition_project/View/face_match_live_view.dart';
import 'package:face_recognition_project/View/face_match_view.dart';
import 'package:face_recognition_project/View/facedetector.dart';
import 'package:face_recognition_project/View/register_page.dart';
import 'package:flutter/material.dart';
import 'View/home_view.dart';
import 'View/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      //options: DefaultFirebaseOptions.currentPlatform,
      );
  runApp(
    MaterialApp(
      color: Colors.amber,
      theme: ThemeData(primarySwatch: Colors.amber),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/homeScreen': (context) => const HomeScreen(),
        '/fromGalley': (context) => const RecognitionScreen(),
        '/fromLiveCamera': (context) => FaceDetectorView(),
      },
    ),
  );
}
