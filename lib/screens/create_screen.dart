import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // 🛠️ دالة اختيار الفيديو الموحدة (استوديو أو كاميرا) مع تحديد المدة بدقيقة واحدة
  Future<void> _getVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1), // ⏱️ حصر الفيديو بدقيقة واحدة لحماية قاعدة البيانات
      );
      
      if (video != null) {
        setState(() => _selectedVideo = File(video.path));
      }
    } catch (e) {
      _showSnack("خطأ أثناء جلب الفيديو: $e", Colors.redAccent);
    }
  }

  // 📸 نافذة خيارات اختيار مصدر الفيديو بتصميم عصري
  void _showSourcePickerBottomSheet() {
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
                  "إضافة مقطع جديد",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "الحد الأقصى لطول المقطع هو دقيقة واحدة لضمان سرعة الرفع ✨",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xff7C3AED).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.videocam_rounded, color: Color(0xff7C3AED), size: 22),
                  ),
                  title: const Text("تسجيل عبر الكاميرا", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                  onTap: () {
                    Navigator.pop(context);
                    _getVideo(ImageSource.camera);
                  },
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.video_collection_rounded, color: Colors.blueAccent, size: 22),
                  ),
                  title: const Text("اختيار من معرض الاستوديو", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                  onTap: () {
                    Navigator.pop(context);
                    _getVideo(ImageSource.gallery);
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

  Future<void> _uploadVideoAndPublish() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (_selectedVideo == null) {
      _showSnack("الرجاء اختيار أو تصوير فيديو أولاً.", Colors.orangeAccent);
      return;
    }
    if (user == null) {
      _showSnack("يجب تسجيل الدخول لنشر فيديو.", Colors.redAccent);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}${path.extension(_selectedVideo!.path)}";
      final filePath = 'videos/${user.id}/$fileName';

      // رفع الفيديو إلى Storage
      await supabase.storage.from('videos').upload(filePath, _selectedVideo!);
      final String videoUrl = supabase.storage.from('videos').getPublicUrl(filePath);

      // إدراج بيانات الفيديو في جدول videos
      await supabase.from('videos').insert({
        'video_url': videoUrl,
        'user_id': user.id,
        'description': _descriptionController.text.trim(),
        'likes_count': 0,
        'comments_count': 0,
        'shares_count': 0,
      });

      _showSnack("🎉 تم نشر المقطع بنجاح!", Colors.green);
      
      if (mounted) {
        setState(() {
          _selectedVideo = null;
          _descriptionController.clear();
        });
      }
    } catch (error) {
      _showSnack("فشل الرفع: ${error.toString()}", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // دعم التنسيق العربي بشكل افتراضي كامل للشاشة
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('إنشاء مقطع جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: const Color(0xff1A1A1E),
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _showSourcePickerBottomSheet, // 👈 يفتح القائمة السفلية الذكية الآن
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xff7C3AED).withOpacity(0.2), width: 1.5),
                  ),
                  child: _selectedVideo == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.video_library_rounded, size: 54, color: Color(0xff7C3AED)),
                            SizedBox(height: 12),
                            Text('إضغط هنا لإضافة فيديو', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                            SizedBox(height: 6),
                            Text('كاميرا أو استوديو (بحد أقصى دقيقة)', style: TextStyle(color: Colors.white30, fontSize: 11)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 54, color: Colors.green),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                path.basename(_selectedVideo!.path), 
                                style: const TextStyle(color: Colors.white70, fontSize: 13), 
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _showSourcePickerBottomSheet,
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white38),
                              label: const Text("تغيير المقطع", style: TextStyle(color: Colors.white38, fontSize: 12)),
                            )
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب وصفاً للمقطع الهادف...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  fillColor: Colors.white.withOpacity(0.04),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: const BorderSide(color: Color(0xff7C3AED), width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xff7C3AED)))
                  : ElevatedButton.icon(
                      onPressed: _uploadVideoAndPublish,
                      icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                      label: const Text('نشر المقطع الآن', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}