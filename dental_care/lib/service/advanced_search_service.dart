import 'package:flutter/foundation.dart';

class AdvancedSearchService {
  // Search across all entities
  static List<dynamic> globalSearch(
    String query, {
    required List<dynamic> patients,
    required List<dynamic> cases,
    required List<dynamic> appointments,
  }) {
    final results = <dynamic>[];
    final lowerQuery = query.toLowerCase();

    // Search in patients
    for (var patient in patients) {
      if (patient.name.toLowerCase().contains(lowerQuery) ||
          patient.phone?.toLowerCase().contains(lowerQuery) == true ||
          patient.email?.toLowerCase().contains(lowerQuery) == true) {
        results.add({'type': 'patient', 'data': patient});
      }
    }

    // Search in cases
    for (var case_ in cases) {
      if (case_.id.toLowerCase().contains(lowerQuery) ||
          case_.status.toLowerCase().contains(lowerQuery)) {
        results.add({'type': 'case', 'data': case_});
      }
    }

    // Search in appointments
    for (var appointment in appointments) {
      if (appointment.appointmentType.toLowerCase().contains(lowerQuery) ||
          appointment.notes.toLowerCase().contains(lowerQuery)) {
        results.add({'type': 'appointment', 'data': appointment});
      }
    }

    return results;
  }

  // Advanced filter builder
  static List<dynamic> applyAdvancedFilters(
    List<dynamic> data, {
    required Map<String, dynamic> filters,
  }) {
    var filtered = data;

    for (var entry in filters.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null || value == '') continue;

      filtered = filtered.where((item) {
        try {
          final itemValue = _getNestedValue(item, key);
          if (itemValue == null) return false;

          if (value is DateTimeRange) {
            return itemValue.isAfter(value.start) &&
                itemValue.isBefore(value.end);
          } else if (value is List) {
            return value.contains(itemValue);
          } else {
            return itemValue.toString().toLowerCase().contains(
                  value.toString().toLowerCase(),
                );
          }
        } catch (e) {
          debugPrint('Filter error: $e');
          return false;
        }
      }).toList();
    }

    return filtered;
  }

  static dynamic _getNestedValue(dynamic object, String path) {
    final parts = path.split('.');
    dynamic current = object;

    for (var part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        try {
          current =
              current.runtimeType.toString().contains(part) ? current : null;
        } catch (e) {
          return null;
        }
      }
    }

    return current;
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}
