import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

class QuizCardSkeleton extends StatelessWidget {
  const QuizCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 140, height: 16),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 12),
          SizedBox(height: 8),
          ShimmerBox(width: 180, height: 12),
          SizedBox(height: 16),
          Row(
            children: [
              ShimmerBox(width: 80, height: 10),
              Spacer(),
              ShimmerBox(width: 56, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardStatsSkeleton extends StatelessWidget {
  const DashboardStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
            child: ShimmerBox(width: double.infinity, height: 86, radius: 14)),
        SizedBox(width: 12),
        Expanded(
            child: ShimmerBox(width: double.infinity, height: 86, radius: 14)),
        SizedBox(width: 12),
        Expanded(
            child: ShimmerBox(width: double.infinity, height: 86, radius: 14)),
      ],
    );
  }
}

class QuestionSkeleton extends StatelessWidget {
  const QuestionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: 220, height: 20),
        SizedBox(height: 16),
        ShimmerBox(width: double.infinity, height: 14),
        SizedBox(height: 10),
        ShimmerBox(width: double.infinity, height: 14),
        SizedBox(height: 24),
        ShimmerBox(width: double.infinity, height: 52, radius: 12),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 52, radius: 12),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 52, radius: 12),
      ],
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerBox(width: 72, height: 72, radius: 36),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 180, height: 14),
              SizedBox(height: 8),
              ShimmerBox(width: 130, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
