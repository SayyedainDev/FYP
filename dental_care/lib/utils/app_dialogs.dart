import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';
import '../widgets/loaders/app_loader.dart';

class AppDialogs {
  static final Queue<_QueuedDialog> _blockingDialogQueue =
      Queue<_QueuedDialog>();
  static bool _isBlockingDialogVisible = false;
  static DateTime? _lastRetryTapAt;

  static void resetForTest() {
    _blockingDialogQueue.clear();
    _isBlockingDialogVisible = false;
    _lastRetryTapAt = null;
  }

  static Future<T?> _enqueueBlockingDialog<T>(Future<T?> Function() presenter) {
    final completer = Completer<T?>();
    _blockingDialogQueue.add(_QueuedDialog(
      presenter: () async {
        final result = await presenter();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      },
    ));

    _drainBlockingDialogQueue();
    return completer.future;
  }

  static void _drainBlockingDialogQueue() {
    if (_isBlockingDialogVisible || _blockingDialogQueue.isEmpty) {
      return;
    }

    _isBlockingDialogVisible = true;
    final queued = _blockingDialogQueue.removeFirst();
    queued.presenter().whenComplete(() {
      _isBlockingDialogVisible = false;
      _drainBlockingDialogQueue();
    });
  }

  static bool _consumeRetryTap() {
    final now = DateTime.now();
    final lastTap = _lastRetryTapAt;
    if (lastTap != null &&
        now.difference(lastTap) < const Duration(seconds: 2)) {
      return false;
    }

    _lastRetryTapAt = now;
    return true;
  }

