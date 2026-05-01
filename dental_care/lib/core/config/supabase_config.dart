import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, FileOptions;

class SupabaseConfig {
  static const String url = 'https://wcuqsnynybrjrzwfauod.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjdXFzbnlueWJyanJ6d2ZhdW9kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyMTM0MzIsImV4cCI6MjA5Mjc4OTQzMn0.ko9cjtXaH0ZHWjiLl_y9vohp7viJQOwHhbMv8ekijE0';

  static Future<void> initialize() async {
    try {
      // Check if already initialized to avoid multiple initialization errors
      Supabase.instance;
      return;
    } catch (_) {
      // Not initialized, proceed with initialization
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
