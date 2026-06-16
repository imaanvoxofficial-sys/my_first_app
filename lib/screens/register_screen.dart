import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_first_app/l10n/app_localizations.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordObscured = true;
  bool isConfirmPasswordObscured = true;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final lang = AppLocalizations.of(context)!;

    // التحقق من صحة المدخلات عبر الـ Form
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.passwordsDoNotMatch), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        // إدخال البيانات للجدول بالأسماء الصغيرة المتناسقة مع الـ Database
        await Supabase.instance.client.from('profiles').insert({
          'id': authResponse.user!.id,
          'name': nameController.text.trim(), 
          'username': usernameController.text.trim(),
          'followers': [], // تهيئة قائمة المتابعين فارغة كـ Array
          'following': [], // تهيئة قائمة المتابَعين فارغة كـ Array
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.accountCreated), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${lang.error}: ${e.toString()}'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xff121214), // نفس الخلفية الداكنة العميقة للتطبيق
      appBar: AppBar(
        title: Text(lang.register, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xff1A1A1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // نص ترحيبي فخم في البداية
                const Text(
                  "إنشاء حساب جديد ✨",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "انضم إلينا وابدأ بمشاركة فلوقاتك الإبداعية اليوم.",
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // حقول الإدخال الاحترافية المبطنة بالثيم الزجاجي الداكن
                _buildInputField(
                  controller: nameController,
                  label: lang.fullName,
                  icon: Icons.person_outline_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? 'الرجاء إدخال الاسم الكامل' : null,
                ),
                const SizedBox(height: 18),
                _buildInputField(
                  controller: usernameController,
                  label: lang.username,
                  icon: Icons.alternate_email_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? 'الرجاء إدخال اسم المستخدم' : null,
                ),
                const SizedBox(height: 18),
                _buildInputField(
                  controller: emailController,
                  label: lang.email,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) return 'الرجاء إدخال بريد إلكتروني صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _buildInputField(
                  controller: passwordController,
                  label: lang.password,
                  icon: Icons.lock_outline_rounded,
                  obscureText: isPasswordObscured,
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white30, size: 20),
                    onPressed: () => setState(() => isPasswordObscured = !isPasswordObscured),
                  ),
                  validator: (val) => val == null || val.length < 6 ? 'كلمة المرور يجب ألا تقل عن 6 أحرف' : null,
                ),
                const SizedBox(height: 18),
                _buildInputField(
                  controller: confirmPasswordController,
                  label: lang.confirmPassword,
                  icon: Icons.lock_clock_outlined,
                  obscureText: isConfirmPasswordObscured,
                  suffixIcon: IconButton(
                    icon: Icon(isConfirmPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white30, size: 20),
                    onPressed: () => setState(() => isConfirmPasswordObscured = !isConfirmPasswordObscured),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'الرجاء تأكيد كلمة المرور' : null,
                ),
                
                const SizedBox(height: 35),

                // زر التسجيل العريض والمضيء باللون البنفسجي الاستثنائي
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff7C3AED),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xff7C3AED).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      shadowColor: const Color(0xff7C3AED).withOpacity(0.4),
                    ),
                    onPressed: isLoading ? null : register,
                    child: isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                        : Text(lang.register, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة ذكية وموحدة لإنشاء حقول نصوص فائقة الجمال لمنع تكرار الكود
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xff7C3AED),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: Color(0xff7C3AED), fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: Colors.white30, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xff1E1E24), // تماثل لوني مع حقول شاشة التعديل
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff7C3AED), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}