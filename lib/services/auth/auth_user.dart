import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final bool isEmailVerified;
  const AuthUser(this.isEmailVerified);

// this is where we are coping the auth user to our own created user 
  factory AuthUser.fromFireBase(User user) => AuthUser(user.emailVerified);
}
