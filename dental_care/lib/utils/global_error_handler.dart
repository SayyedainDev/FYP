import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'app_dialogs.dart';

enum _GlobalErrorType {
  network,
  timeout,
  auth,
  permission,
  validation,
  unknown,
}

class GlobalErrorHandler {
  GlobalErrorHandler._();
  static final GlobalErrorHandler _instance = GlobalErrorHandler._();
  static GlobalErrorHandler get instance => _instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Use a simple queue to manage dialogs if one is already showing.
  bool _isShowingDialog = false;
  final List<Function> _dialogQueue = [];

  void handleError(Object error, StackTrace? stack) {
    _logError(error, stack);

    // Queue the dialog to avoid overlapping dialogs
    _queueDialog(() {
      _showErrorDialog(error);
    });
  }

  void _logError(Object error, StackTrace? stack) {
    // Log to a robust internal logging or crashlytics service.
    // We intentionally don't expose this payload to the UI.
    debugPrint('--- INTERNAL ERROR LOG ---');
    debugPrint(error.toString());
    if (stack != null) debugPrint(stack.toString());
    debugPrint('--------------------------');
  }

  void _queueDialog(Function dialogAction) {
    if (_isShowingDialog) {
      _dialogQueue.add(dialogAction);
    } else {
      _isShowingDialog = true;
      dialogAction();
    }
  }

  void onDialogDismissed() {
    _isShowingDialog = false;
    if (_dialogQueue.isNotEmpty) {
      final nextAction = _dialogQueue.removeAt(0);
      _isShowingDialog = true;
      nextAction();
    }
  }

  Future<void> _showErrorDialog(Object error) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      onDialogDismissed();
      return;
    }

    final errorType = _classifyError(error);

    switch (errorType) {
      case _GlobalErrorType.network:
        await AppDialogs.showNoInternetDialog(context);
        break;
      case _GlobalErrorType.timeout:
        await AppDialogs.showErrorDialog(
          context,
          title: 'Request Timed Out',
          message:
              'The request timed out. Check your connection and try again.',
        );
        break;
      case _GlobalErrorType.auth:
        await AppDialogs.showSessionExpiredDialog(
          context,
          onLoginAgain: () {
            navigatorKey.currentState
                ?.pushNamedAndRemoveUntil('/', (_) => false);
          },
        );
        break;
      case _GlobalErrorType.permission:
        await AppDialogs.showErrorDialog(
          context,
          title: 'Access Denied',
          message: 'You do not have permission to perform this action.',
        );
        break;
      case _GlobalErrorType.validation:
        await AppDialogs.showWarningDialog(
          context,
          title: 'Validation Error',
          message:
              'Some required fields are missing. Please complete the form.',
          confirmLabel: 'OK',
          onConfirm: () {},
        );
        break;
      case _GlobalErrorType.unknown:
        await AppDialogs.showErrorDialog(
          context,
          message: 'Something went wrong on our end. Please try again.',
        );
        break;
    }

    onDialogDismissed();
  }

  _GlobalErrorType _classifyError(Object error) {
    if (error is SocketException) {
      return _GlobalErrorType.network;
    }

    if (error is TimeoutException) {
      return _GlobalErrorType.timeout;
    }

    if (error is FormatException || error is ArgumentError) {
      return _GlobalErrorType.validation;
    }

    final message = error.toString().toLowerCase();
    if (message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('token') ||
        message.contains('session expired')) {
      return _GlobalErrorType.auth;
    }

    if (message.contains('403') ||
        message.contains('forbidden') ||
        message.contains('permission')) {
      return _GlobalErrorType.permission;
    }

    return _GlobalErrorType.unknown;
  }
}
