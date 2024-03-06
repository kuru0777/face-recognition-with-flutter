import 'package:face_recognition_project/ViewModel/face_match.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../Model/db.dart';
import 'face_match_view.dart';
import 'face_register_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Recognizer _recognizer = Recognizer();
  showdialog_all_emb_faces() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Yüzler"),
            content: SizedBox(
              height: 800,
              width: 400,
              child: ListView.builder(
                  itemCount: _recognizer.registered.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(_recognizer.registered.keys.elementAt(index)),
                      subtitle: Text(_recognizer.registered.values
                          .elementAt(index)
                          .embedding
                          .toString()),
                    );
                  }),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Kapat"))
            ],
          );
        });
  }

  fetchFromFirebase() async {
    FirebaseFirestore.instance
        .collection('students')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) {
                print(doc["name"]);
                print(doc["surname"]);
                print(doc["number"]);
                print(doc["embedding"]);
              })
            });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yüz Tanıma Uygulaması"),
        backgroundColor: Colors.amber,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                _databaseHelper.syncDB();
              },
              icon: const Icon(Icons.refresh_rounded)),
          IconButton(
              onPressed: () {
                showdialog_all_emb_faces();
              },
              icon: const Icon(Icons.list))
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
              height: 400,
              width: 400,
              child: FittedBox(
                child: Container(
                    child: Lottie.asset('assets/images/homescreen.json')),
              )),
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            child: Column(
              children: [
                TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(200, 40)),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const RegistrationScreen()));
                    },
                    child: const Text("Yüz Kayıt",
                        style: TextStyle(fontSize: 20, color: Colors.black))),
                Container(
                  height: 40,
                ),
                TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(200, 40)),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RecognitionScreen()));
                    },
                    child: const Text("Yüz Tanıma",
                        style: TextStyle(fontSize: 20, color: Colors.black))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
