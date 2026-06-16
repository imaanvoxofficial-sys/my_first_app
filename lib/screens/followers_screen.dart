import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart'; // استيراد صفحة البروفايل للانتقال إليها

class FollowersScreen extends StatelessWidget {
  final String userId; 
  
  const FollowersScreen({super.key, required this.userId});

  Future<List<dynamic>> _fetchFollowers() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. جلب بيانات المتابعين المبرمجة داخل الـ profiles
      final userData = await supabase
          .from('profiles')
          .select('followers')
          .eq('id', userId)
          .single();

      final List<dynamic> followersIds = userData['followers'] ?? [];

      if (followersIds.isEmpty) return [];

      // 2. جلب الحسابات الكاملة للمعرفات المتطابقة
      final usersData = await supabase
          .from('profiles')
          .select()
          .inFilter('id', followersIds);

      return usersData as List<dynamic>;
    } catch (e) {
      debugPrint("❌ خطأ في جلب قائمة المتابعين: $e");
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
            "المتابعون", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xff1A1A1E),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _fetchFollowers(),
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
                      child: const Icon(Icons.people_outline_rounded, size: 40, color: Colors.white24),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "لا يوجد متابعون حالياً", 
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
                      // 🚀 ميزة تفاعلية: عند الضغط على المتابع يفتح حسابه الشخصي فوراً
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(), // يمكنك تعديلها مستقبلاً لتستقبل الـ userId للحساب الآخر
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
                      displayName, // 🟢 تعديل الحقل ليطابق السوبابيس
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      username.isNotEmpty ? '@$username' : '', 
                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded, // 🟢 سهم متناسق مع اتجاه القراءة العربي RTL
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