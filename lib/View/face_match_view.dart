import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';

import '../Model/db.dart';
import '../ViewModel/face_match.dart';
import '../ViewModel/face_register.dart';
import 'constants/painter.dart';
import 'facedetector.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  late FaceDetector faceDetector;
  late Recognizer recognizer;

  ui.Image? image;
  List<Face> faces = [];
  List<Recognition> recognitions = [];

  @override
  void initState() {
    super.initState();
    final options =
        FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
  }

  @override
  void dispose() {
    faceDetector.close();
    recognizer.close();
    super.dispose();
  }

  Future<void> _imgFromCamera() async {
    XFile? pickedFile =
        await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      setState(() {});
      await _doFaceDetection();
    }
  }

  Future<void> _imgFromGallery() async {
    XFile? pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      setState(() {});
      await _doFaceDetection();
    }
  }

  Future<void> _doFaceDetection() async {
    await recognizer.ensureInitialized();
    InputImage inputImage = InputImage.fromFile(_image!);
    recognitions.clear();

    final bytes = _image!.readAsBytesSync();
    image = await decodeImageFromList(bytes);

    faces = await faceDetector.processImage(inputImage);

    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;
      debugPrint("Bounding box: $boundingBox");

      num left = boundingBox.left < 0 ? 0 : boundingBox.left;
      num top = boundingBox.top < 0 ? 0 : boundingBox.top;
      num right = boundingBox.right > image!.width
          ? image!.width - 1
          : boundingBox.right;
      num bottom = boundingBox.bottom > image!.height
          ? image!.height - 1
          : boundingBox.bottom;
      num width = right - left;
      num height = bottom - top;

      img.Image? faceImg = img.decodeImage(bytes);
      img.Image croppedFace = img.copyCrop(faceImg!,
          x: left.toInt(),
          y: top.toInt(),
          width: width.toInt(),
          height: height.toInt());
      Recognition recognition = await recognizer.recognize(
        croppedFace,
        boundingBox,
      );
      if (recognition.distance > 1.25) {
        recognition.number = "Unknown Face";
      }
      recognitions.add(recognition);
      debugPrint('Name: ${recognition.number}');
    }

    setState(() {});
  }

  Future<void> _showRegisteredFacesInfo() async {
    final databaseHelper = DatabaseHelper();

    try {
      await databaseHelper.init();
      List<Map<String, dynamic>> allFaces = await databaseHelper.getAllFaces();
      debugPrint('Registered faces count: ${allFaces.length}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.amber,
        content: Text(
          "Registered Faces: ${allFaces.length}",
          style: const TextStyle(color: Colors.black),
        ),
      ));
    } catch (e) {
      debugPrint("Error listing faces: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Recognition"),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            onPressed: () async {
              bool deleteConfirmed = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Delete Saved Faces"),
                        content: const Text(
                            "Do you want to delete all saved faces?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;
              if (deleteConfirmed) {
                await _deleteAllFaces();
              }
            },
            icon: const Icon(Icons.delete_forever_outlined),
          ),
          IconButton(
            onPressed: () async {
              await _showRegisteredFacesInfo();
            },
            icon: const Icon(Icons.list),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              image != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                            top: 20,
                            left: 60,
                            right: 10,
                            bottom: 0,
                          ),
                          child: FittedBox(
                            child: SizedBox(
                              width: image!.width.toDouble() * 1.2,
                              height: image!.width.toDouble() * 1.2,
                              child: CustomPaint(
                                painter: FaceRecognitionPainter(
                                    facesList: recognitions,
                                    imageFile: image),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.amber,
                          width: screenWidth,
                          margin: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.3),
                          child: Center(
                            child: Text(
                              recognitions.isNotEmpty
                                  ? recognitions
                                      .map((r) => r.number)
                                      .join(", ")
                                  : "Unknown Face",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      margin: const EdgeInsets.only(top: 60),
                      child: SizedBox(
                        height: 300,
                        width: 300,
                        child: Lottie.asset('assets/images/face_r.json'),
                      ),
                    ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          if (index == 0) {
            _imgFromGallery();
          } else if (index == 1) {
            _imgFromCamera();
          } else if (index == 2) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const FaceDetectorView()));
          }
        },
        backgroundColor: Colors.amber,
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.black,
        selectedFontSize: 15,
        unselectedFontSize: 15,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.image, size: 40),
            label: 'Pick from Gallery',
            tooltip: 'Recognize faces from a gallery photo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, size: 40),
            label: 'Take Photo',
            tooltip: 'Recognize faces from a camera photo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, size: 40),
            label: 'Live Camera',
            tooltip: 'Recognize faces in real-time',
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllFaces() async {
    final databaseHelper = DatabaseHelper();
    try {
      await databaseHelper.init();
      int recordCount = await databaseHelper.queryRowCount();
      if (recordCount > 0) {
        await databaseHelper.deleteAllRow();
        debugPrint('All faces deleted');
      } else {
        debugPrint('No faces to delete');
      }
    } catch (e) {
      debugPrint("Error deleting faces: $e");
    }
  }
}
