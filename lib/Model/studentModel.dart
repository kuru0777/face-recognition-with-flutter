import 'dart:ffi';

class StdModel {
  final String id;
  final String stdNumber;
  final String firstName;
  final String lastName;
  List<Double> embFace = [];

  StdModel({
    required this.id,
    required this.stdNumber,
    required this.firstName,
    required this.lastName,
    required this.embFace,
  });

  factory StdModel.fromMap(Map<String, dynamic> data, String id) {
    return StdModel(
      id: id,
      stdNumber: data['stdNumber'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      embFace: data['embFace'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stdNumber': stdNumber,
      'firstName': firstName,
      'lastName': lastName,
      'embFace': embFace,
    };
  }
}
