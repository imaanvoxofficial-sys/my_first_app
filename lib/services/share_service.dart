import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  // 📋 دالة نسخ رابط الحساب الشخصي
  static void copyProfileLink(String username) {
    // يمكنك تعديل الرابط ليناسب الدومين الخاص بتطبيقك
    final String profileUrl = "https://imaanvox.com/$username"; 
    Clipboard.setData(ClipboardData(text: profileUrl));
  }

  // 🔗 دالة مشاركة الحساب عبر التطبيقات الأخرى
  static Future<void> shareProfile(String username) async {
    final String profileUrl = "https://imaanvox.com/$username";
    await Share.share(
      "تابعني على تطبيق إيمان فوكس! حسابي هو: @$username\n$profileUrl",
      subject: "مشاركة الملف الشخصي",
    );
  }
}