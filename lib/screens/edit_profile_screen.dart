import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _birthDateController = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _loading = false;

  String _initialName = '';
  String _initialUsername = '';
  String _initialBio = '';
  String _initialBirthDate = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (!mounted) return;
      setState(() => _loading = true);

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || data == null) return;

      setState(() {
        _initialName = data['display_name'] ?? '';
        _initialUsername = data['username'] ?? '';
        _initialBio = data['bio'] ?? '';
        _initialBirthDate = data['birth_date'] ?? '';

        _nameController.text = _initialName;
        _usernameController.text = _initialUsername;
        _bioController.text = _initialBio;
        _birthDateController.text = _initialBirthDate;
      });
    } catch (e) {
      debugPrint("❌ خطأ في جلب البيانات: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xff7C3AED),
              surface: Color(0xff1A1A1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xff121214),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final lang = AppLocalizations.of(context)!;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    final cleanUsername = _usernameController.text
        .trim()
        .toLowerCase()
        .replaceAll('@', '')
        .replaceAll(' ', '');

    final cleanName = _nameController.text.trim();
    final cleanBio = _bioController.text.trim();
    final cleanBirthDate = _birthDateController.text.trim();

    final Map<String, dynamic> updatedData = {};

    if (cleanName != _initialName) {
      updatedData['display_name'] = cleanName;
    }

    if (cleanUsername != _initialUsername) {
      updatedData['username'] = cleanUsername;
    }

    if (cleanBio != _initialBio) {
      updatedData['bio'] = cleanBio.isEmpty ? null : cleanBio;
    }

    if (cleanBirthDate != _initialBirthDate) {
      updatedData['birth_date'] =
          cleanBirthDate.isEmpty ? null : cleanBirthDate;
    }

    if (updatedData.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context);
      }
      return;
    }

    try {
      await supabase
          .from('profiles')
          .update(updatedData)
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.profileUpdated,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "حدث خطأ أثناء الحفظ، قد يكون اسم المستخدم مأخوذاً مسبقاً ⚠️",
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xff121214),
      appBar: AppBar(
        title: const Text(
          "تعديل الملف الشخصي",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xff1A1A1E),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xff7C3AED),
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _nameController,
                      label: "الاسم المستعار",
                      icon: Icons.person_outline,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "الاسم لا يمكن أن يكون فارغاً";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _usernameController,
                      label: "اسم المستخدم",
                      icon: Icons.alternate_email,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "اسم المستخدم مطلوب";
                        }

                        final value =
                            val.replaceAll('@', '').trim();

                        if (!RegExp(r'^[a-zA-Z0-9_]+$')
                            .hasMatch(value)) {
                          return "مسموح فقط أحرف إنجليزية وأرقام و _";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _birthDateController,
                      label: "تاريخ الميلاد",
                      icon: Icons.cake,
                      readOnly: true,
                      onTap: _pickDate,
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _bioController,
                      label: "النبذة",
                      icon: Icons.description,
                      maxLines: 3,
                      maxLength: 150,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff7C3AED),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          lang.send,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xff1E1E24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}