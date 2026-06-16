import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'profile_screen.dart'; 

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

// إضافة WidgetsBindingObserver لمراقبة خروج التطبيق للخلفية (Home/تطبيقات أخرى)
class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;
  final currentUser = Supabase.instance.client.auth.currentUser;
  
  List<dynamic> _videos = [];
  bool _isLoading = true;
  int _focusedIndex = 0; // تتبع الفيديو النشط حالياً

  final Map<String, bool> _likedVideos = {};
  final Map<String, int> _videoLikesCount = {};
  final Map<String, int> _videoCommentsCount = {}; 
  final Map<String, int> _videoSharesCount = {};   
  final Map<String, bool> _followedUsers = {};
  final Map<String, int> _videoReportsCount = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // تسجيل المراقب
    _fetchFeedVideos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // إلغاء المراقب حماية للذاكرة
    super.dispose();
  }

  // إيقاف الفيديوهات مؤقتاً إذا خرج المستخدم من التطبيق تماماً (مثلاً للرد على مكالمة)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() {
        // سيؤدي هذا لتنبيه العناصر الفرعية للتوقف
        _focusedIndex = -1; 
      });
    }
  }

  // 1. جلب الفيديوهات من قاعدة البيانات
  Future<void> _fetchFeedVideos() async {
    try {
      final List<dynamic> response = await supabase
          .from('videos')
          .select('*, profiles(*)') 
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _videos = response;
          _isLoading = false;
          
          for (var video in _videos) {
            final videoId = video['id'].toString();
            _videoLikesCount[videoId] = video['likes_count'] ?? 0;
            _videoCommentsCount[videoId] = video['comments_count'] ?? 0;
            _videoSharesCount[videoId] = video['shares_count'] ?? 0;
            _likedVideos[videoId] = false; 
            _videoReportsCount[videoId] = 0; 
            
            final authorId = video['user_id'].toString();
            _followedUsers[authorId] = false; 
          }
        });
        // استدعاء الفحص المحسن والذكي
        _checkLikesAndFollowsOptimized(response);
      }
    } catch (e) {
      print("❌ خطأ سوبابيز في شاشة الـ Feed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 💡 حل مشكلة الحفظ الفوري (تحسين الاستعلام بطلب واحد مجمع للكل Bulk Query)
  Future<void> _checkLikesAndFollowsOptimized(List<dynamic> videos) async {
    if (currentUser == null || videos.isEmpty) return;

    try {
      final videoIds = videos.map((v) => v['id'].toString()).toList();
      final authorIds = videos.map((v) => v['user_id'].toString()).toSet().toList();

      // جلب كل الإعجابات الخاصة بالمستخدم لهذه الفيديوهات بطلب واحد فقط
      final likesResponse = await supabase
          .from('likes')
          .select('video_id')
          .eq('user_id', currentUser!.id)
          .inFilter('video_id', videoIds);

      // جلب كل المتابعات الخاصة بالمستخدم لهؤلاء الصناع بطلب واحد فقط
      final followsResponse = await supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', currentUser!.id)
          .inFilter('following_id', authorIds);

      if (mounted) {
        setState(() {
          for (var like in likesResponse) {
            _likedVideos[like['video_id'].toString()] = true;
          }
          for (var follow in followsResponse) {
            _followedUsers[follow['following_id'].toString()] = true;
          }
        });
      }
    } catch (e) {
      print("❌ خطأ فحص الإعجابات والمتابعات المحسن: $e");
    }
  }

  // 2. التفاعل مع زر الإعجاب
  Future<void> _handleLike(String videoId) async {
    if (currentUser == null) return;
    final isLiked = _likedVideos[videoId] ?? false;
    final currentLikes = _videoLikesCount[videoId] ?? 0;

    setState(() {
      _likedVideos[videoId] = !isLiked;
      _videoLikesCount[videoId] = !isLiked ? currentLikes + 1 : currentLikes - 1;
    });

    try {
      if (!isLiked) {
        await supabase.from('likes').insert({'user_id': currentUser!.id, 'video_id': videoId});
      } else {
        await supabase.from('likes').delete().eq('user_id', currentUser!.id).eq('video_id', videoId);
      }
      
      await supabase.from('videos').update({'likes_count': _videoLikesCount[videoId]}).eq('id', videoId);
    } catch (e) {
      print("❌ خطأ تحديث الإعجاب: $e");
      setState(() {
        _likedVideos[videoId] = isLiked;
        _videoLikesCount[videoId] = currentLikes;
      });
    }
  }

  // 3. التفاعل مع زر المتابعة
  Future<void> _handleFollow(String authorId) async {
    if (currentUser == null || currentUser!.id == authorId) return;
    final isFollowed = _followedUsers[authorId] ?? false;

    setState(() {
      _followedUsers[authorId] = !isFollowed;
    });

    try {
      if (!isFollowed) {
        await supabase.from('followers').insert({'follower_id': currentUser!.id, 'following_id': authorId});
      } else {
        await supabase.from('followers').delete().eq('follower_id', currentUser!.id).eq('following_id', authorId);
      }
    } catch (e) {
      print("❌ خطأ تحديث المتابعة: $e");
      setState(() {
        _followedUsers[authorId] = isFollowed;
      });
    }
  }

  // 🔗 مشاركة الفيديوهات
  Future<void> _handleShare(String videoId, String username, String caption) async {
    final currentShares = _videoSharesCount[videoId] ?? 0;
    setState(() { _videoSharesCount[videoId] = currentShares + 1; });

    try {
      final String deepLinkString = "https://imaanvox.com/user/$username/video/$videoId";
      await Share.shareUri(Uri.parse(deepLinkString));
      
      await supabase.from('videos').update({'shares_count': _videoSharesCount[videoId]}).eq('id', videoId);
    } catch (e) {
      print("❌ خطأ مشاركة: $e");
    }
  }

  // نظام التبليغات
  void _showReportDialog(String videoId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1A1A1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('إرسال بلاغ', textAlign: TextAlign.right, style: TextStyle(color: Colors.white)),
        content: const Text('هل تريد الإبلاغ عن هذا المقطع؟', textAlign: TextAlign.right, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              int currentReports = (_videoReportsCount[videoId] ?? 0) + 1;
              _videoReportsCount[videoId] = currentReports;

              try {
                await supabase.from('reports').insert({'video_id': videoId, 'user_id': currentUser?.id});
              } catch (_) {}

              if (currentReports >= 3) {
                setState(() { _videos.removeAt(index); });
              }
            },
            child: const Text('تبليغ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // نافذة التعليقات المرنة والمصلحة نهائياً 🛠️
  void _showCommentsBottomSheet(String videoId) {
    final TextEditingController commentController = TextEditingController();

    // فحص أمان مسبق للتأكد من أن المعرف ليس فارغاً
    if (videoId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذراً، معرّف الفيديو غير صالح.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1A1A1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 15, right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("التعليقات (${_videoCommentsCount[videoId] ?? 0})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white10),
                  FutureBuilder<List<dynamic>>(
                    // تم الاعتماد على الـ videoId كـ String مباشرة لمرونة الربط مع الجداول والتوافق التام
                    future: supabase.from('comments').select('*, profiles(*)').eq('video_id', videoId).order('created_at', ascending: true),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Color(0xff7C3AED))));
                      }
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return const SizedBox(
                          height: 100,
                          child: Center(child: Text("لا توجد تعليقات بعد. كن أول من يعلق! 💬", style: TextStyle(color: Colors.white38, fontSize: 13))),
                        );
                      }
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final profile = comment['profiles'] as Map<String, dynamic>? ?? {};
                            return ListTile(
                              leading: CircleAvatar(backgroundImage: NetworkImage(profile['avatar_url'] ?? 'https://i.pravatar.cc/300')),
                              title: Text(profile['display_name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              subtitle: Text(comment['comment'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "أضف تعليقاً...",
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xff26262B),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xff7C3AED)),
                          onPressed: () async {
                            if (commentController.text.trim().isEmpty || currentUser == null) return;
                            final text = commentController.text.trim();
                            commentController.clear();
                            try {
                              await supabase.from('comments').insert({'video_id': videoId, 'user_id': currentUser!.id, 'comment': text});
                              this.setState(() { _videoCommentsCount[videoId] = (_videoCommentsCount[videoId] ?? 0) + 1; });
                              await supabase.from('videos').update({'comments_count': _videoCommentsCount[videoId]}).eq('id', videoId);
                              setModalState(() {});
                            } catch (e) { 
                              print("❌ خطأ أثناء إرسال التعليق: $e"); 
                            }
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xff7C3AED)))
            : _videos.isEmpty
                ? const Center(child: Text("لا توجد مقاطع فيديو حالياً 🎬", style: TextStyle(color: Colors.white38)))
                : PageView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: _videos.length,
                    onPageChanged: (index) {
                      setState(() {
                        _focusedIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      final videoId = video['id'].toString();
                      final author = video['profiles'] as Map<String, dynamic>? ?? {};
                      final authorId = video['user_id'].toString();
                      final username = author['username'] ?? authorId;
                      final caption = video['caption'] ?? '';

                      return FeedVideoItem(
                        key: ValueKey(videoId),
                        videoUrl: video['video_url'] ?? '',
                        videoId: videoId,
                        author: author,
                        authorId: authorId,
                        caption: caption,
                        likesCount: _videoLikesCount[videoId] ?? 0,
                        commentsCount: _videoCommentsCount[videoId] ?? 0,
                        sharesCount: _videoSharesCount[videoId] ?? 0,
                        isLiked: _likedVideos[videoId] ?? false,
                        isFollowed: _followedUsers[authorId] ?? false,
                        isMyOwnVideo: currentUser?.id == authorId,
                        isFocused: index == _focusedIndex, 
                        onLike: () => _handleLike(videoId),
                        onFollow: () => _handleFollow(authorId),
                        onShare: () => _handleShare(videoId, username, caption), 
                        onReport: () => _showReportDialog(videoId, index),
                        onComment: () => _showCommentsBottomSheet(videoId),
                        onProfileBack: (bool dynamicFollowStatus) {
                          if (mounted && _followedUsers[authorId] != dynamicFollowStatus) {
                            setState(() {
                              _followedUsers[authorId] = dynamicFollowStatus;
                            });
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class FeedVideoItem extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final Map<String, dynamic> author;
  final String authorId;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isFollowed;
  final bool isMyOwnVideo;
  final bool isFocused; 
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onComment;
  final Function(bool) onProfileBack; 

  const FeedVideoItem({
    super.key,
    required this.videoUrl,
    required this.videoId,
    required this.author,
    required this.authorId,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLiked,
    required this.isFollowed,
    required this.isMyOwnVideo,
    required this.isFocused,
    required this.onLike,
    required this.onFollow,
    required this.onShare,
    required this.onReport,
    required this.onComment,
    required this.onProfileBack,
  });

  @override
  State<FeedVideoItem> createState() => _FeedVideoItemState();
}

class _FeedVideoItemState extends State<FeedVideoItem> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() { _isInitialized = true; });
          if (widget.isFocused) {
            _videoController.play();
          }
          _videoController.setLooping(true);
        }
      });
  }

  void _navigateToProfile() async {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    }
    
    final bool? updatedFollowStatus = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.authorId)),
    );

    if (updatedFollowStatus != null) {
      widget.onProfileBack(updatedFollowStatus);
    }
    
    if (mounted && widget.isFocused) {
      _videoController.play();
    }
  }

  @override
  void didUpdateWidget(covariant FeedVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isFocused && !oldWidget.isFocused) {
        _videoController.play();
      } else if (!widget.isFocused && oldWidget.isFocused) {
        _videoController.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController.pause(); 
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_videoController.value.isPlaying) {
                _videoController.pause();
              } else {
                _videoController.play();
              }
            },
            child: Container(
              color: const Color(0xff121214),
              child: _isInitialized
                  ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController.value.size.width,
                          height: _videoController.value.size.height,
                          child: VideoPlayer(_videoController),
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator(color: Color(0xff7C3AED))),
            ),
          ),
        ),

        // الأزرار الجانبية التفاعلية
        Positioned(
          bottom: 30, 
          left: 15,    
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none, 
                children: [
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(widget.author['avatar_url'] ?? 'https://i.pravatar.cc/300'),
                      ),
                    ),
                  ),
                  if (!widget.isMyOwnVideo)
                    Positioned(
                      bottom: -4, 
                      child: GestureDetector(
                        onTap: widget.onFollow,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: widget.isFollowed ? Colors.green : const Color(0xff7C3AED),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            widget.isFollowed ? Icons.check : Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14), 
              IconButton(
                icon: Icon(widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: widget.isLiked ? Colors.red : Colors.white, size: 34),
                onPressed: widget.onLike,
              ),
              Text('${widget.likesCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10), 
              IconButton(
                icon: const Icon(Icons.comment_rounded, color: Colors.white, size: 30),
                onPressed: widget.onComment,
              ),
              Text('${widget.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10), 
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 30),
                onPressed: widget.onShare,
              ),
              Text('${widget.sharesCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14), 
              IconButton(
                icon: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.white70, size: 28),
                onPressed: widget.onReport,
              ),
              const Text('تبليغ', style: TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
        ),

        // النصوص والوصف بالأسفل
        Positioned(
          bottom: 35,
          right: 20,
          left: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.author['display_name'] ?? 'مستخدم إيمان فوكس',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                widget.caption,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}