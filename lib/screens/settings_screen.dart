import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 📋 مطلوبة لعملية نسخ النصوص للحافظة
import 'package:share_plus/share_plus.dart'; // 🔗 مطلوبة لمشاركة الرابط عبر التطبيقات الأخرى
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;
  bool _loading = false;
  String _currentUsername = ''; // 🔥 لتخزين اسم المستخدم الحالي ديناميكياً

  // 🔗 الروابط الرسمية الخاصة بتطبيق Imaan Vox
  final String telegramUrl = "https://t.me/Imaan_Vox";
  final String xUrl = "https://x.com/Imaan_Vox";

  @override
  void initState() {
    super.initState();
    _fetchCurrentUsername(); // جلب اسم المستخدم عند بناء الصفحة
  }

  // 📥 دالة سريعة لجلب اسم المستخدم الحالي من جدول الـ profiles لتمريره للروابط
  Future<void> _fetchCurrentUsername() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .single();
      
      if (mounted) {
        setState(() {
          _currentUsername = data['username'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("خطأ في جلب اسم المستخدم: $e");
    }
  }

  // 📋 دالة نسخ رابط الحساب الشخصي
  void _copyProfileLink() {
    if (_currentUsername.isEmpty) {
      _showSnack("يتعذر جلب بيانات الحساب حالياً ⚠️", Colors.orangeAccent);
      return;
    }
    final String profileUrl = "https://imaanvox.com/$_currentUsername"; 
    Clipboard.setData(ClipboardData(text: profileUrl));
    _showSnack("تم نسخ رابط ملفك الشخصي بنجاح! 📋", const Color(0xff7C3AED));
  }

  // 🔗 دالة مشاركة الحساب عبر منصات التواصل
  Future<void> _shareProfile() async {
    if (_currentUsername.isEmpty) {
      _showSnack("يتعذر جلب بيانات الحساب حالياً ⚠️", Colors.orangeAccent);
      return;
    }
    final String profileUrl = "https://imaanvox.com/$_currentUsername";
    await Share.share(
      "تابعني على تطبيق إيمان فوكس! حسابي هو: @$_currentUsername\n$profileUrl",
      subject: "مشاركة الملف الشخصي",
    );
  }

  // دالة مساعدة لفتح الروابط الخارجية بشكل آمن
  Future<void> _openLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnack("تعذر فتح الرابط حالياً ⚠️", Colors.orangeAccent);
      }
    } catch (e) {
      _showSnack("خطأ في الانتقال للرابط", Colors.redAccent);
    }
  }

  Future<void> _logout() async {
    try {
      setState(() => _loading = true);
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showSnack("خطأ أثناء تسجيل الخروج ❌", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("حذف الحساب نهائياً ⚠️", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text("هل أنت متأكد من حذف حسابك؟ هذا الإجراء سيقوم بإزالة بياناتك وفيديوهاتك الشخصية ولا يمكن التراجع عنه مطلقاً.", 
          style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("إلغاء", style: TextStyle(color: Colors.white38))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("حذف الحساب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _loading = true);
      await supabase.from('profiles').delete().eq('id', user.id);
      await supabase.auth.signOut();
      
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showSnack("حدث خطأ، يرجى إعادة المحاولة لاحقاً", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1E1E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "مركز المساعدة والدعم",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "يسعدنا تواصلك معنا عبر منصاتنا الرسمية للإجابة على استفساراتك:",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xff0088cc).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.telegram, color: Color(0xff0088cc), size: 24),
                  ),
                  title: const Text("قناة التيليجرام الفنية", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                  onTap: () {
                    Navigator.pop(context);
                    _openLink(telegramUrl);
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  title: const Text("حسابنا على منصة إكس (تويتر)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                  onTap: () {
                    Navigator.pop(context);
                    _openLink(xUrl);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("سياسة الخصوصية والأمان 🛡️", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Text(
            "في تطبيق Imaan Vox، نلتزم بحماية خصوصية بياناتك ومعلوماتك الشخصية بشكل كامل:\n\n"
            "1. تشفير البيانات: يتم حفظ كلمات المرور وبيانات الهوية بشكل مشفر تماماً عبر خوادم Supabase الآمنة.\n\n"
            "2. المحتوى المرئي: الفيديوهات والفلوقات التي تقوم برفعها تخضع لملكية حسابك الشخصي، ولا يتم مشاركتها مع أي جهات خارجية.\n\n"
            "3. حذف الحساب: عند قيامك بحذف الحساب، يتم إزالة كافة بياناتك، ملفك الشخصي، وفيديوهاتك من قاعدة البيانات نهائياً وبشكل فوري دون الاحتفاظ بنسخ احتياطية.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13, fontFamily: 'Cairo')),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff121214),
        appBar: AppBar(
          title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          centerTitle: true,
          backgroundColor: const Color(0xff1A1A1E),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                
                // 🔥 القسم الجديد: التفاعل ونشر الحساب الشخصي
                _buildSectionTitle("تفاعل ونشر الحساب"),
                const SizedBox(height: 10),
                Container(
                  decoration: _buildBoxDecoration(),
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.share_rounded,
                        iconColor: const Color(0xff7C3AED),
                        title: "مشاركة الملف الشخصي",
                        onTap: _shareProfile,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildListTile(
                        icon: Icons.copy_rounded,
                        iconColor: Colors.amber,
                        title: "نسخ رابط الحساب",
                        onTap: _copyProfileLink,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                _buildSectionTitle("الدعم والمساعدة"),
                const SizedBox(height: 10),
                Container(
                  decoration: _buildBoxDecoration(),
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xff7C3AED),
                        title: "مركز المساعدة والدعم",
                        onTap: _showSupportBottomSheet,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildListTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: Colors.green,
                        title: "سياسة الخصوصية والأمان",
                        onTap: _showPrivacyDialog,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildListTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.cyan,
                        title: "حول تطبيق Imaan Vox",
                        trailing: const Text("الإصدار 1.0.0", style: TextStyle(color: Colors.white30, fontSize: 12)),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),

                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white70),
                    label: const Text("تسجيل الخروج", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ),
                ),
                
                const SizedBox(height: 14),
                
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2A1418), 
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.15)),
                      ),
                    ),
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text("حذف الحساب نهائياً", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            
            if (_loading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xff7C3AED), strokeWidth: 3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xff1E1E24),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.02)),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
    );
  }
}