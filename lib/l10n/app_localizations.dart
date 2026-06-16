import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Common
  String get error;
  String get email;
  String get password;

  // Home / Feed
  String get loading;
  String get errorLoadingVideos;
  String get noVideosAvailable;
  String get like;
  String get comment;
  String get share;

  // Notifications
  String get notifications;
  String get markedAllAsRead;
  String get today;
  String get likedVideo;
  String get fiveMinutesAgo;
  String get commentedOnVideo;
  String get twentyMinutesAgo;
  String get thisWeek;
  String get followedYou;
  String get twoDaysAgo;

  // Profile
  String get profile;
  String get profileUpdated;
  String get enterName;
  String get enterUsername;
  String get pickBirthDate;

  // Auth
  String get register;
  String get fullName;
  String get username;
  String get confirmPassword;
  String get passwordsDoNotMatch;
  String get accountCreated;

  // Settings
  String get settings;
  String get language;
  String get arabic;
  String get english;
  String get logout;
  String get deleteAccount;

  // About
  String get aboutApp;
  String get send;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'ar') {
      return AppLocalizationsAr();
    }
    return AppLocalizationsEn();
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get error => "Error";

  @override
  String get email => "Email";

  @override
  String get password => "Password";

  @override
  String get loading => "Loading...";

  @override
  String get errorLoadingVideos => "Error loading videos";

  @override
  String get noVideosAvailable => "No videos available";

  @override
  String get like => "Like";

  @override
  String get comment => "Comment";

  @override
  String get share => "Share";

  @override
  String get notifications => "Notifications";

  @override
  String get markedAllAsRead => "Marked all as read";

  @override
  String get today => "Today";

  @override
  String get likedVideo => "Liked your video";

  @override
  String get fiveMinutesAgo => "5 minutes ago";

  @override
  String get commentedOnVideo => "Commented on your video";

  @override
  String get twentyMinutesAgo => "20 minutes ago";

  @override
  String get thisWeek => "This week";

  @override
  String get followedYou => "Started following you";

  @override
  String get twoDaysAgo => "2 days ago";

  @override
  String get profile => "Profile";

  @override
  String get profileUpdated => "Profile updated";

  @override
  String get enterName => "Enter name";

  @override
  String get enterUsername => "Enter username";

  @override
  String get pickBirthDate => "Birth date";

  @override
  String get register => "Register";

  @override
  String get fullName => "Full Name";

  @override
  String get username => "Username";

  @override
  String get confirmPassword => "Confirm Password";

  @override
  String get passwordsDoNotMatch => "Passwords do not match";

  @override
  String get accountCreated => "Account created";

  @override
  String get settings => "Settings";

  @override
  String get language => "Language";

  @override
  String get arabic => "Arabic";

  @override
  String get english => "English";

  @override
  String get logout => "Logout";

  @override
  String get deleteAccount => "Delete Account";

  @override
  String get aboutApp => "About App";

  @override
  String get send => "Send";
}

class AppLocalizationsAr extends AppLocalizations {
  @override
  String get error => "خطأ";

  @override
  String get email => "البريد الإلكتروني";

  @override
  String get password => "كلمة المرور";

  @override
  String get loading => "جاري التحميل...";

  @override
  String get errorLoadingVideos => "حدث خطأ أثناء تحميل الفيديوهات";

  @override
  String get noVideosAvailable => "لا توجد فيديوهات";

  @override
  String get like => "إعجاب";

  @override
  String get comment => "تعليق";

  @override
  String get share => "مشاركة";

  @override
  String get notifications => "الإشعارات";

  @override
  String get markedAllAsRead => "تم تحديد الكل كمقروء";

  @override
  String get today => "اليوم";

  @override
  String get likedVideo => "أعجب بفيديوك";

  @override
  String get fiveMinutesAgo => "منذ 5 دقائق";

  @override
  String get commentedOnVideo => "علق على فيديوك";

  @override
  String get twentyMinutesAgo => "منذ 20 دقيقة";

  @override
  String get thisWeek => "هذا الأسبوع";

  @override
  String get followedYou => "بدأ بمتابعتك";

  @override
  String get twoDaysAgo => "منذ يومين";

  @override
  String get profile => "الملف الشخصي";

  @override
  String get profileUpdated => "تم تحديث الملف الشخصي";

  @override
  String get enterName => "أدخل الاسم";

  @override
  String get enterUsername => "أدخل اسم المستخدم";

  @override
  String get pickBirthDate => "تاريخ الميلاد";

  @override
  String get register => "تسجيل";

  @override
  String get fullName => "الاسم الكامل";

  @override
  String get username => "اسم المستخدم";

  @override
  String get confirmPassword => "تأكيد كلمة المرور";

  @override
  String get passwordsDoNotMatch => "كلمات المرور غير متطابقة";

  @override
  String get accountCreated => "تم إنشاء الحساب";

  @override
  String get settings => "الإعدادات";

  @override
  String get language => "اللغة";

  @override
  String get arabic => "العربية";

  @override
  String get english => "الإنجليزية";

  @override
  String get logout => "تسجيل الخروج";

  @override
  String get deleteAccount => "حذف الحساب";

  @override
  String get aboutApp => "عن التطبيق";

  @override
  String get send => "إرسال";
}