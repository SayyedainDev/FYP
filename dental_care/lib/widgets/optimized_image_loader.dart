import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// OptimizedImageLoader: Provides optimized image loading with caching
/// Automatically handles placeholders, error states, and memory management.
class OptimizedImageLoader extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeDuration;

  const OptimizedImageLoader({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeDuration = const Duration(milliseconds: 300),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Return placeholder for empty URLs
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // Use CachedNetworkImage for automatic caching
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeDuration,
      fadeOutDuration: fadeDuration,
      memCacheWidth: width != null ? (width! * 1.5).toInt() : null,
      memCacheHeight: height != null ? (height! * 1.5).toInt() : null,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }
}

/// OptimizedAssetImage: Optimized asset image display
class OptimizedAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const OptimizedAssetImage({
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheHeight: height != null ? (height! * 1.5).toInt() : null,
      cacheWidth: width != null ? (width! * 1.5).toInt() : null,
    );
  }
}

/// ImageCacheHelper: Utilities for image cache management
class ImageCacheHelper {
  static void clearMemoryCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  static int getApproximateCacheSize() {
    return imageCache.currentSize;
  }

  static int getMaxCacheSize() {
    return imageCache.maximumSize;
  }

  static void setMaxCacheSize(int size) {
    imageCache.maximumSize = size;
  }

  /// Print cache statistics
  static void printCacheStats() {
    debugPrint('''
    Image Cache Stats:
    - Current Size: ${getApproximateCacheSize()} bytes
    - Max Size: ${getMaxCacheSize()} bytes
    - Usage: ${(getApproximateCacheSize() / getMaxCacheSize() * 100).toStringAsFixed(1)}%
    ''');
  }
}
