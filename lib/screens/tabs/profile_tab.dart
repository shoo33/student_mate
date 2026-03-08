import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('app');

  Future<void> _ensureSettingsExists() async {
    final snap = await _settingsDoc.get();
    if (!snap.exists) {
      await _settingsDoc.set({
        'notificationsEnabled': true,
        'quotesEnabled': true,
        'darkMode': false,
        'weeklyHomeLimit': 2,
        'appointmentsHomeLimit': 3,
        'tasksHomeLimit': 3,
        'showAllWeeklyOnHome': false,
        'showAllDatedOnHome': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    await _settingsDoc.set({
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _changePasswordDialog(BuildContext context, String email) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Change password"),
          content: Text(
            "A password reset email will be sent to:\n$email",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rose,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password reset email sent.")),
                );
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _contactUsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Contact us"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Student Mate support",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text("Email: support@studentmate.app"),
              SizedBox(height: 6),
              Text("You can replace this later with your real team email."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editNameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rose,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                await _userDoc.set({
                  'name': newName,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name updated.")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editEmailDialog(BuildContext context, String currentEmail) async {
    final controller = TextEditingController(text: currentEmail);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit email"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              const Text(
                "If Firebase asks for recent login, just log out and log in again, then retry.",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rose,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newEmail = controller.text.trim();
                if (newEmail.isEmpty) return;

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await user.verifyBeforeUpdateEmail(newEmail);
                  }

                  await _userDoc.set({
                    'email': newEmail,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Verification email sent to update your email."),
                    ),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Could not update email: $e")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppTheme.dark,
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2C9BF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withValues(alpha: 0.65),
    );
  }

  Widget _rowButton({
    required String title,
    Color? color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: color ?? AppTheme.dark,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _stepperRow({
    required String title,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppTheme.dark,
            ),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          "$value",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authEmail = user?.email ?? "No email";

    return FutureBuilder(
      future: _ensureSettingsExists(),
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.bgTop, AppTheme.bgBottom],
            ),
          ),
          child: SafeArea(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userDoc.snapshots(),
              builder: (context, userSnap) {
                final userData = userSnap.data?.data();
                final name = (userData?['name'] ?? 'Student').toString();
                final email = (userData?['email'] ?? authEmail).toString();

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _settingsDoc.snapshots(),
                  builder: (context, settingsSnap) {
                    final s = settingsSnap.data?.data() ?? {};

                    final notificationsEnabled =
                        (s['notificationsEnabled'] ?? true) == true;
                    final quotesEnabled = (s['quotesEnabled'] ?? true) == true;
                    final darkMode = (s['darkMode'] ?? false) == true;
                    final weeklyHomeLimit = (s['weeklyHomeLimit'] ?? 2) as int;
                    final appointmentsHomeLimit =
                        (s['appointmentsHomeLimit'] ?? 3) as int;
                    final tasksHomeLimit = (s['tasksHomeLimit'] ?? 3) as int;
                    final showAllWeeklyOnHome =
                        (s['showAllWeeklyOnHome'] ?? false) == true;
                    final showAllDatedOnHome =
                        (s['showAllDatedOnHome'] ?? false) == true;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                      children: [
                        Row(
                          children: [
                            const Text(
                              "⋯",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.dark,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F1DE),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.dark, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.dark,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.person_outline),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        _settingsCard(
                          child: Column(
                            children: [
                              _rowButton(
                                title: "Edit name",
                                trailing: const Icon(Icons.edit_outlined),
                                onTap: () => _editNameDialog(context, name),
                              ),
                              _divider(),
                              _rowButton(
                                title: "Edit email",
                                trailing: const Icon(Icons.alternate_email),
                                onTap: () => _editEmailDialog(context, email),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                        _sectionTitle("Settings"),

                        _settingsCard(
                          child: Column(
                            children: [
                              _rowButton(
                                title: "Notifications",
                                trailing: Icon(
                                  Icons.arrow_forward,
                                  color: AppTheme.beigeBtn,
                                ),
                                onTap: () {},
                              ),
                              _divider(),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Quotes",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                value: quotesEnabled,
                                onChanged: (v) => _updateSetting('quotesEnabled', v),
                                activeColor: AppTheme.rose,
                              ),
                              _divider(),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Enable reminders",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                value: notificationsEnabled,
                                onChanged: (v) =>
                                    _updateSetting('notificationsEnabled', v),
                                activeColor: AppTheme.rose,
                              ),
                              _divider(),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Dark mode",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                value: darkMode,
                                onChanged: (v) => _updateSetting('darkMode', v),
                                activeColor: AppTheme.rose,
                              ),
                              _divider(),
                              _rowButton(
                                title: "Change password",
                                onTap: () => _changePasswordDialog(context, email),
                              ),
                              _divider(),
                              _rowButton(
                                title: "Contact us",
                                onTap: () => _contactUsDialog(context),
                              ),
                              _divider(),
                              _rowButton(
                                title: "Log out",
                                color: Colors.red.shade700,
                                onTap: () => _logout(context),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        _settingsCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Home display",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _stepperRow(
                                title: "Weekly on home",
                                value: weeklyHomeLimit,
                                min: 1,
                                max: 10,
                                onChanged: (v) =>
                                    _updateSetting('weeklyHomeLimit', v),
                              ),
                              _divider(),
                              _stepperRow(
                                title: "Appointments on home",
                                value: appointmentsHomeLimit,
                                min: 1,
                                max: 10,
                                onChanged: (v) =>
                                    _updateSetting('appointmentsHomeLimit', v),
                              ),
                              _divider(),
                              _stepperRow(
                                title: "Tasks on home",
                                value: tasksHomeLimit,
                                min: 1,
                                max: 10,
                                onChanged: (v) =>
                                    _updateSetting('tasksHomeLimit', v),
                              ),
                              _divider(),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Show all weekly classes on home",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                value: showAllWeeklyOnHome,
                                onChanged: (v) =>
                                    _updateSetting('showAllWeeklyOnHome', v),
                                activeColor: AppTheme.rose,
                              ),
                              _divider(),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  "Show all dated appointments on home",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                value: showAllDatedOnHome,
                                onChanged: (v) =>
                                    _updateSetting('showAllDatedOnHome', v),
                                activeColor: AppTheme.rose,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}