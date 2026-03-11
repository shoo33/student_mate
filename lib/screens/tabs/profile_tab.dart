import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../app_text.dart';
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
        'reminderMinutes': 30,
        'languageCode': 'en',
        'customQuotes': const [
          'Start with one small step today.',
          'Every finished task moves you forward.',
          'Organize today, relax tomorrow.',
          'Small consistency creates big results.',
          'One task at a time.',
        ],
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

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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

  Future<void> _editNameDialog(
    BuildContext context,
    String currentName,
    AppText t,
  ) async {
    final controller = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.editNameTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: t.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
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
                _toast(t.nameUpdated);
              },
              child: Text(t.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editEmailDialog(
    BuildContext context,
    String currentEmail,
    AppText t,
  ) async {
    final controller = TextEditingController(text: currentEmail);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.editEmailTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(labelText: t.email),
              ),
              const SizedBox(height: 10),
              Text(
                t.verificationEmailHint,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
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
                  _toast(t.emailCheck);
                } catch (_) {
                  _toast(t.emailUpdateError);
                }
              },
              child: Text(t.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePasswordDialog(
    BuildContext context,
    String email,
    AppText t,
  ) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    bool obscure1 = true;
    bool obscure2 = true;
    bool obscure3 = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(t.changePasswordTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentCtrl,
                      obscureText: obscure1,
                      decoration: InputDecoration(
                        labelText: t.currentPassword,
                        suffixIcon: IconButton(
                          onPressed: () => setLocal(() => obscure1 = !obscure1),
                          icon: Icon(
                            obscure1 ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newCtrl,
                      obscureText: obscure2,
                      decoration: InputDecoration(
                        labelText: t.newPassword,
                        suffixIcon: IconButton(
                          onPressed: () => setLocal(() => obscure2 = !obscure2),
                          icon: Icon(
                            obscure2 ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscure3,
                      decoration: InputDecoration(
                        labelText: t.confirmNewPassword,
                        suffixIcon: IconButton(
                          onPressed: () => setLocal(() => obscure3 = !obscure3),
                          icon: Icon(
                            obscure3 ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.rose,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final currentPass = currentCtrl.text.trim();
                    final newPass = newCtrl.text.trim();
                    final confirmPass = confirmCtrl.text.trim();

                    if (currentPass.isEmpty ||
                        newPass.isEmpty ||
                        confirmPass.isEmpty) {
                      _toast(t.fillAllFields);
                      return;
                    }

                    if (newPass.length < 6) {
                      _toast(t.newPasswordMin);
                      return;
                    }

                    if (newPass != confirmPass) {
                      _toast(t.passwordsNoMatch);
                      return;
                    }

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final credential = EmailAuthProvider.credential(
                        email: email,
                        password: currentPass,
                      );

                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(newPass);

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _toast(t.passwordUpdated);
                    } catch (_) {
                      _toast(t.passwordUpdateError);
                    }
                  },
                  child: Text(t.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _contactUsDialog(BuildContext context, AppText t) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.contactTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.supportTitle,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text("Email: support@studentmate.app"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.close),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickLanguageDialog(
    BuildContext context,
    String current,
    AppText t,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'en',
                groupValue: current,
                title: Text(t.languageEnglish),
                onChanged: (v) async {
                  if (v == null) return;
                  await _updateSetting('languageCode', v);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                value: 'ar',
                groupValue: current,
                title: Text(t.languageArabic),
                onChanged: (v) async {
                  if (v == null) return;
                  await _updateSetting('languageCode', v);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editQuotesDialog(
    BuildContext context,
    List<String> currentQuotes,
    AppText t,
  ) async {
    final controller = TextEditingController(
      text: currentQuotes.join('\n'),
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.customQuotes),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              minLines: 8,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: t.quoteDialogHint,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rose,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final lines = controller.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                await _updateSetting(
                  'customQuotes',
                  lines.isEmpty ? t.defaultQuotes : lines,
                );

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _toast(t.quotesUpdated);
              },
              child: Text(t.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickReminderMinutes(
    BuildContext context,
    int current,
    AppText t,
  ) async {
    final items = <int>[10, 30, 60, 1440];

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.reminderDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((m) {
              return RadioListTile<int>(
                value: m,
                groupValue: current,
                activeColor: AppTheme.rose,
                title: Text(
                  t.reminderText(m),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onChanged: (value) async {
                  if (value == null) return;
                  await _updateSetting('reminderMinutes', value);
                  await NotificationService.instance.requestPermissions();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary(context),
        ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.softCardColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppTheme.isDark(context)
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.white.withValues(alpha: 0.65),
    );
  }

  Widget _rowButton(
    BuildContext context, {
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
                  color: color ?? AppTheme.textPrimary(context),
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _stepperRow(
    BuildContext context, {
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
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          "$value",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppTheme.textPrimary(context),
          ),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.pageTop(context),
                AppTheme.pageBottom(context),
              ],
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
                    final t = AppText((s['languageCode'] ?? 'en').toString());

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
                    final reminderMinutes = (s['reminderMinutes'] ?? 30) as int;
                    final languageCode = (s['languageCode'] ?? 'en').toString();

                    final customQuotes = (s['customQuotes'] is List)
                        ? (s['customQuotes'] as List)
                            .map((e) => e.toString())
                            .toList()
                        : t.defaultQuotes;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                      children: [
                        Row(
                          children: [
                            Text(
                              "⋯",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary(context),
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
                            color: AppTheme.profileHeaderColor(context),
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
                                    color: Colors.white.withValues(alpha: 0.9),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                ),
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
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Colors.white,
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
                          context,
                          child: Column(
                            children: [
                              _rowButton(
                                context,
                                title: t.editName,
                                trailing: Icon(
                                  Icons.edit_outlined,
                                  color: AppTheme.textPrimary(context),
                                ),
                                onTap: () => _editNameDialog(context, name, t),
                              ),
                              _divider(context),
                              _rowButton(
                                context,
                                title: t.editEmail,
                                trailing: Icon(
                                  Icons.alternate_email,
                                  color: AppTheme.textPrimary(context),
                                ),
                                onTap: () => _editEmailDialog(context, email, t),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle(context, t.settings),
                        _settingsCard(
                          context,
                          child: Column(
                            children: [
                              _rowButton(
                                context,
                                title: t.language,
                                trailing: Text(
                                  languageCode == 'ar'
                                      ? t.languageArabic
                                      : t.languageEnglish,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                onTap: () => _pickLanguageDialog(
                                  context,
                                  languageCode,
                                  t,
                                ),
                              ),
                              _divider(context),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  t.quotes,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                value: quotesEnabled,
                                onChanged: (v) => _updateSetting('quotesEnabled', v),
                              ),
                              if (quotesEnabled) ...[
                                _divider(context),
                                _rowButton(
                                  context,
                                  title: t.customQuotes,
                                  trailing: Text(
                                    "${customQuotes.length}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                  onTap: () => _editQuotesDialog(
                                    context,
                                    customQuotes,
                                    t,
                                  ),
                                ),
                              ],
                              _divider(context),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  t.enableReminders,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                value: notificationsEnabled,
                                onChanged: (v) async {
                                  await _updateSetting('notificationsEnabled', v);
                                  if (v) {
                                    await NotificationService.instance
                                        .requestPermissions();
                                  }
                                },
                              ),
                              if (notificationsEnabled) ...[
                                _divider(context),
                                _rowButton(
                                  context,
                                  title: t.reminderTime,
                                  trailing: Text(
                                    t.reminderText(reminderMinutes),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                  onTap: () => _pickReminderMinutes(
                                    context,
                                    reminderMinutes,
                                    t,
                                  ),
                                ),
                              ],
                              _divider(context),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  t.darkMode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                value: darkMode,
                                onChanged: (v) => _updateSetting('darkMode', v),
                              ),
                              _divider(context),
                              _rowButton(
                                context,
                                title: t.changePassword,
                                onTap: () => _changePasswordDialog(context, email, t),
                              ),
                              _divider(context),
                              _rowButton(
                                context,
                                title: t.contactUs,
                                onTap: () => _contactUsDialog(context, t),
                              ),
                              _divider(context),
                              _rowButton(
                                context,
                                title: t.logOut,
                                color: Colors.red.shade700,
                                onTap: () => _logout(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _settingsCard(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.homeDisplay,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _stepperRow(
                                context,
                                title: t.weeklyOnHome,
                                value: weeklyHomeLimit,
                                min: 1,
                                max: 10,
                                onChanged: (v) => _updateSetting(
                                  'weeklyHomeLimit',
                                  v,
                                ),
                              ),
                              _divider(context),
                              _stepperRow(
                                context,
                                title: t.appointmentsOnHome,
                                value: appointmentsHomeLimit,
                                min: 1,
                                max: 10,
                                onChanged: (v) => _updateSetting(
                                  'appointmentsHomeLimit',
                                  v,
                                ),
                              ),
                              _divider(context),
                              _stepperRow(
                                context,
                                title: t.tasksOnHome,
                                value: tasksHomeLimit,
                                min: 1,
                                max: 10,
                                onChanged: (v) => _updateSetting(
                                  'tasksHomeLimit',
                                  v,
                                ),
                              ),
                              _divider(context),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  t.showAllWeeklyOnHome,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                value: showAllWeeklyOnHome,
                                onChanged: (v) =>
                                    _updateSetting('showAllWeeklyOnHome', v),
                              ),
                              _divider(context),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  t.showAllDatedOnHome,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                value: showAllDatedOnHome,
                                onChanged: (v) =>
                                    _updateSetting('showAllDatedOnHome', v),
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