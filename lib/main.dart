import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; 
import 'utils/app_theme.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
// 🟢 استيراد ملف سيرفيس الإعلانات الخاص بـ Start.io
import 'package:my_first_app/services/ad_service.dart'; 

Future<void> main() async {
  // التأكد من تهيئة Flutter قبل أي شيء
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 1. تهيئة نظام إعلانات Start.io لتكون جاهزة للعمل
  await AdService().initialize();
  
  // ⏳ 2. شحن أول إعلان بيني في الخلفية ليكون جاهزاً فوراً للعرض
  AdService().loadInterstitialAd();

  // تهيئة Supabase بالبيانات الحقيقية للمشروع
  await Supabase.initialize(
    url: 'https://huzfuutltdsdljgbmrnw.supabase.co',
    anonKey: 'sb_publishable_BxzxkBPnL0tjQP5lJO2lmA_Xcan1CK8',
  );

  // إعداد لغة الوقت للعربية
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MyApp(
      savedLocale: prefs.getString('locale') ?? 'ar',
    ),
  );
}

class MyApp extends StatefulWidget {
  final String savedLocale;
  const MyApp({super.key, required this.savedLocale});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.savedLocale);
  }

  // دالة ديناميكية لتغيير اللغة من أي مكان داخل التطبيق وحفظها
  void changeLocale(Locale newLocale) async {
    setState(() {
      _locale = newLocale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Imaan Vox',
      
      // 🛠️ تم التعديل هنا ليعمل التطبيق بالهوية الداكنة الفخمة المتناسقة
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff121214),
        primaryColor: const Color(0xff7C3AED),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff7C3AED),
          surface: Color(0xff1E1E24),
        ),
      ),
      
      locale: _locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // حالة التحميل أثناء التحقق من الجلسة (تم جعلها داكنة لمنع الوميض الأبيض المفاجئ)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xff121214),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xff7C3AED), // اللون البنفسجي المميز للتطبيق
                  strokeWidth: 3,
                ),
              ),
            );
          }

          final session = snapshot.data?.session;

          // إذا لم توجد جلسة، انتقل لشاشة الدخول
          if (session == null) {
            return const LoginScreen();
          }

          // إذا وُجدت جلسة، انتقل للشاشة الرئيسية
          return const HomeScreen(); 
        },
      ),
    );
  }
}