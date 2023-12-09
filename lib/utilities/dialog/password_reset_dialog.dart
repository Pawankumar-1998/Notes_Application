import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialog/generic_dialog.dart';

Future<void> showPasswordResetSentDialog(BuildContext context) {
  return showGenericDialog(
    context: context,
    title: 'Reset Password ',
    content: 'Reset link has been sent to your email',
    optionsBuilder: () => {
      'OK': null,
    },
  );
}
