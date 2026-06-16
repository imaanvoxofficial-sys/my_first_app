import 'package:flutter/material.dart';
import 'feed_screen.dart'; 
import 'create_screen.dart';
// 1. قمنا بإزالة hide NotificationsScreen لنتمكن من استخدامها
import 'notifications_screen.dart'; 
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  static const Color primaryColor = Color(0xff7C3AED);

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    // 2. تم حذف كلمة const من قبل NotificationsScreen() لأنها ديناميكية
    pages = [
      const FeedScreen(), 
      NotificationsScreen(), 
      const CreateScreen(),
      const SettingsScreen(), 
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121214), 
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xff1A1A1E), 
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.white30,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), 
              activeIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined), 
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'التنبيهات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded), 
              activeIcon: Icon(Icons.add_circle_rounded),
              label: 'إنشاء',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), 
              activeIcon: Icon(Icons.settings_rounded),
              label: 'الإعدادات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), 
              activeIcon: Icon(Icons.person_rounded),
              label: 'الملف',
            ),
          ],
        ),
      ),
    );
  }
}