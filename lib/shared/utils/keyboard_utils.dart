import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dismisses the active software keyboard and clears focus consistently.
void dismissKeyboard(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  FocusScope.of(context).unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}
