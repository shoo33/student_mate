class AppText {
  final String languageCode;

  const AppText(this.languageCode);

  bool get isArabic => languageCode == 'ar';

  String get appTitle => isArabic ? 'ستودنت ميت' : 'Student Mate';

  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get tasks => isArabic ? 'المهام' : 'Tasks';
  String get schedule => isArabic ? 'الجدول' : 'Schedule';
  String get notes => isArabic ? 'الملاحظات' : 'Notes';
  String get gpa => isArabic ? 'المعدل' : 'GPA';
  String get profile => isArabic ? 'الحساب' : 'Profile';

  String get weekly => isArabic ? 'الأسبوعي' : 'Weekly';
  String get appointments => isArabic ? 'المواعيد' : 'Appointments';
  String get more => isArabic ? 'المزيد' : 'More';
  String get add => isArabic ? 'إضافة' : 'Add';

  String get noWeeklyClasses =>
      isArabic ? 'لا توجد محاضرات أسبوعية' : 'No weekly classes';
  String get noDatedEvents =>
      isArabic ? 'لا توجد مواعيد بتاريخ' : 'No dated events';
  String get noTasks => isArabic ? 'لا توجد مهام' : 'No tasks';

  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get editName => isArabic ? 'تعديل الاسم' : 'Edit name';
  String get editEmail => isArabic ? 'تعديل الإيميل' : 'Edit email';
  String get changePassword => isArabic ? 'تغيير كلمة المرور' : 'Change password';
  String get contactUs => isArabic ? 'تواصل معنا' : 'Contact us';
  String get logOut => isArabic ? 'تسجيل الخروج' : 'Log out';

  String get quotes => isArabic ? 'العبارات التحفيزية' : 'Quotes';
  String get customQuotes => isArabic ? 'عباراتي التحفيزية' : 'My quotes';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get enableReminders =>
      isArabic ? 'تفعيل التذكيرات' : 'Enable reminders';
  String get reminderTime => isArabic ? 'وقت التذكير' : 'Reminder time';
  String get darkMode => isArabic ? 'الوضع الليلي' : 'Dark mode';

  String get homeDisplay => isArabic ? 'عرض الرئيسية' : 'Home display';
  String get weeklyOnHome => isArabic ? 'الأسبوعي في الرئيسية' : 'Weekly on home';
  String get appointmentsOnHome =>
      isArabic ? 'المواعيد في الرئيسية' : 'Appointments on home';
  String get tasksOnHome => isArabic ? 'المهام في الرئيسية' : 'Tasks on home';
  String get showAllWeeklyOnHome =>
      isArabic ? 'إظهار كل الأسبوعي في الرئيسية' : 'Show all weekly classes on home';
  String get showAllDatedOnHome =>
      isArabic ? 'إظهار كل المواعيد المؤرخة في الرئيسية' : 'Show all dated appointments on home';

  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get close => isArabic ? 'إغلاق' : 'Close';

  String get name => isArabic ? 'الاسم' : 'Name';
  String get email => isArabic ? 'الإيميل' : 'Email';

  String get quoteDialogHint => isArabic
      ? 'اكتبي كل عبارة في سطر مستقل'
      : 'Write each quote on a separate line';

  String get quotesUpdated =>
      isArabic ? 'تم تحديث العبارات' : 'Quotes updated';
  String get languageUpdated =>
      isArabic ? 'تم تغيير اللغة' : 'Language updated';
  String get nameUpdated =>
      isArabic ? 'تم تحديث الاسم' : 'Name updated.';
  String get emailCheck =>
      isArabic ? 'تحققي من الإيميل لتأكيد التغيير.' : 'Check your email to confirm the change.';
  String get emailUpdateError =>
      isArabic ? 'تعذر تحديث الإيميل. سجلي الدخول مرة أخرى.' : 'Could not update email. Try logging in again.';
  String get fillAllFields =>
      isArabic ? 'عبّي كل الخانات.' : 'Fill all fields.';
  String get newPasswordMin =>
      isArabic ? 'كلمة المرور الجديدة لازم تكون 6 أحرف على الأقل.'
      : 'New password must be at least 6 characters.';
  String get passwordsNoMatch =>
      isArabic ? 'كلمتا المرور غير متطابقتين.' : 'Passwords do not match.';
  String get passwordUpdated =>
      isArabic ? 'تم تحديث كلمة المرور بنجاح.' : 'Password updated successfully.';
  String get passwordUpdateError =>
      isArabic ? 'تعذر تغيير كلمة المرور. تأكدي من كلمة المرور الحالية.'
      : 'Could not change password. Check your current password.';

  String get contactTitle => isArabic ? 'تواصل معنا' : 'Contact us';
  String get supportTitle => isArabic ? 'دعم Student Mate' : 'Student Mate support';
  String get supportNote => isArabic
      ? 'تقدرين تبدلين هذا لاحقًا بإيميل فريقكم الحقيقي.'
      : 'You can replace this later with your real team email.';

  String get currentPassword =>
      isArabic ? 'كلمة المرور الحالية' : 'Current password';
  String get newPassword =>
      isArabic ? 'كلمة المرور الجديدة' : 'New password';
  String get confirmNewPassword =>
      isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm new password';

  String get editNameTitle => isArabic ? 'تعديل الاسم' : 'Edit name';
  String get editEmailTitle => isArabic ? 'تعديل الإيميل' : 'Edit email';
  String get changePasswordTitle =>
      isArabic ? 'تغيير كلمة المرور' : 'Change password';

  String get verificationEmailHint => isArabic
      ? 'قد يتم إرسال رسالة تحقق لتأكيد الإيميل الجديد.'
      : 'A verification email may be sent to confirm the new address.';

  String get reminderDialogTitle =>
      isArabic ? 'وقت التذكير' : 'Reminder time';

  String reminderText(int minutes) {
    if (isArabic) {
      switch (minutes) {
        case 10:
          return 'قبل 10 دقائق';
        case 30:
          return 'قبل 30 دقيقة';
        case 60:
          return 'قبل ساعة';
        case 1440:
          return 'قبل يوم';
        default:
          return 'قبل 30 دقيقة';
      }
    } else {
      switch (minutes) {
        case 10:
          return '10 min before';
        case 30:
          return '30 min before';
        case 60:
          return '1 hour before';
        case 1440:
          return '1 day before';
        default:
          return '30 min before';
      }
    }
  }

  String get languageArabic => 'العربية';
  String get languageEnglish => 'English';

  List<String> get defaultQuotes => isArabic
      ? const [
          'ابدئي بخطوة صغيرة اليوم.',
          'كل مهمة تنجزينها تقربك لهدفك.',
          'التنظيم اليوم يريحك بكرة.',
          'الالتزام البسيط يصنع فرقًا كبيرًا.',
          'خذيها مهمة مهمة وبتوصلين.',
        ]
      : const [
          'Start with one small step today.',
          'Every finished task moves you forward.',
          'Organize today, relax tomorrow.',
          'Small consistency creates big results.',
          'One task at a time.',
        ];
}