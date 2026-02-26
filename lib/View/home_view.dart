import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../ViewModel/face_match.dart';
import 'face_match_view.dart';
import 'face_register_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Recognizer _recognizer = Recognizer();

  void _showRegisteredFaces() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Faces"),
            content: SizedBox(
              height: 800,
              width: 400,
              child: ListView.builder(
                  itemCount: _recognizer.registered.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title:
                          Text(_recognizer.registered.keys.elementAt(index)),
                      subtitle: Text(_recognizer.registered.values
                          .elementAt(index)
                          .embedding
                          .toString()),
                    );
                  }),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Recognition App"),
        backgroundColor: Colors.amber,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                await _recognizer.ensureInitialized();
                await _recognizer.loadRegisteredFaces();
                _showRegisteredFaces();
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
                child: Lottie.asset('assets/images/homescreen.json'),
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
                    child: const Text("Register Face",
                        style:
                            TextStyle(fontSize: 20, color: Colors.black))),
                const SizedBox(height: 40),
                TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(200, 40)),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const RecognitionScreen()));
                    },
                    child: const Text("Recognize Face",
                        style:
                            TextStyle(fontSize: 20, color: Colors.black))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
