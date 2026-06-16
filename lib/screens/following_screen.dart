import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart'; // استيراد صفحة البروفايل للانتقال إليها عند الضغط

class FollowingScreen extends StatelessWidget {
  final String userId; 

  const FollowingScreen({super.key, required this.userId});

  // دالة جلب مصفوفة الـ following وجلب حساباتهم الكاملة بشكل آمن
  Future<List<dynamic>> _fetchFollowing() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. جلب بيانات المستخدم المستهدف لاستخراج مصفوفة الحسابات التي يتابعها
      final userData = await supabase
          .from('profiles')
          .select('following')
          .eq('id', userId)
          .single();

      final List<dynamic> followingIds = userData['following'] ?? [];

      if (followingIds.isEmpty) return [];

      // 2. جلب الحسابات الكاملة لجميع المعرفات دفعة واحدة
      final usersData = await supabase
          .from('profiles')
          .select()
          .inFilter('id', followingIds);

      return usersData as List<dynamic>;
    } catch (e) {
      debugPrint("❌ خطأ في جلب قائمة المتابعة: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, 
      child: Scaffold(
        backgroundColor: const Color(0xff121214), 
        appBar: AppBar(
          title: const Text(
            "قائمة المتابعة", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xff1A1A1E),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _fetchFollowing(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff7C3AED), strokeWidth: 3),
              );
            }
            
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "حدث خطأ أثناء تحميل القائمة ⚠️", 
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              );
            }
            
            final users = snapshot.data ?? [];
            
            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xff1E1E24),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1_outlined, size: 40, color: Colors.white24),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "لا يتابع أحداً حالياً", 
                      style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                
                // 🟢 استخراج البيانات بالمسميات الصحيحة والمطابقة لجداول السوبابيس لتجنب الكراش
                final String avatarUrl = user['avatar_url'] ?? '';
                final String displayName = user['display_name'] ?? 'مستخدم غير معروف';
                final String username = user['username'] ?? '';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xff1E1E24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: () {
                      // 🚀 ميزة التنقل: تفتح الحساب الشخصي للمستخدم الذي تابعه فوراً عند النقر
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xff7C3AED).withOpacity(0.3), width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xff121214),
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty 
                            ? const Icon(Icons.person, color: Colors.white38, size: 24) 
                            : null,
                      ),
                    ),
                    title: Text(
                      displayName, // الحقل المصلح
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      username.isNotEmpty ? '@$username' : '', 
                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded, // 🟢 سهم احترافي متناسق مع اتجاه التصفح العربي RTL
                      size: 12, 
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}