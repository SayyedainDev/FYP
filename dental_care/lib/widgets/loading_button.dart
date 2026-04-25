import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color overlayColor;

  const LoadingButton({
    Key? key,
    required this.isLoading,
    required this.child,
    this.overlayColor = Colors.white24, // Softer generic overlay color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return AbsorbPointer(
      absorbing: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.8, // Dim the underlying button slightly 
            child: child,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: overlayColor,
                borderRadius: BorderRadius.circular(16.0), // A safer generic radius for Material 3 buttons
              ),
            ),
          ),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
