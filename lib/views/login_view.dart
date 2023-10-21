
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

//  this method is called first when the app is first build
  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  //  this method is used to destroye the object of the memory
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _email,
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          decoration:
              const InputDecoration(hintText: "Enter your email address here "),
        ),
        TextField(
          controller: _password,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration:
              const InputDecoration(hintText: "Enter your password here  "),
        ),
        TextButton(
          onPressed: () async {
            final email = _email.text;
            final password = _password.text;

            try {
              final userCredential = await FirebaseAuth.instance
                  .signInWithEmailAndPassword(email: email, password: password);
              print(userCredential);
            } on FirebaseAuthException catch (e) {
              if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
                print("User not found please register ");
              } else {
                print("Something else happened ");
                print(e.code);
              }
            }
          },
          child: const Text("Login"),
        ),
      ],
    );
  }
}
