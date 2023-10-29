import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final bool isEmailVerified;

  // auth user check the current auth user has his email verifies or not 
  const AuthUser(this.isEmailVerified);

// this is where we are coping the auth user to our own created user 
// this is like get the user from the fireBase but dress like the user we want AuthUser is the costume we designed but the body is of the firebase user ( actual user )
  factory AuthUser.fromFireBase(User user) => AuthUser(user.emailVerified);
}
