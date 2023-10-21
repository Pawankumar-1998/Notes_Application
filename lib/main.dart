import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/firebase_options.dart';
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/register_view.dart';
import 'package:mynotes/views/verify_email_view.dart';
// import 'package:mynotes/views/login_view.dart';

void main() {
  // widget binding inplace
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    home: const HomePage(),

    // creating link between login and register so that user can navigate to the both screen
    routes: {
      '/login/': (context) => const LoginView(),
      '/register/': (context) => const RegisterView(),
    },
  ));
}

// this is the code fot the home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              if (user.emailVerified) {
                print("You are good to go");
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            } 

            // // adding the code for the verification
            // print(user);
            // if (user?.emailVerified ?? false) {
            //   return const Text("Done");
            // } else {
            //   return const VerifyEmailView();
            // }
            return const Text("done");
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}
