import 'package:flutter/material.dart';
import 'package:startapp_sdk/startapp_sdk.dart'; // 🟢 الاستيراد الصحيح للحزمة الجديدة

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // رقم الـ App ID الخاص بحسابك
  static const String appId = '205474997'; 

  // متغيرات الحزمة الحقيقية لإدارة الإعلانات
  final StartAppSdk _sdk = StartAppSdk();
  StartAppInterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  /// 🚀 دالة التهيئة الحقيقية (تُستدعى في main)
  Future<void> initialize() async {
    try {
      // تهيئة الـ SDK باستخدام معرف تطبيقك
      _sdk.setAppId(appId);
      debugPrint("⚙️ [AdService] تم ربط تطبيقك بـ Start.io بنجاح.");
      
      // تحميل أول إعلان مسبقاً
      loadInterstitialAd();
    } catch (e) {
      debugPrint("❌ خطأ أثناء تهيئة StartApp SDK: $e");
    }
  }

  /// ⏳ دالة تحميل الإعلان البيني في الخلفية
  void loadInterstitialAd() {
    if (_isAdLoading || _interstitialAd != null) return;

    _isAdLoading = true;
    debugPrint("⏳ [AdService] جاري جلب إعلان بيني من السيرفر...");

    _sdk.loadInterstitialAd(
      onAdLoaded: (ad) {
        _interstitialAd = ad;
        _isAdLoading = false;
        debugPrint("✅ [AdService] الإعلان البيني جاهز للعرض الآن.");
      },
      onAdNotLoaded: (error) {
        _isAdLoading = false;
        _interstitialAd = null;
        debugPrint("❌ [AdService] فشل تحميل الإعلان: $error");
      },
    );
  }

  /// 💰 دالة عرض الإعلان ملء الشاشة
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      debugPrint("💰 [AdService] جاري عرض الإعلان البيني الحقيقي...");
      
      _interstitialAd!.show().then((_) {
        // بمجرد إغلاق أو انتهاء الإعلان، نقوم بتفريغه وشحن واحد جديد
        _interstitialAd = null;
        loadInterstitialAd();
      }).catchError((error) {
        debugPrint("❌ خطأ أثناء محاولة عرض الإعلان: $error");
        _interstitialAd = null;
        loadInterstitialAd();
      });
    } else {
      debugPrint("⚠️ [AdService] الإعلان غير جاهز بعد، جاري محاولة التحميل مجدداً.");
      loadInterstitialAd();
    }
  }
}