import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialog/generic_dialog.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Logout',
    content: 'Are you sure to leave ?',
    optionsBuilder: () => {
      'Cancel': false,
      'Logout': true,
    },
  ).then((value) => value ?? false);
}
