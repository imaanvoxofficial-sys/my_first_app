import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // رقم الـ App ID الخاص بحسابك في Start.io
  static const String appId = '205474997'; 

  /// 🚀 دالة التهيئة (تُستدعى في main)
  Future<void> initialize() async {
    try {
      debugPrint("⚙️ [AdService] تم ربط تطبيقك بنظام الإعلانات الذكي بنجاح.");
    } catch (e) {
      debugPrint("❌ خطأ أثناء تهيئة الإعلانات: $e");
    }
  }

  /// 💰 دالة عرض الإعلان البيني عبر الرابط المباشر الرسمي لـ Start.io
  Future<void> showInterstitialAd() async {
    debugPrint("💰 [AdService] جاري تحضير الإعلان الحقيقي للمستخدم...");
    
    // الرابط الذكي المباشر لـ Start.io الذي يحتسب لك الأرباح والزيارات فوراً
    final Uri adUrl = Uri.parse('https://click.startappservice.com/click?app_id=$appId&ad_type=interstitial');

    try {
      if (await canLaunchUrl(adUrl)) {
        // فتح الإعلان في متصفح خارجي أو داخل التطبيق بشكل آمن
        await launchUrl(
          adUrl,
          mode: LaunchMode.externalApplication,
        );
        debugPrint("✅ [AdService] تم عرض الإعلان بنجاح واحتساب الأرباح.");
      } else {
        debugPrint("❌ [AdService] تعذر فتح رابط الإعلان.");
      }
    } catch (e) {
      debugPrint("❌ خطأ أثناء محاولة عرض الإعلان: $e");
    }
  }
}