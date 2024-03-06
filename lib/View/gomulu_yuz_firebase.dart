/*
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

// Firebase'den yüz bilgisini almak için örnek kod (Firestore kullanılarak)
Future<Map<String, dynamic>> getFaceFromFirebase(String faceId) async {
  var faceData =
      await FirebaseFirestore.instance.collection('faces').doc(faceId).get();

  return faceData.data() as Map<String, dynamic>;
}

// Gömme vektörlerini karşılaştırmak için örnek kod (Euclidean Distance)
double calculateEuclideanDistance(List<double> vector1, List<double> vector2) {
  double sum = 0.0;
  for (int i = 0; i < vector1.length; i++) {
    sum += (vector1[i] - vector2[i]) * (vector1[i] - vector2[i]);
  }
  return sqrt(sum);
}

// Yüz tanıma işlemi
faceMatcher recognizeFaceFromFirebase(
    String faceId, img.Image image, Rect location) {
  // Yüz tespiti ve gömme vektörü elde etme işlemleri

  // Firebase'den yüz bilgisini al
  var firebaseFaceData = getFaceFromFirebase(faceId);

  // Karşılaştırma işlemi
  double distance = calculateEuclideanDistance(
    extractedFaceEmbedding,
    firebaseFaceData['embedding'].cast<double>(),
  );

  // Mesafe değerine göre tanıma yapma
  if (distance < threshold) {
    return faceMatcher(
        firebaseFaceData['number'], location, extractedFaceEmbedding, distance);
  } else {
    return faceMatcher(
        "Yüz Tanınmıyor", location, extractedFaceEmbedding, distance);
  }
}

class faceMatcher {
  String number;
  Rect location;
  List<double> embedding;
  double distance;
  faceMatcher(this.number, this.location, this.embedding, this.distance);
}
*/