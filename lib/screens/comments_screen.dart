import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsScreen extends StatefulWidget {
  final int videoId; 

  const CommentsScreen({super.key, required this.videoId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  final List<String> _quickEmojis = ['❤️', '✨', '👏', '😂', '🔥', '😍', '🙌', '💯', '👍', '🌟'];

  final List<String> _emojiFontFallbacks = [
    'Apple Color Emoji',
    'Android Emoji',
    'Noto Color Emoji',
    'Segoe UI Emoji'
  ];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  void _insertEmoji(String emoji) {
    final text = _commentController.text;
    final textSelection = _commentController.selection;
    
    final newText = text.replaceRange(
      textSelection.start >= 0 ? textSelection.start : text.length,
      textSelection.end >= 0 ? textSelection.end : text.length,
      emoji,
    );
    
    final myTextLength = emoji.length;
    
    _commentController.text = newText;
    _commentController.selection = TextSelection.collapsed(
      offset: (textSelection.start >= 0 ? textSelection.start : text.length) + myTextLength,
    );
    setState(() {});
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      // هنا الإرسال صحيح لعمود 'text' كما هو موجود في قاعدة بياناتك
      await supabase.from('comments').insert({
        'video_id': widget.videoId, 
        'user_id': user.id,
        'text': text, 
        'created_at': DateTime.now().toIso8601String(),
      });

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("❌ خطأ أثناء إرسال التعليق: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleLikeComment(dynamic commentId) async {
    if (commentId == null) return;
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('comment_likes').insert({
        'comment_id': commentId,
        'user_id': user.id,
      });
    } catch (e) {
      debugPrint("خطأ أثناء الإعجاب بالتعليق: $e");
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xff1A1A1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4.5,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
            ),
            const Text(
              'التعليقات',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white10, height: 1),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('comments')
                    .stream(primaryKey: ['id'])
                    .eq('video_id', widget.videoId)
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('حدث خطأ أثناء تحميل التعليقات', style: TextStyle(color: Colors.white38, fontSize: 13)));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xff7C3AED), strokeWidth: 2));
                  }

                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد تعليقات بعد.\nكن أول من يترك بصمته الهادفة! ✨',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: comments.length,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final dynamic commentId = comment['id'];
                      
                      final String commentUserId = comment['user_id']?.toString() ?? '';
                      
                      String timeString = "قبل قليل";
                      if (comment['created_at'] != null) {
                        try {
                          timeString = timeago.format(DateTime.parse(comment['created_at'].toString()).toLocal(), locale: currentLocale);
                        } catch (_) {}
                      }

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: commentUserId.isEmpty 
                            ? Future.value(null) 
                            : supabase.from('profiles').select('username, avatar_url').eq('id', commentUserId).maybeSingle(),
                        builder: (context, profileSnapshot) {
                          if (profileSnapshot.connectionState == ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 18, backgroundColor: Colors.white.withOpacity(0.05)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(width: 80, height: 8, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
                                        const SizedBox(height: 6),
                                        Container(width: 140, height: 8, decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(4))),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          }

                          final profileData = profileSnapshot.data;
                          final String username = profileData?['username'] ?? 'مستخدم إيمان';
                          final String? avatarUrl = profileData?['avatar_url'];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xff7C3AED).withOpacity(0.1),
                                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                  child: (avatarUrl == null || avatarUrl.isEmpty) 
                                      ? Text(username.isNotEmpty ? username[0].toUpperCase() : "?", style: const TextStyle(color: Color(0xff7C3AED), fontSize: 13, fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(username, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Text(timeString, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      
                                      //  التعديل السحري هنا: تم تغيير الحقل من 'comment' إلى 'text' ليطابق قاعدة بياناتك تماماً
                                      Text(
                                        comment['text'] ?? '', 
                                        style: TextStyle(
                                          color: Colors.white, 
                                          fontSize: 13.5, 
                                          height: 1.3,
                                          fontFamilyFallback: _emojiFontFallbacks,
                                        ),
                                      ),
                                      
                                      Row(
                                        children: [
                                          TextButton(
                                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                                            onPressed: () {},
                                            child: const Text("رد", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.white38),
                                      onPressed: () {
                                        _toggleLikeComment(commentId);
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            
            SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xff121214),
                  border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _quickEmojis.length,
                        itemBuilder: (context, index) {
                          final emoji = _quickEmojis[index];
                          return InkWell(
                            onTap: () => _insertEmoji(emoji),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: TextStyle(fontSize: 20, fontFamilyFallback: _emojiFontFallbacks),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _commentController,
                                style: TextStyle(color: Colors.white, fontSize: 13.5, fontFamilyFallback: _emojiFontFallbacks),
                                maxLines: null,
                                decoration: const InputDecoration(
                                  hintText: "أضف تعليقاً هادفاً لأصحاب الفلوق...",
                                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12.5),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSending
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xff7C3AED), strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.send_rounded, color: Color(0xff7C3AED), size: 22),
                                  onPressed: _postComment,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}