import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

// تم الاستغناء عن flutter_dotenv مؤقتاً لضمان عمل التطبيق فوراً
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; 
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:my_first_app/services/ad_service.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 تهيئة Supabase مباشرة بالقيم لضمان عدم وجود خطأ (FileNotFoundError)
  const supabaseUrl = "https://huzfuutltdsdljgbmrnw.supabase.co";
  const supabaseAnonKey = "sb_publishable_BxzxkBPnL0tjQP5lJO2lmA_Xcan1CK8";

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    debugPrint("✅ تم تهيئة Supabase بنجاح");
  } catch (e) {
    debugPrint("❌ فشل تهيئة Supabase: $e");
  }

  // 4. تهيئة الخدمات
  try {
    await AdService().initialize();
  } catch (e) {
    debugPrint("⚠️ خطأ في تهيئة الإعلانات: $e");
  }

  timeago.setLocaleMessages('ar', timeago.ArMessages());
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(
    savedLocale: prefs.getString('locale') ?? 'ar',
  ));
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Imaan Vox',
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xff121214),
              body: Center(child: CircularProgressIndicator(color: Color(0xff7C3AED))),
            );
          }

          if (snapshot.hasError) {
             return Scaffold(body: Center(child: Text("خطأ في الاتصال: ${snapshot.error}")));
          }

          final session = snapshot.data?.session;
          return session == null ? const LoginScreen() : const HomeScreen();
        },
      ),
    );
  }
}