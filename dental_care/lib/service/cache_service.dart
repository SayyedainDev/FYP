import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// CacheService: Provides caching for Firebase Firestore queries
/// to reduc network calls and improve app startup time.
class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  // Cache storage: key = cacheKey, value = {data, timestamp}
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Default cache duration (5 minutes)
  static const Duration defaultCacheDuration = Duration(minutes: 5);

  /// Check if cache exists and is still valid
  bool _isValidCache(String key, Duration duration) {
    if (!_cacheTimestamps.containsKey(key)) return false;

    final timestamp = _cacheTimestamps[key]!;
    final isValid = DateTime.now().difference(timestamp) < duration;

    if (!isValid) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    return isValid;
  }

  /// Store data in cache
  void setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
    developer.log('Cache SET: $key', name: 'CacheService');
  }

  /// Retrieve data from cache
  dynamic getCache(String key) {
    if (_cache.containsKey(key)) {
      developer.log('Cache HIT: $key', name: 'CacheService');
      return _cache[key];
    }
    developer.log('Cache MISS: $key', name: 'CacheService');
    return null;
  }

  /// Check if valid cache exists
  bool hasValidCache(String key, {Duration? duration}) {
    return _isValidCache(key, duration ?? defaultCacheDuration);
  }

  /// Clear specific cache
  void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    developer.log('Cache CLEARED: $key', name: 'CacheService');
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    developer.log('All cache CLEARED', name: 'CacheService');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCachedItems': _cache.length,
      'cacheKeys': _cache.keys.toList(),
      'memorySizeApprox':
          '${(_cache.toString().length / 1024).toStringAsFixed(2)} KB',
    };
  }

  /// Fetch with caching: Returns cached data if available, otherwise fetches from Firestore
  Future<List<T>> fetchWithCache<T>(
    String cacheKey,
    Future<List<T>> Function() fetchFunction, {
    Duration cacheDuration = defaultCacheDuration,
  }) async {
    // Check if valid cache exists
    if (hasValidCache(cacheKey, duration: cacheDuration)) {
      final cachedData = getCache(cacheKey) as List<T>?;
      if (cachedData != null) {
        developer.log('Returning cached data for: $cacheKey',
            name: 'CacheService');
        return cachedData;
      }
    }

    // Fetch fresh data
    try {
      developer.log('Fetching fresh data for: $cacheKey', name: 'CacheService');
      final data = await fetchFunction();
      setCache(cacheKey, data);
      return data;
    } catch (e) {
      // Return cached data on error if available
      final cachedData = getCache(cacheKey) as List<T>?;
      if (cachedData != null) {
        developer.log(
            'Error fetching data, returning stale cache for: $cacheKey',
            name: 'CacheService');
        return cachedData;
      }
      rethrow;
    }
  }

  /// Fetch document with caching
  Future<DocumentSnapshot?> fetchDocumentWithCache(
    String cacheKey,
    DocumentReference ref, {
    Duration cacheDuration = defaultCacheDuration,
  }) async {
    if (hasValidCache(cacheKey, duration: cacheDuration)) {
      final cachedData = getCache(cacheKey) as DocumentSnapshot?;
      if (cachedData != null) return cachedData;
    }

    try {
      final doc = await ref.get();
      if (doc.exists) {
        setCache(cacheKey, doc);
      }
      return doc;
    } catch (e) {
      final cachedData = getCache(cacheKey) as DocumentSnapshot?;
      if (cachedData != null) return cachedData;
      rethrow;
    }
  }

  /// Fetch collection with caching
  Future<QuerySnapshot?> fetchCollectionWithCache(
    String cacheKey,
    Query query, {
    Duration cacheDuration = defaultCacheDuration,
  }) async {
    if (hasValidCache(cacheKey, duration: cacheDuration)) {
      final cachedData = getCache(cacheKey) as QuerySnapshot?;
      if (cachedData != null) return cachedData;
    }

    try {
      final snapshot = await query.get();
      setCache(cacheKey, snapshot);
      return snapshot;
    } catch (e) {
      final cachedData = getCache(cacheKey) as QuerySnapshot?;
      if (cachedData != null) return cachedData;
      rethrow;
    }
  }

  /// Invalidate cache pattern (e.g., "user_*" invalidates all user caches)
  void invalidateCachePattern(String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    final keysToRemove =
        _cache.keys.where((key) => regex.hasMatch(key)).toList();
    for (final key in keysToRemove) {
      clearCache(key);
    }
    developer.log(
        'Pattern invalidation: $pattern removed ${keysToRemove.length} items',
        name: 'CacheService');
  }
}
