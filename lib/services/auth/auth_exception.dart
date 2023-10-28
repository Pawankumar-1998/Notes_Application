//  these below exceptions are from the login exception 

class UserNotFoundAuthException implements Exception{}

class WrongPasswordAuthException implements Exception{}

//  these below exceptions are from the register exception

class WeakPasswordAuthException implements Exception{}

class EmailAlreadyInUseAuthException implements Exception{}

class InvalidEmailAuthException implements Exception{}

// generic auth exception

class GenericAuthException implements Exception{}


class UserNotLoggedInAuthException implements Exception{}

