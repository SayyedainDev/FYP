import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class AppointmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Appointment> _appointments = [];
  bool _loading = false;
  String? _error;

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get loading => _loading;
  String? get error => _error;

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) => a.appointmentDate.isAfter(now) && a.status != 'cancelled')
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  List<Appointment> get completedAppointments {
    return _appointments.where((a) => a.status == 'completed').toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  int get completionRate {
    if (_appointments.isEmpty) return 0;
    final completed = _appointments
        .where((a) => a.status == 'completed')
        .length;
    return ((completed / _appointments.length) * 100).toInt();
  }

  Future<void> fetchAppointments(String dentistUid) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('dentistUid', isEqualTo: dentistUid)
          .orderBy('appointmentDate', descending: true)
          .get();

      _appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch appointments: $e';
      _loading = false;
      notifyListeners();
      debugPrint('Error fetching appointments: $e');
    }
  }

  Future<void> createAppointment(Appointment appointment) async {
    try {
      _loading = true;
      notifyListeners();

      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toFirestore());

      _appointments.add(appointment);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create appointment: $e';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update(appointment.toFirestore());

      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update appointment: $e';
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': DateTime.now(),
      });

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: 'cancelled',
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to cancel appointment: $e';
      notifyListeners();
    }
  }

  Stream<List<Appointment>> getAppointmentsStream(String dentistUid) {
    return _firestore
        .collection('appointments')
        .where('dentistUid', isEqualTo: dentistUid)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList(),
        );
  }
}
