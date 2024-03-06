import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/studentModel.dart';

class StudentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get studentsCollection =>
      _firestore.collection('students');

  // Student ekleme
  Future<void> addStudent(StdModel student) async {
    await studentsCollection.add(student.toMap());
  }

  // Tüm studentları alma
  Stream<List<StdModel>> getAllStudents() {
    return studentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return StdModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Belirli ID'ye sahip studentı alma
  /* Future<StdModel?> getStudentById(String studentId) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await studentsCollection.doc(studentId).get();
    if (snapshot.exists) {
      return StdModel.fromMap(snapshot.data()!, snapshot.id);
    } else {
      return null;
    }
  }
*/
  // Student güncelleme
  Future<void> updateStudent(StdModel student) async {
    await studentsCollection.doc(student.id).update(student.toMap());
  }

  // Student silme
  Future<void> deleteStudent(String studentId) async {
    await studentsCollection.doc(studentId).delete();
  }
}
