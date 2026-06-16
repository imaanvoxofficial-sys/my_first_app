import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_first_app/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  static const Color primaryColor = Color(0xff7C3AED);
  static const Color backgroundColor = Color(0xff121214); 
  static const Color cardColor = Color(0xff1A1A1E);

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint("خطأ أثناء تحديث الإشعارات: $e");
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint("خطأ أثناء قراءة الإشعار: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          lang.notifications,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff1A1A1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: primaryColor, size: 22),
            onPressed: () async {
              await _markAllAsRead();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lang.markedAllAsRead),
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', _supabase.auth.currentUser!.id)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 50, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 12),
                  const Text(
                    "لا توجد إشعارات حالياً",
                    style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final note = notifications[index];
              
              String timeString = "منذ قليل";
              if (note['created_at'] != null) {
                final DateTime createdAt = DateTime.parse(note['created_at']).toLocal();
                timeString = timeago.format(createdAt, locale: currentLocale);
              }
              
              IconData icon = Icons.notifications;
              Color iconColor = primaryColor;
              
              if (note['type'] == 'like') {
                icon = Icons.favorite_rounded;
                iconColor = Colors.redAccent;
              } else if (note['type'] == 'comment') {
                icon = Icons.comment_rounded;
                iconColor = const Color(0xff0EA5E9);
              } else if (note['type'] == 'follow') {
                icon = Icons.person_add_alt_1_rounded;
                iconColor = Colors.greenAccent;
              }

              return _NotificationItem(
                name: note['sender_name'] ?? 'مستخدم',
                actionText: note['type'] == 'like' 
                    ? lang.likedVideo 
                    : (note['type'] == 'comment' ? lang.commentedOnVideo : lang.followedYou),
                time: timeString, 
                icon: icon,
                iconColor: iconColor,
                isUnread: !(note['is_read'] ?? true),
                cardColor: cardColor,
                primaryColor: primaryColor,
                onTap: () => _markAsRead(note['id'].toString()), 
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String name;
  final String actionText;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;
  final Color cardColor;
  final Color primaryColor;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.name,
    required this.actionText,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.isUnread,
    required this.cardColor,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.02),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ✅ تم إصلاح الخطأ هنا: إزالة الـ const من الـ CircleAvatar لأن التكست يعتمد على متغيرات ديناميكية
              CircleAvatar(
                radius: 22,
                backgroundColor: primaryColor.withOpacity(0.08),
                child: Text(
                  name.isNotEmpty ? name[0] : "?",
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$name ', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)
                          ),
                          TextSpan(
                            text: actionText, 
                            style: const TextStyle(color: Colors.white70, fontSize: 13)
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(icon, color: iconColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          time, 
                          style: const TextStyle(fontSize: 11, color: Colors.white30, fontWeight: FontWeight.w400)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ✅ تم إصلاح الخطأ هنا أيضاً: حذف الـ const لأن الـ primaryColor يمنع الـ compile الثابت مسبقاً
              if (isUnread)
                Container(
                  width: 8, 
                  height: 8, 
                  decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)
                )
            ],
          ),
        ),
      ),
    );
  }
}