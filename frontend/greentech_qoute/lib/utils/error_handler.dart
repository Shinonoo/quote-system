import 'package:flutter/material.dart';
import '../services/api_exception.dart';

void handleError(BuildContext context, Object error) {
  String message;

  if (error is UnauthorizedException) {
    // Just show message, don't auto-clear session
    message = error.message;
  } else if (error is NetworkException) {
    message = error.message;
  } else if (error is ApiException) {
    message = error.message;
  } else {
    message = 'An unexpected error occurred.';
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}           
