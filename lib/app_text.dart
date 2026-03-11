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
  String get changePassword =>
      isArabic ? 'تغيير كلمة المرور' : 'Change password';
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
  String get weeklyOnHome =>
      isArabic ? 'الأسبوعي في الرئيسية' : 'Weekly on home';
  String get appointmentsOnHome =>
      isArabic ? 'المواعيد في الرئيسية' : 'Appointments on home';
  String get tasksOnHome => isArabic ? 'المهام في الرئيسية' : 'Tasks on home';
  String get showAllWeeklyOnHome => isArabic
      ? 'إظهار كل الأسبوعي في الرئيسية'
      : 'Show all weekly classes on home';
  String get showAllDatedOnHome => isArabic
      ? 'إظهار كل المواعيد المؤرخة في الرئيسية'
      : 'Show all dated appointments on home';

  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get restore => isArabic ? 'استرجاع' : 'Restore';
  String get active => isArabic ? 'نشطة' : 'Active';
  String get completed => isArabic ? 'مكتملة' : 'Completed';
  String get overdue => isArabic ? 'متأخرة' : 'Overdue';

  String get name => isArabic ? 'الاسم' : 'Name';
  String get email => isArabic ? 'الإيميل' : 'Email';
  String get title => isArabic ? 'العنوان' : 'Title';
  String get course => isArabic ? 'المادة' : 'Course';
  String get room => isArabic ? 'القاعة' : 'Room';
  String get day => isArabic ? 'اليوم' : 'Day';
  String get start => isArabic ? 'البداية' : 'Start';
  String get end => isArabic ? 'النهاية' : 'End';
  String get scale => isArabic ? 'السلم' : 'Scale';
  String get grade => isArabic ? 'التقدير' : 'Grade';
  String get credits => isArabic ? 'الساعات' : 'Credits';
  String get points => isArabic ? 'النقاط' : 'Points';
  String get previousCredits =>
      isArabic ? 'الساعات السابقة' : 'Previous Credits';
  String get previousGpa => isArabic ? 'المعدل السابق' : 'Previous GPA';

  String get quoteDialogHint => isArabic
      ? 'اكتبي كل عبارة في سطر مستقل'
      : 'Write each quote on a separate line';

  String get quotesUpdated =>
      isArabic ? 'تم تحديث العبارات' : 'Quotes updated';
  String get languageUpdated =>
      isArabic ? 'تم تغيير اللغة' : 'Language updated';
  String get nameUpdated => isArabic ? 'تم تحديث الاسم' : 'Name updated.';
  String get emailCheck => isArabic
      ? 'تحققي من الإيميل لتأكيد التغيير.'
      : 'Check your email to confirm the change.';
  String get emailUpdateError => isArabic
      ? 'تعذر تحديث الإيميل. سجلي الدخول مرة أخرى.'
      : 'Could not update email. Try logging in again.';
  String get fillAllFields =>
      isArabic ? 'عبّي كل الخانات.' : 'Fill all fields.';
  String get newPasswordMin => isArabic
      ? 'كلمة المرور الجديدة لازم تكون 6 أحرف على الأقل.'
      : 'New password must be at least 6 characters.';
  String get passwordsNoMatch =>
      isArabic ? 'كلمتا المرور غير متطابقتين.' : 'Passwords do not match.';
  String get passwordUpdated => isArabic
      ? 'تم تحديث كلمة المرور بنجاح.'
      : 'Password updated successfully.';
  String get passwordUpdateError => isArabic
      ? 'تعذر تغيير كلمة المرور. تأكدي من كلمة المرور الحالية.'
      : 'Could not change password. Check your current password.';

  String get contactTitle => isArabic ? 'تواصل معنا' : 'Contact us';
  String get supportTitle =>
      isArabic ? 'دعم Student Mate' : 'Student Mate support';

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

  String get addTask => isArabic ? 'إضافة مهمة' : 'Add Task';
  String get editTask => isArabic ? 'تعديل المهمة' : 'Edit Task';
  String get noDeadline => isArabic ? 'بدون موعد نهائي' : 'No deadline';
  String get pickDeadline =>
      isArabic ? 'اختيار الموعد النهائي' : 'Pick deadline';
  String get taskSaved => isArabic ? 'تم حفظ المهمة' : 'Task saved';
  String get taskUpdated => isArabic ? 'تم تحديث المهمة' : 'Task updated';
  String get taskDeleted => isArabic ? 'تم حذف المهمة' : 'Task deleted';
  String get taskRestored => isArabic ? 'تم استرجاع المهمة' : 'Restored';
  String get markedCompleted =>
      isArabic ? 'تم وضعها كمكتملة' : 'Marked as completed';
  String get noCompletedTasks =>
      isArabic ? 'لا توجد مهام مكتملة' : 'No completed tasks';

  String get dateExpired => isArabic ? 'انتهى التاريخ' : 'Date expired';
  String get editDate => isArabic ? 'تعديل التاريخ' : 'Edit date';

  String dateExpiredMessage(String typeName) => isArabic
      ? 'تاريخ $typeName انتهى بالفعل.\nعدلي التاريخ أولًا إذا تبين استرجاعه.'
      : 'This $typeName date has already passed.\nEdit the date first if you want to restore it.';

  String get addNote => isArabic ? 'إضافة ملاحظة' : 'Add Note';
  String get editNote => isArabic ? 'تعديل الملاحظة' : 'Edit Note';
  String get writeYourNote =>
      isArabic ? 'اكتبي ملاحظتك' : 'Write your note';
  String get searchNotes => isArabic ? 'ابحثي في الملاحظات' : 'Search notes';
  String get noNotesYet => isArabic ? 'لا توجد ملاحظات بعد' : 'No notes yet';
  String get noNoteFound =>
      isArabic ? 'لم يتم العثور على ملاحظة' : 'No note found';
  String get untitledNote =>
      isArabic ? 'ملاحظة بدون عنوان' : 'Untitled note';
  String get noContent => isArabic ? 'لا يوجد محتوى' : 'No content';
  String get noteSaved => isArabic ? 'تم حفظ الملاحظة' : 'Note saved';
  String get noteUpdated => isArabic ? 'تم تحديث الملاحظة' : 'Note updated';
  String get noteDeleted => isArabic ? 'تم حذف الملاحظة' : 'Note deleted';

  String get addCourse => isArabic ? 'إضافة مادة' : 'Add course';
  String get semesterGpa => isArabic ? 'معدل الفصل' : 'Semester GPA';
  String get cumulativeGpa => isArabic ? 'المعدل التراكمي' : 'Cumulative GPA';
  String get cumulativeSettings =>
      isArabic ? 'إعدادات المعدل التراكمي' : 'Cumulative settings';
  String get gpaOutOf4 => isArabic ? 'المعدل من 4' : 'GPA out of 4';
  String get gpaOutOf5 => isArabic ? 'المعدل من 5' : 'GPA out of 5';
  String get prev => isArabic ? 'السابق' : 'Prev';
  String get addBtn => isArabic ? 'إضافة' : 'Add';
  String get settingsSaved =>
      isArabic ? 'تم حفظ الإعدادات' : 'Settings saved';
  String get courseSaved => isArabic ? 'تم حفظ المادة' : 'Course saved';
  String get courseDeleted => isArabic ? 'تم حذف المادة' : 'Course deleted';
  String get noCoursesYet => isArabic
      ? 'لا توجد مواد بعد.\nاضغطي إضافة للبدء.'
      : 'No courses yet.\nPress Add to start.';

  String get weeklyClasses =>
      isArabic ? 'المحاضرات الأسبوعية' : 'Weekly classes';
  String get examsEvents =>
      isArabic ? 'الاختبارات / المواعيد' : 'Exams / Events';
  String get addWeeklyClass =>
      isArabic ? 'إضافة محاضرة أسبوعية' : 'Add Weekly class';
  String get editWeeklyClass =>
      isArabic ? 'تعديل المحاضرة الأسبوعية' : 'Edit Weekly class';
  String get addExamEvent =>
      isArabic ? 'إضافة اختبار / موعد' : 'Add Exam / Event';
  String get editExamEvent =>
      isArabic ? 'تعديل الاختبار / الموعد' : 'Edit Exam / Event';
  String get weeklyClassSaved =>
      isArabic ? 'تم حفظ المحاضرة الأسبوعية' : 'Weekly class saved';
  String get weeklyClassUpdated =>
      isArabic ? 'تم تحديث المحاضرة الأسبوعية' : 'Weekly class updated';
  String get appointmentSaved =>
      isArabic ? 'تم حفظ الموعد' : 'Appointment saved';
  String get appointmentUpdated =>
      isArabic ? 'تم تحديث الموعد' : 'Appointment updated';
  String get appointmentDeleted =>
      isArabic ? 'تم حذف الموعد' : 'Deleted';
  String get appointmentRestored =>
      isArabic ? 'تم استرجاع الموعد' : 'Restored';
  String get noActiveDatedEvents => isArabic
      ? 'لا توجد مواعيد نشطة بتاريخ'
      : 'No active dated events';
  String get noCompletedAppointments => isArabic
      ? 'لا توجد مواعيد مكتملة'
      : 'No completed appointments';
  String get appointmentWord => isArabic ? 'الموعد' : 'appointment';

  String get sunday => isArabic ? 'الأحد' : 'Sunday';
  String get monday => isArabic ? 'الاثنين' : 'Monday';
  String get tuesday => isArabic ? 'الثلاثاء' : 'Tuesday';
  String get wednesday => isArabic ? 'الأربعاء' : 'Wednesday';
  String get thursday => isArabic ? 'الخميس' : 'Thursday';
  String get friday => isArabic ? 'الجمعة' : 'Friday';
  String get saturday => isArabic ? 'السبت' : 'Saturday';

  String shortDay(int index) {
    if (isArabic) {
      const names = ['أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
      return names[(index - 1).clamp(0, 6)];
    }
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return names[(index - 1).clamp(0, 6)];
  }

  String fullDay(int index) {
    if (isArabic) {
      const names = [
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت'
      ];
      return names[(index - 1).clamp(0, 6)];
    }
    const names = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return names[(index - 1).clamp(0, 6)];
  }

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