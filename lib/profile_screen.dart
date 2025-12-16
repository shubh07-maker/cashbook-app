import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current logged-in user
    final user = AuthService().currentUser;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("My Account")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Circular Avatar with First Letter
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? "U",
                style: const TextStyle(fontSize: 40, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // Email Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text("Email Address"),
                subtitle: Text(user?.email ?? "Not logged in", style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),

            // Account ID Card (Optional, looks pro)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.fingerprint, color: Colors.grey),
                title: const Text("Account ID"),
                subtitle: Text(
                  user?.uid.substring(0, 10) ?? "Unknown", 
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace')
                ),
              ),
            ),

            const Spacer(),

            // Logout Button at the bottom
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50, // Light red background
                  foregroundColor: Colors.red,       // Red text/icon
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  // Show confirmation dialog
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Logout", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (Route<dynamic> route) => false);
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}