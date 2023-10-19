import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/firebase_options.dart';
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
  ));
}

// this is the code fot the home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              // adding the code for the verification
              final user = FirebaseAuth.instance.currentUser;
              if (user?.emailVerified ?? false) {
                print("You are a verified user ");
              } else {
                print("Your email isn't verified yet please verify ");
              }
              return const Text("Done");
            default:
              return const Text("Loading ...");
          }
        },
      ),
    );
  }
}
