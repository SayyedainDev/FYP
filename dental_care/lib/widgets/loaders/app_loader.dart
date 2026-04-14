import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  final double size;

  const AppLoader({super.key, this.message, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: Lottie.asset(
              'assets/lottie/loader.json',
              width: size,
              height: size,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return const _PulseDots();
              },
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: textStyle),
          ],
        ],
      ),
    );
  }
}

class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final a = (0.35 + (t * 0.65)).clamp(0.35, 1.0);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final opacity = (a - (index * 0.2)).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90E2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
