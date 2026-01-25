import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Management',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF212121),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Schedule and manage patient appointments',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAppointmentDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', Icons.calendar_today),
                  const SizedBox(width: 12),
                  _buildFilterChip('Upcoming', 'upcoming', Icons.upcoming),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    'Completed',
                    'completed',
                    Icons.check_circle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appointments List
            Consumer<AppointmentProvider>(
              builder: (context, appointmentProvider, _) {
                if (appointmentProvider.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final appointments = _filterAppointments(
                  appointmentProvider.appointments,
                );

                if (appointments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(64),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $_selectedFilter appointments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Schedule a new appointment to get started',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final apt = appointments[index];
                    return _buildAppointmentCard(apt);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A90E2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A90E2) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final statusColor = _getStatusColor(appointment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Date Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.2),
                    statusColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appointment.appointmentDate.day.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    _getMonthAbbreviation(appointment.appointmentDate.month),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Appointment Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Patient: ${appointment.patientId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          appointment.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${appointment.appointmentDate.hour.toString().padLeft(2, '0')}:${appointment.appointmentDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.medical_services,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appointment.appointmentType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (appointment.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      appointment.notes,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[600]),
                  onPressed: () => _editAppointment(appointment),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[400]),
                  onPressed: () => _deleteAppointment(appointment),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void _editAppointment(Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _deleteAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<Appointment> _filterAppointments(List<Appointment> appointments) {
    switch (_selectedFilter) {
      case 'upcoming':
        return appointments
            .where(
              (a) =>
                  a.appointmentDate.isAfter(DateTime.now()) &&
                  a.status != 'cancelled',
            )
            .toList();
      case 'completed':
        return appointments.where((a) => a.status == 'completed').toList();
      default:
        return appointments;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
      case 'upcoming':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Appointment'),
        content: const SizedBox(
          height: 300,
          child: Text('Appointment form would go here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
