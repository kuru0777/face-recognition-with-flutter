import 'package:face_recognition_project/View/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../Model/userModel.dart';
import '../ViewModel/userViewModel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isRegistered = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordControllerr = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final UserController userController = UserController();

  Future<void> signUp() async {
    String password = passwordController.text;
    String email = emailController.text;
    String firstName = firstNameController.text;
    String lastName = lastNameController.text;

    UserModel userModel = UserModel(
      id: '',
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    User? user = await userController.signUp(userModel);

    if (user != null) {
      isRegistered = true;
      print('Kayıt başarılı: ${user.email}');
    } else {
      print('Kayıt başarısız');
    }
  }

  Future<void> navigateToLogin() async {
    await signUp();
    if (isRegistered) {
      Navigator.replace(context,
          oldRoute: ModalRoute.of(context)!,
          newRoute: MaterialPageRoute(builder: (context) => const LoginPage()));
    } else {
      print('kayıt: $isRegistered');
    }
  }

  Future<void> matchPass() async {
    String password = passwordController.text;
    String passwordd = passwordControllerr.text;
    if (password == passwordd) {
      Fluttertoast.showToast(
        msg: "şifreler eşleşti!",
      );
    } else {
      Fluttertoast.showToast(
        msg: "şifreler eşleşmedi!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    void navigateToLogin() async {
      await signUp();
      if (isRegistered) {
        Navigator.pushNamed(context, '/login');
      } else {
        print('kayıt: $isRegistered');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kaydol",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 200,
                  width: 200,
                  child: Lottie.asset(
                    'assets/images/face_r.json',
                    repeat: false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: passwordControllerr,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre Tekrar',
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(150, 40)),
                onPressed: navigateToLogin,
                child: const Text(
                  'Kaydol',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
