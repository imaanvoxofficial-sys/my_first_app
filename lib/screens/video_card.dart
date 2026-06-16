import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart'; // 🚀 ترقية المشغل لدعم الكاش الفوري
import 'package:share_plus/share_plus.dart';
import 'comments_screen.dart'; 
import 'profile_screen.dart'; 

class VideoCard extends StatefulWidget {
  final String videoId, videoUrl, username, description, currentUserId, avatarUrl;
  final int initialLikes, initialFollowers, initialComments, initialShares;
  final bool isFocused;

  const VideoCard({
    super.key, 
    required this.videoId, 
    required this.videoUrl, 
    required this.username,
    required this.avatarUrl, 
    required this.description, 
    required this.initialLikes, 
    required this.initialFollowers, 
    required this.initialComments,
    required this.initialShares, 
    required this.currentUserId, 
    required this.isFocused, 
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  final supabase = Supabase.instance.client;
  CachedVideoPlayerPlusController? _videoController; // استخدام مشغل الكاش المحترف
  bool isLiked = false, isFollowing = false, _isInitialized = false;
  bool _isClosed = false; // 🛡️ كاشف أمان لمنع الانهيارات أثناء الخروج

  @override
  void initState() {
    super.initState();
    _checkInteractions(); 
    if (widget.isFocused) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFocused && !oldWidget.isFocused) {
      _initializeVideo();
    } else if (!widget.isFocused && oldWidget.isFocused) {
      _disposeController();
    }
  }

  Future<void> _checkInteractions() async {
    try {
      final like = await supabase
          .from('likes')
          .select()
          .eq('video_id', widget.videoId)
          .eq('user_id', widget.currentUserId)
          .maybeSingle();

      final follow = await supabase
          .from('followers')
          .select()
          .eq('video_id', widget.videoId)
          .eq('user_id', widget.currentUserId)
          .maybeSingle();

      if (mounted && !_isClosed) {
        setState(() {
          isLiked = like != null;
          isFollowing = follow != null;
        });
      }
    } catch (_) {}
  }

  Future<void> _initializeVideo() async {
    try {
      if (_videoController != null || _isClosed) return;

      _videoController = CachedVideoPlayerPlusController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoController!.initialize();
      
      if (mounted && widget.isFocused && !_isClosed) {
        setState(() => _isInitialized = true);
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    } catch (e) {
      debugPrint("خطأ في تشغيل الفيديو الكاش: $e");
    }
  }

  Future<void> toggleLike() async {
    if (!mounted || _isClosed) return;
    setState(() => isLiked = !isLiked);
    try {
      if (isLiked) {
        await supabase.from('likes').insert({'video_id': widget.videoId, 'user_id': widget.currentUserId});
      } else {
        await supabase.from('likes').delete().eq('video_id', widget.videoId).eq('user_id', widget.currentUserId);
      }
    } catch (e) {
      debugPrint("خطأ في تحديث الإعجاب: $e");
    }
  }

  Future<void> toggleFollow() async {
    if (!mounted || _isClosed) return;
    setState(() => isFollowing = !isFollowing);
    try {
      if (isFollowing) {
        await supabase.from('followers').insert({'video_id': widget.videoId, 'user_id': widget.currentUserId});
      } else {
        await supabase.from('followers').delete().eq('video_id', widget.videoId).eq('user_id', widget.currentUserId);
      }
    } catch (e) {
      debugPrint("خطأ في تحديث المتابعة: $e");
    }
  }

  // 💬 دالة إظهار التعليقات المصلحة والمحمية بالكامل
  void _showComments() {
    // إيقاف الفيديو مؤقتاً لتسهيل الكتابة والقراءة للمستخدم
    if (_videoController != null && _videoController!.value.isInitialized && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1E1E24), 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // حماية شاشة التعليقات لئلا تتداخل مع لوحة المفاتيح
        return Padding(
          padding: EdgeInsets.varying(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75, 
            child: CommentsScreen(videoId: widget.videoId), // تمرير معرّف الفيديو للتعليقات الحقيقية
          ),
        );
      },
    ).then((_) {
      // إعادة تشغيل المقطع تلقائياً فور إغلاق قائمة التعليقات
      if (mounted && widget.isFocused && _videoController != null && !_videoController!.value.isPlaying && !_isClosed) {
        _videoController!.play();
      }
    });
  }

