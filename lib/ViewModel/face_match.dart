import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../Model/db.dart';
import 'face_register.dart';

class Recognizer {
  static const String _defaultModelAssetPath =
      'assets/model/mobilefacenet.tflite';

  late final InterpreterOptions _interpreterOptions;
  late final Future<void> _initFuture;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;

  final dbHelper = DatabaseHelper();
  Map<String, Recognition> registered = {};

  Recognizer({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();
    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }

    _initFuture = _init();
  }

  Future<void> ensureInitialized() => _initFuture;

  Future<void> _init() async {
    await loadModel();
    await initDB();
  }

  Future<void> initDB() async {
    await dbHelper.init();
    await loadRegisteredFaces();
  }

  Future<void> loadRegisteredFaces() async {
    registered.clear();
    final allRows = await dbHelper.queryAllRows();

    for (final row in allRows) {
      String name = row[DatabaseHelper.columnFirstName];
      String surname = row[DatabaseHelper.columnLastName];
      String fullName = '$name $surname';

      String embedding0 = row[DatabaseHelper.columnEmbedding];

      List<double> doubleList =
          embedding0.split(',').map((e) => double.parse(e.trim())).toList();

      Recognition recognition = Recognition(
          row[DatabaseHelper.columnFirstName], Rect.zero, doubleList, 0);
      registered.putIfAbsent(fullName, () => recognition);
    }
  }

  Future<void> registerFaceInDB(
      String number, String name, String surname, List<double> embedding) async {
    await dbHelper.registerFace(number, name, surname, embedding);
    await loadRegisteredFaces();
  }

  Future<void> loadModel() async {
    await close();

    final interpreter = await Interpreter.fromAsset(
      _defaultModelAssetPath,
      options: _interpreterOptions,
    );
    _interpreter = interpreter;

    _isolateInterpreter = await IsolateInterpreter.create(
      address: interpreter.address,
    );
  }

  List<dynamic> imageToArray(img.Image inputImage) {
    const int height = 112;
    const int width = 112;
    const int channels = 3;

    final img.Image resizedImage =
        img.copyResize(inputImage, width: width, height: height);

    // MobileFaceNet expects NHWC float32 normalized to [-1, 1].
    final Float32List input = Float32List(1 * height * width * channels);
    int i = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = resizedImage.getPixel(x, y);
        input[i++] = ((p.r.toDouble()) - 127.5) / 127.5;
        input[i++] = ((p.g.toDouble()) - 127.5) / 127.5;
        input[i++] = ((p.b.toDouble()) - 127.5) / 127.5;
      }
    }

    return input.reshape([1, height, width, channels]);
  }

  Future<Recognition> recognize(img.Image image, Rect location) async {
    await ensureInitialized();

    final input = imageToArray(image);

    final isolateInterpreter = _isolateInterpreter;
    if (isolateInterpreter == null) {
      throw StateError('Recognizer model is not initialized.');
    }

    final List output = List.filled(192, 0.0).reshape([1, 192]);

    final runs = DateTime.now().millisecondsSinceEpoch;
    await isolateInterpreter.run(input, output);
    final run = DateTime.now().millisecondsSinceEpoch - runs;

    final embedding = (output.first as List)
        .map((e) => (e as num).toDouble())
        .toList(growable: false);

    debugPrint('Time to run inference: $run ms');

    final pair = findNearest(embedding);
    return Recognition(pair.number, location, embedding, pair.distance);
  }

  double cosineSimilarity(List<double> vector1, List<double> vector2) {
    if (vector1.length != vector2.length ||
        vector1.isEmpty ||
        vector2.isEmpty) {
      throw ArgumentError("Vectors must have equal non-zero length.");
    }

    double dotProduct = 0;
    for (int i = 0; i < vector1.length; i++) {
      dotProduct += vector1[i] * vector2[i];
    }

    double norm1 = vectorNorm(vector1);
    double norm2 = vectorNorm(vector2);

    return dotProduct / (norm1 * norm2);
  }

  double vectorNorm(List<double> vector) {
    double sum = 0;
    for (int i = 0; i < vector.length; i++) {
      sum += vector[i] * vector[i];
    }
    return sqrt(sum);
  }

  Pair findNearest(List<double> embedding) {
    Pair pair = Pair("Unknown Face", double.infinity);

    for (MapEntry<String, Recognition> item in registered.entries) {
      final String number = item.key;
      List<double> knownEmb = item.value.embedding;

      double distance = euclideanDistance(embedding, knownEmb);

      if (distance < pair.distance) {
        pair = Pair(number, distance);
      }
    }

    return pair;
  }

  double euclideanDistance(List<double> embedding, List<double> knownEmb) {
    double distance = 0;
    for (int i = 0; i < embedding.length; i++) {
      double diff = embedding[i] - knownEmb[i];
      distance += diff * diff;
    }
    distance = sqrt(distance);
    return distance;
  }

  Future<void> close() async {
    final isolateInterpreter = _isolateInterpreter;
    _isolateInterpreter = null;
    if (isolateInterpreter != null) {
      await isolateInterpreter.close();
    }

    final interpreter = _interpreter;
    _interpreter = null;
    interpreter?.close();
  }
}

class Pair {
  String number;
  double distance;
  Pair(this.number, this.distance);
}
