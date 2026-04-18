import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../utils/app_dialogs.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final name = authProvider.userName ?? 'Student';
    final email = authProvider.userEmail ?? 'No email provided';

    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final studentIdController = TextEditingController();
    final programController = TextEditingController();
    final yearController = TextEditingController();

    // Try to prefill from provider's user data in Firestore if available

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(fontSize: 40, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Editable profile fields
            TextFormField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: studentIdController,
              decoration:
                  const InputDecoration(labelText: 'Student / Professional ID'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: programController,
              decoration:
                  const InputDecoration(labelText: 'Program / Department'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: yearController,
              decoration: const InputDecoration(labelText: 'Year / Batch'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final Map<String, dynamic> updateData = {};
                        if (firstNameController.text.trim().isNotEmpty)
                          updateData['firstName'] =
                              firstNameController.text.trim();
                        if (lastNameController.text.trim().isNotEmpty)
                          updateData['lastName'] =
                              lastNameController.text.trim();
                        if (phoneController.text.trim().isNotEmpty)
                          updateData['phone'] = phoneController.text.trim();
                        if (studentIdController.text.trim().isNotEmpty)
                          updateData['userId'] =
                              studentIdController.text.trim();
                        if (programController.text.trim().isNotEmpty)
                          updateData['program'] = programController.text.trim();
                        if (yearController.text.trim().isNotEmpty)
                          updateData['yearOfStudy'] =
                              yearController.text.trim();

                        try {
                          await authProvider.updateProfile(updateData);
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Profile updated')));
                        } catch (e) {
                          if (context.mounted)
                            AppDialogs.showErrorDialog(context,
                                message: e.toString());
                        }
                      },
                      child: const Text('Save Profile'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.red, width: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