  void _shareVideo() {
    Share.share('شاهد هذا المقطع من @${widget.username} على تطبيقنا!\nرابط الفيديو: ${widget.videoUrl}');
  }

  Future<void> _reportVideo() async {
    try {
      await supabase.from('videos').update({'reports_count': 1}).eq('id', widget.videoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شكراً لك، تم تسجيل الإبلاغ وسيقوم المشرفون بمراجعته.'), 
            backgroundColor: Colors.amber, 
            duration: Duration(seconds: 2)
          )
        );
      }
    } catch (e) {
      debugPrint("خطأ أثناء الإبلاغ: $e");
    }
  }

  Future<void> _navigateToProfile() async {
    if (_videoController != null && _videoController!.value.isPlaying) {
      await _videoController!.pause();
    }

    if (!mounted) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );

    if (mounted && widget.isFocused && _videoController != null && !_isClosed) {
      _videoController!.play();
    }
  }

  void _disposeController() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
      _isInitialized = false;
    }
  }

  @override
  void dispose() {
    _isClosed = true; // تفعيل وضع الإغلاق لمنع العمليات غير المتزامنة تالياً
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // مشغل الفيديو الذكي
          GestureDetector(
            onTap: () {
              if (_videoController != null && _videoController!.value.isInitialized) {
                _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                setState(() {});
              }
            },
            child: _isInitialized && _videoController != null
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: CachedVideoPlayerPlus(_videoController!),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.white24)),
          ),

          // اسم الحساب والوصف (جهة اليمين)
          Positioned(
            right: 16,
            bottom: 30,
            left: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.username}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // الأزرار الجانبية العائمة المدمجة والمحاذية لجهة اليسار (Left)
          Positioned(
            left: 12,
            bottom: 40,
            child: Column(
              children: [
                _buildProfileButton(), 
                const SizedBox(height: 14), 
                
                _buildActionButton(
                  icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                  color: isLiked ? Colors.red : Colors.white, 
                  label: '${widget.initialLikes}', 
                  onTap: toggleLike
                ),
                const SizedBox(height: 14),
                
                _buildActionButton(
                  icon: Icons.chat_bubble_rounded, 
                  color: Colors.white, 
                  label: '${widget.initialComments}', 
                  onTap: _showComments // استدعاء الدالة المصلحة والآمنة
                ),
                const SizedBox(height: 14),
                
                _buildActionButton(
                  icon: Icons.reply_rounded, 
                  color: Colors.white, 
                  label: '${widget.initialShares}', 
                  onTap: _shareVideo
                ),
                const SizedBox(height: 14),
                
                _buildActionButton(
                  icon: Icons.report_gmailerrorred_rounded, 
                  color: Colors.amber, 
                  label: 'إبلاغ', 
                  onTap: _reportVideo
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return SizedBox(
      width: 60,
      height: 54, 
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none, 
        children: [
          GestureDetector(
            onTap: _navigateToProfile, 
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.black,
                backgroundImage: widget.avatarUrl.isNotEmpty ? NetworkImage(widget.avatarUrl) : null,
                child: widget.avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 28) : null,
              ),
            ),
          ),
          Positioned(
            bottom: -4, 
            child: GestureDetector(
              onTap: toggleFollow,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isFollowing ? Colors.blue : Colors.redAccent, 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2), 
                ),
                child: Icon(
                  isFollowing ? Icons.check : Icons.add, 
                  color: Colors.white, 
                  size: 11, 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 2), 
          Text(
            label,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 12, 
              fontWeight: FontWeight.w600, 
              shadows: [Shadow(blurRadius: 2, color: Colors.black)]
            ),
          ),
        ],
      ),
    );
  }
}