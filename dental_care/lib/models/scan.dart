import 'package:cloud_firestore/cloud_firestore.dart';

class Scan {
  final String id;
  final String patientId;
  final String patientName; // Denormalized for easier display
  final String toothNumber;
  final String imageUrl;
  final DateTime scanDate;
  final String cavityStatus; // 'Cavity' or 'Healthy'
  final double confidence; // AI confidence percentage (0-100)
  final String notes;

  Scan({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.toothNumber,
    required this.imageUrl,
    required this.scanDate,
    required this.cavityStatus,
    required this.confidence,
    required this.notes,
  });

  // Convert Scan to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'toothNumber': toothNumber,
      'imageUrl': imageUrl,
      'scanDate': Timestamp.fromDate(scanDate),
      'cavityStatus': cavityStatus,
      'confidence': confidence,
      'notes': notes,
    };
  }

  // Create Scan from Firestore DocumentSnapshot
  factory Scan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Scan(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      toothNumber: data['toothNumber'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      scanDate: (data['scanDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cavityStatus: data['cavityStatus'] ?? 'Unknown',
      confidence: (data['confidence'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
    );
  }

  // Check if scan shows cavity
  bool get hasCavity => cavityStatus.toLowerCase() == 'cavity';

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(scanDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  // Copy with method for updates
  Scan copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? toothNumber,
    String? imageUrl,
    DateTime? scanDate,
    String? cavityStatus,
    double? confidence,
    String? notes,
  }) {
    return Scan(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      toothNumber: toothNumber ?? this.toothNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      scanDate: scanDate ?? this.scanDate,
      cavityStatus: cavityStatus ?? this.cavityStatus,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
    );
  }
}
