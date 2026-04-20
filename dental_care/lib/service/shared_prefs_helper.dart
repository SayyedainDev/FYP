import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

/// SharedPreferencesHelper: Simplified access to SharedPreferences
/// for caching user data, preferences, and frequently accessed data.
class SharedPrefsHelper {
  static final SharedPrefsHelper _instance = SharedPrefsHelper._internal();

  factory SharedPrefsHelper() {
    return _instance;
  }

  SharedPrefsHelper._internal();

  late SharedPreferences _prefs;

  // Keys for commonly cached data
  static const String keyUserProfile = 'user_profile';
  static const String keyUserUid = 'user_uid';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole = 'user_role';
  static const String keyUserName = 'user_name';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyPatientsList = 'patients_list';
  static const String keyQuizzesList = 'quizzes_list';
  static const String keyAssignmentsList = 'assignments_list';
  static const String keyAppTheme = 'app_theme';
  static const String keyRememberMe = 'remember_me';
  static const String keyCacheTimestamp = 'cache_timestamp_';

  /// Initialize SharedPreferences (call once on app startup)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    developer.log('SharedPreferencesHelper initialized', name: 'SharedPrefs');
  }

  // === String Operations ===
  Future<bool> setString(String key, String value) async {
    final result = await _prefs.setString(key, value);
    developer.log('SET String: $key', name: 'SharedPrefs');
    return result;
  }

  String? getString(String key) {
    final value = _prefs.getString(key);
    developer.log('GET String: $key = ${value != null ? 'cached' : 'null'}',
        name: 'SharedPrefs');
    return value;
  }

  // === Int Operations ===
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // === Bool Operations ===
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  // === List<String> Operations ===
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  // === JSON (Serialized) Operations ===
  Future<bool> setJson(String key, dynamic json) async {
    final jsonString = jsonEncode(json);
    final result = await _prefs.setString(key, jsonString);
    developer.log('SET Json: $key', name: 'SharedPrefs');
    return result;
  }

  dynamic getJson(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) {
      developer.log('GET Json: $key = null', name: 'SharedPrefs');
      return null;
    }
    try {
      final decoded = jsonDecode(jsonString);
      developer.log('GET Json: $key (decoded)', name: 'SharedPrefs');
      return decoded;
    } catch (e) {
      developer.log('Error decoding JSON for $key: $e', name: 'SharedPrefs');
      return null;
    }
  }

  /// Check if key exists
  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }

  /// Remove specific key
  Future<bool> remove(String key) async {
    final result = await _prefs.remove(key);
    developer.log('REMOVE: $key', name: 'SharedPrefs');
    return result;
  }

  /// Clear all data
  Future<bool> clear() async {
    final result = await _prefs.clear();
    developer.log('Clear all SharedPreferences', name: 'SharedPrefs');
    return result;
  }

  /// Get all keys
  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  // === User-specific Helper Methods ===

  Future<bool> cacheUserProfile(Map<String, dynamic> profile) {
    return setJson(keyUserProfile, profile);
  }

  Map<String, dynamic>? getUserProfile() {
    final data = getJson(keyUserProfile);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<bool> cacheUserBasicInfo({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) async {
    await setString(keyUserUid, uid);
    await setString(keyUserEmail, email);
    await setString(keyUserName, name);
    await setString(keyUserRole, role);
    return true;
  }

  String? getUserUid() => getString(keyUserUid);
  String? getUserEmail() => getString(keyUserEmail);
  String? getUserName() => getString(keyUserName);
  String? getUserRole() => getString(keyUserRole);

  Future<bool> clearUserData() async {
    await remove(keyUserProfile);
    await remove(keyUserUid);
    await remove(keyUserEmail);
    await remove(keyUserName);
    await remove(keyUserRole);
    return true;
  }

  // === List Caching Helper ===
  Future<bool> cacheList(String key, List<Map<String, dynamic>> list) {
    return setJson(key, list);
  }

  List<Map<String, dynamic>> getCachedList(String key) {
    final data = getJson(key);
    if (data is List) {
      return List<Map<String, dynamic>>.from(
        data.map((e) => e is Map ? Map<String, dynamic>.from(e) : {}),
      );
    }
    return [];
  }

  // === Timestamp Management ===
  void setCacheTimestamp(String key) {
    setInt('$keyCacheTimestamp$key', DateTime.now().millisecondsSinceEpoch);
  }

  bool isCacheExpired(String key,
      {Duration expiry = const Duration(hours: 1)}) {
    final timestamp = getInt('$keyCacheTimestamp$key');
    if (timestamp == null) return true;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedTime) > expiry;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final keys = getKeys();
    return {
      'totalCachedKeys': keys.length,
      'cachedKeys': keys.toList(),
      'memorySizeApprox': _estimateMemoryUsage(),
    };
  }

  String _estimateMemoryUsage() {
    int totalBytes = 0;
    for (final key in getKeys()) {
      final value = _prefs.get(key);
      if (value is String) totalBytes += value.length;
    }
    return '${(totalBytes / 1024).toStringAsFixed(2)} KB';
  }
}