  static Widget _buildDialogTitle({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Focus(
      autofocus: true,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  /// Red/danger-styled. Shows a human-readable error.
  static Future<void> showErrorDialog(
    BuildContext context, {
    String title = "Error",
    required String message,
    VoidCallback? onRetry,
  }) async {
    return _enqueueBlockingDialog<void>(
      () => showDialog<void>(
        context: context,
        builder: (ctx) {
          bool retryTapped = false;
          return StatefulBuilder(
            builder: (ctx, setState) => Semantics(
              namesRoute: true,
              label: 'dialog_error',
              child: AlertDialog(
                semanticLabel: 'dialog_error',
                title: _buildDialogTitle(
                  icon: Icons.error_outline,
                  color: Colors.red,
                  text: title,
                ),
                content: Text(message),
                actions: [
                  Semantics(
                    button: true,
                    label: 'dialog_error_ok_button',
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ),
                  if (onRetry != null)
                    Semantics(
                      button: true,
                      label: 'dialog_error_retry_button',
                      child: ElevatedButton(
                        onPressed: retryTapped
                            ? null
                            : () {
                                if (!_consumeRetryTap()) {
                                  return;
                                }
                                setState(() => retryTapped = true);
                                Navigator.of(ctx).pop();
                                onRetry();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Amber/warning-styled. Used for destructive or irreversible actions.
  static Future<void> showWarningDialog(
    BuildContext context, {
    String title = "Warning",
    required String message,
    String confirmLabel = "Confirm",
    required VoidCallback onConfirm,
  }) async {
    return _enqueueBlockingDialog<void>(
      () => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Semantics(
            namesRoute: true,
            label: 'dialog_warning',
            child: AlertDialog(
              semanticLabel: 'dialog_warning',
              title: _buildDialogTitle(
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                text: title,
              ),
              content: Text(message),
              actions: [
                Semantics(
                  button: true,
                  label: 'dialog_warning_cancel_button',
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'dialog_warning_confirm_button',
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Neutral/info-styled. For non-critical notices.
  static Future<void> showInfoDialog(
    BuildContext context, {
    String title = "Info",
    required String message,
  }) async {
    return _enqueueBlockingDialog<void>(
      () => showDialog<void>(
        context: context,
        builder: (ctx) => Semantics(
          namesRoute: true,
          label: 'dialog_info',
          child: AlertDialog(
            semanticLabel: 'dialog_info',
            title: _buildDialogTitle(
              icon: Icons.info_outline,
              color: Colors.blue,
              text: title,
            ),
            content: Text(message),
            actions: [
              Semantics(
                button: true,
                label: 'dialog_info_ok_button',
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Non-dismissible. Tells user their session has expired.
  static Future<void> showSessionExpiredDialog(
    BuildContext context, {
    required VoidCallback onLoginAgain,
  }) async {
    return _enqueueBlockingDialog<void>(
      () => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Semantics(
            namesRoute: true,
            label: 'dialog_session_expired',
            child: AlertDialog(
              semanticLabel: 'dialog_session_expired',
              title: _buildDialogTitle(
                icon: Icons.lock_clock,
                color: Colors.orange,
                text: 'Session Expired',
              ),
              content:
                  const Text('Your session has expired. Please log in again.'),
              actions: [
                Semantics(
                  button: true,
                  label: 'dialog_session_expired_login_button',
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onLoginAgain();
                    },
                    child: const Text('Log in again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tells user device is offline.
  static Future<void> showNoInternetDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    return _enqueueBlockingDialog<void>(
      () => showDialog<void>(
        context: context,
        builder: (ctx) {
          bool retryTapped = false;
          return StatefulBuilder(
            builder: (ctx, setState) => Semantics(
              namesRoute: true,
              label: 'dialog_no_internet',
              child: AlertDialog(
                semanticLabel: 'dialog_no_internet',
                title: _buildDialogTitle(
                  icon: Icons.wifi_off,
                  color: Colors.orange,
                  text: 'No Internet',
                ),
                content: const Text(
                  'No internet connection. Check your network and try again.',
                ),
                actions: [
                  Semantics(
                    button: true,
                    label: 'dialog_no_internet_ok_button',
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ),
                  if (onRetry != null)
                    Semantics(
                      button: true,
                      label: 'dialog_no_internet_retry_button',
                      child: ElevatedButton(
                        onPressed: retryTapped
                            ? null
                            : () {
                                if (!_consumeRetryTap()) {
                                  return;
                                }
                                setState(() => retryTapped = true);
                                Navigator.of(ctx).pop();
                                onRetry();
                              },
                        child: const Text('Retry'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Non-dismissible circular progress dialog. Return a close function.
  static VoidCallback showLoadingDialog(
    BuildContext context, {
    String message = 'Please wait...',
  }) {
    // If we pop this specific dialog, we use a global key or just return a dismissal function.
    bool isClosed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Semantics(
          namesRoute: true,
          label: 'dialog_loading',
          child: AlertDialog(
            semanticLabel: 'dialog_loading',
            content: Row(
              children: [
                const AppLoader(size: 36),
                const SizedBox(width: 16),
                Expanded(child: Focus(autofocus: true, child: Text(message))),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      isClosed = true;
    });

    return () {
      if (!isClosed && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    };
  }

  /// Warning before navigating away from a dirty form.
  static Future<void> showUnsavedChangesDialog(
    BuildContext context, {
    required VoidCallback onDiscard,
  }) async {
    return _enqueueBlockingDialog<void>(
      () => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Semantics(
            namesRoute: true,
            label: 'dialog_unsaved_changes',
            child: AlertDialog(
              semanticLabel: 'dialog_unsaved_changes',
              title: _buildDialogTitle(
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                text: 'Unsaved Changes',
              ),
              content: const Text(
                'You have unsaved changes. Are you sure you want to leave?',
              ),
              actions: [
                Semantics(
                  button: true,
                  label: 'dialog_unsaved_keep_editing_button',
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Keep editing'),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'dialog_unsaved_discard_button',
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onDiscard();
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Discard changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueuedDialog {
  final Future<void> Function() presenter;

  _QueuedDialog({required this.presenter});
}
