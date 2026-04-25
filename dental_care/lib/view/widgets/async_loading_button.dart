import 'package:flutter/material.dart';

class AsyncLoadingButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isIcon;
  final Widget? icon;
  final Widget? label;

  const AsyncLoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  })  : isIcon = false,
        icon = null,
        label = null;

  const AsyncLoadingButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.style,
  })  : isIcon = true,
        child = const SizedBox();

  @override
  State<AsyncLoadingButton> createState() => _AsyncLoadingButtonState();
}

class _AsyncLoadingButtonState extends State<AsyncLoadingButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isIcon) {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : _handlePress,
        style: widget.style,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : widget.icon!,
        label: widget.label!,
      );
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePress,
      style: widget.style,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.child,
    );
  }
}
