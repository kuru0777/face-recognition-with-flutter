import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';

import '../ViewModel/face_match.dart';
import '../ViewModel/face_register.dart';
import 'constants/painter.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;

  late FaceDetector faceDetector;
  late Recognizer recognizer;

  ui.Image? image;
  List<Face> faces = [];

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

    final bytes = _image!.readAsBytesSync();
    image = await decodeImageFromList(bytes);

    faces = await faceDetector.processImage(inputImage);

    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;

      if (kDebugMode) {
        debugPrint("Bounding box: $boundingBox");
      }

      num left = boundingBox.left < 0 ? 0 : boundingBox.left;
      num top = boundingBox.top < 0 ? 0 : boundingBox.top;
      num right =
          boundingBox.right > image!.width ? image!.width - 1 : boundingBox.right;
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
      await _showFaceRegistrationDialog(
          Uint8List.fromList(img.encodeBmp(croppedFace)), recognition);
    }

    setState(() {});
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  Future<void> _showFaceRegistrationDialog(
      Uint8List croppedFace, Recognition recognition) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Detected", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: 600,
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.memory(croppedFace, width: 200, height: 200),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Number")),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "First Name")),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: _surnameController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Last Name")),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  try {
                    recognizer.registerFaceInDB(
                        _numberController.text,
                        _nameController.text,
                        _surnameController.text,
                        recognition.embedding);
                  } catch (e) {
                    debugPrint('Error registering face: $e');
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.amber,
                    content: Text(
                      "Face Saved",
                      style: TextStyle(color: Colors.black),
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(200, 40)),
                child: const Text("Save Face",
                    style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text("Face Registration"),
          backgroundColor: Colors.amber,
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              image != null
                  ? Container(
                      margin: const EdgeInsets.only(
                          top: 0, left: 30, right: 30, bottom: 0),
                      child: FittedBox(
                        child: SizedBox(
                          width: image!.width.toDouble(),
                          height: image!.height.toDouble(),
                          child: CustomPaint(
                            painter: FaceDetectPainter(
                                facesList: faces, imageFile: image),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              margin: const EdgeInsets.only(
                                  top: 60, left: 30, right: 30, bottom: 0),
                              child: SizedBox(
                                height: 300,
                                width: 300,
                                child:
                                    Lottie.asset('assets/images/face_r.json'),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Welcome to Face Registration",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Register a face by picking a photo from camera or gallery",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.amber,
          selectedIconTheme: const IconThemeData(color: Colors.black),
          unselectedIconTheme: const IconThemeData(color: Colors.black),
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          selectedFontSize: 12,
          onTap: (index) {
            if (index == 0) {
              _imgFromGallery();
            } else if (index == 1) {
              _imgFromCamera();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.image, size: 40),
              label: 'Pick from Gallery',
              tooltip: 'Pick a photo from gallery to register a face',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt, size: 40),
              label: 'Take Photo',
              tooltip: 'Take a photo to register a face',
            ),
          ],
        ));
  }
}
