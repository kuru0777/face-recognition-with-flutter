import 'dart:io';
import 'package:face_recognition_project/Model/db.dart';
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
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _HomePageState();
}

class _HomePageState extends State<RegistrationScreen> {
  late ImagePicker imagePicker;
  File? _image;

  late FaceDetector faceDetector;
  late Recognizer recognizer;

  get widthh => image.width;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();

    final options =
        FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
  }

  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  _imgFromGallery() async {
    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  List<Face> faces = [];

  doFaceDetection() async {
    InputImage inputImage = InputImage.fromFile(_image!);
    image = await _image?.readAsBytes();
    image = await decodeImageFromList(_image!.readAsBytesSync());

    faces = await faceDetector.processImage(inputImage);

    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;

      if (kDebugMode) {
        print("RECTTTTT =$boundingBox");
      }

      num left = boundingBox.left < 0 ? 0 : boundingBox.left;
      num top = boundingBox.top < 0 ? 0 : boundingBox.top;
      num right =
          boundingBox.right > image.width ? image.width - 1 : boundingBox.right;
      num bottom = boundingBox.bottom > image.height
          ? image.height - 1
          : boundingBox.bottom;
      num width = right - left;
      num height = bottom - top;

      final bytes = _image?.readAsBytesSync();
      img.Image? faceImg = img.decodeImage(bytes!);
      img.Image croppedFace = img.copyCrop(faceImg!,
          x: left.toInt(),
          y: top.toInt(),
          width: width.toInt(),
          height: height.toInt());
      Recognition recognition = recognizer.recognize(croppedFace, boundingBox);
      await showFaceRegistrationDialogue(
          Uint8List.fromList(img.encodeBmp(croppedFace)), recognition);
    }
    drawRectangleAroundFaces();
  }

  removeRotation(File inputImage) async {
    final img.Image? capturedImage =
        img.decodeImage(await File(inputImage.path).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    return await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
  }

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController surnameTextEditingController = TextEditingController();
  TextEditingController numberTextEditingController = TextEditingController();

  showFaceRegistrationDialogue(Uint8List cropedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yüz Algılandı", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: 600,
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Image.memory(
                cropedFace,
                width: 200,
                height: 200,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: numberTextEditingController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Numara")),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: nameTextEditingController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white, filled: true, hintText: "Ad")),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: surnameTextEditingController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Soyad")),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    recognizer.registerFaceFirebase(
                        numberTextEditingController.text,
                        nameTextEditingController.text,
                        surnameTextEditingController.text,
                        recognition.embedding);
                  } catch (e) {
                    print(e);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.amber,
                    content: Text(
                      "Yüz Kaydedildi",
                      style: TextStyle(color: Colors.black),
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(200, 40)),
                child: const Text("Yüzü Kaydet",
                    style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  var image;

  drawRectangleAroundFaces() async {
    print("${image.width}   ${image.height}");
    setState(() {
      image;
      faces;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text("Yüz Kayıt"),
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
                          width: widthh.toDouble(),
                          height: image.width.toDouble(),
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
                              "Yüz Kayıt Ekranına Hoşgeldiniz",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Kameradan veya Galeriden fotoğraf seçerek yüz kayıt işlemi gerçekleştirin",
                              style: TextStyle(
                                fontSize: 20,
                              ),
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
              backgroundColor: Colors.red,
              icon: Icon(Icons.image, size: 40),
              label: 'Galeriden Seç',
              tooltip:
                  'Galeriden fotoğraf seçerek yüz kayıt işlemi gerçekleştirin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt, size: 40),
              label: 'Fotoğraf Çek',
              tooltip:
                  'Kameranızdan fotoğraf çekerek yüz kayıt işlemi gerçekleştirin',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            try {
              DatabaseHelper dbHelper = DatabaseHelper();
              await dbHelper.init();
              List<Map<String, dynamic>> faces = await dbHelper.getAllFaces();
              print(faces);
            } catch (e) {
              print(e);
            }
          },
          child: const Icon(Icons.face),
          backgroundColor: Colors.amber,
        ));
  }
}
