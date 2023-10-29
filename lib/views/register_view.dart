// below is the code for the registration view
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exception.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                hintText: "Enter your email address here "),
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
                await AuthService.firebase().createUser(
                  email: email,
                  password: password,
                );

                await AuthService.firebase().sendEmailVerification();
                // if the compiler hits this line means user has entered a valid email and password
                //  we need to send the user to the register view
                Navigator.of(context).pushNamed(verifyEmailRoute);
              } on WeakPasswordAuthException{
                await showErrorDialog(
                    context,
                    "weak password",
                  );
              } on EmailAlreadyInUseAuthException{
                   await showErrorDialog(
                    context,
                    "email-already-in-use",
                  );
              } on InvalidEmailAuthException{
                 await showErrorDialog(
                    context,
                    "Please enter valid email address",
                  );
              } on GenericAuthException{
                  await showErrorDialog(
                  context,
                  'Failed to register',
                );
              }
            },
            child: const Text("Register"),
          ),

          // adding the button to link to the login view
          TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              },
              child: const Text("Already registered? login "))
        ],
      ),
    );
  }
}
