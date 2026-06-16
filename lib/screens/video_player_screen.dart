import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
// 🟢 استيراد سيرفيس الإعلانات الخاص بـ Start.io
import 'package:my_first_app/services/ad_service.dart'; 

class VideoPlayerScreen extends StatefulWidget {
  final String? videoUrl; 
  final Map<String, dynamic>? videoData; 
  final Map<String, dynamic>? profileData; 

  const VideoPlayerScreen({
    super.key,
    this.videoUrl,
    this.videoData,
    this.profileData,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

// 🚀 أضفنا هنا WidgetsBindingObserver لمراقبة خروج المستخدم وقفل الهاتف فوراً
class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  VideoPlayerController? _controller; 
  bool _isInitialized = false;
  bool _isClosed = false; // 🛡️ متغير أمان لمنع تشغيل الفيديو بعد تدمير الشاشة

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // تفعيل مراقب دورت الحياة

    final url = widget.videoUrl ?? '';
    if (url.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          // نتأكد أن الشاشة ما زالت مفتوحة ولم يتم إغلاقها أثناء التحميل
          if (mounted && !_isClosed) {
            setState(() {
              _isInitialized = true;
            });
            _controller?.play();
            _controller?.setLooping(true);
          }
        }).catchError((error) {
          debugPrint("Error initializing video player: $error");
        });
    }
  }

  // 🛑 كاتم الصوت الفوري والذكي إذا خرج المستخدم من التطبيق أو قفل الشاشة
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed && _isInitialized && !_isClosed) {
      _controller?.play();
    }
  }

  @override
  void dispose() {
    _isClosed = true; // تفعيل وضع الإغلاق فوراً
    WidgetsBinding.instance.removeObserver(this); // إلغاء المراقب
    _controller?.pause(); // إيقاف قاطع للصوت قبل التدمير
    _controller?.dispose();
    super.dispose();
  }

  void _showFullDescription() {
    final caption = widget.videoData?['caption']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1A1A1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              caption,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
            ),
          ),
        );
      },
    );
  }

  void _showComments() {
    // 🛡️ تأمين فحص المشغل بشكل صارم لمنع انهيار الشاشة الحمراء
    if (_controller != null && _controller!.value.isInitialized && _controller!.value.isPlaying) {
      _controller!.pause();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1A1A1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return const SizedBox(
          height: 400,
          child: Center(
            child: Text(
              'سيتم ربط التعليقات الحقيقية لاحقاً',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        );
      },
    ).then((_) {
      // إعادة التشغيل الآمن فقط إذا كانت الشاشة نشطة والمشغل واقف
      if (mounted && _isInitialized && _controller != null && !_controller!.value.isPlaying && !_isClosed) {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final likes = widget.videoData?['likes_count'] ?? 0;
    final comments = widget.videoData?['comments_count'] ?? 0;
    final shares = widget.videoData?['shares_count'] ?? 0;

    final displayName = widget.profileData?['display_name'] ?? 'مستخدم';
    final avatarUrl = widget.profileData?['avatar_url']?.toString() ?? '';
    final caption = widget.videoData?['caption']?.toString() ?? '';
    final safeVideoUrl = widget.videoUrl ?? 'unknown_video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: VisibilityDetector(
        key: Key('video_$safeVideoUrl'), 
        onVisibilityChanged: (visibilityInfo) {
          if (!mounted || _isClosed) return;
          double visiblePercentage = visibilityInfo.visibleFraction * 100;
          
          // إذا اختفى الفيديو بنسبة أكبر من 50% نقتله برمجياً لمنع الصوت في الخلفية تماماً
          if (visiblePercentage < 50) {
            _controller?.pause();
          } else {
            if (_isInitialized && _controller != null && !_controller!.value.isPlaying) {
              _controller!.play();
            }
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_controller != null && _controller!.value.isInitialized) {
                    setState(() {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                    });
                  }
                },
                child: Container(
                  color: Colors.black,
                  child: _isInitialized && _controller != null
                      ? SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controller!.value.size.width,
                              height: _controller!.value.size.height,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            ),

            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    _isClosed = true; // إيقاف فوري لمنع أي ردود فعل
                    _controller?.pause(); 
                    AdService().showInterstitialAd();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

            Positioned(
              bottom: 80,
              left: 15,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 20),
                  const Icon(Icons.favorite, color: Colors.red, size: 32),
                  const SizedBox(height: 4),
                  Text('$likes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _showComments, // 🟢 تم تأمينها بالكامل هنا
                    child: const Icon(Icons.comment_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 4),
                  Text('$comments', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  const Icon(Icons.share_rounded, color: Colors.white, size: 32),
                  const SizedBox(height: 4),
                  Text('$shares', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Positioned(
              bottom: 80,
              right: 15,
              left: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  if (caption.length > 60)
                    GestureDetector(
                      onTap: _showFullDescription,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text('المزيد', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}