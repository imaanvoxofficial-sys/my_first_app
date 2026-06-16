import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'video_player_screen.dart';
import 'edit_profile_screen.dart';
import 'video_grid_thumbnail.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  User? get currentLoggedInUser => supabase.auth.currentUser;

  late String targetUserId;
  bool _isMyOwnProfile = true;
  bool _isUploadingImage = false;
  bool _isFollowingTarget = false;

  int _localFollowersCount = 0;
  int _localFollowingCount = 0;

  static const String _baseUrl = "https://imaanvox.com/user/";

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  void _initializeProfile() {
    targetUserId = widget.userId ?? currentLoggedInUser?.id ?? '';
    _isMyOwnProfile = (targetUserId == currentLoggedInUser?.id);

    _localFollowersCount = 0;
    _localFollowingCount = 0;

    if (!_isMyOwnProfile && currentLoggedInUser != null) {
      _checkIfFollowing();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      setState(() {
        _initializeProfile();
      });
    }
  }

  Future<void> _checkIfFollowing() async {
    if (currentLoggedInUser == null) return;

    try {
      final res = await supabase
          .from('followers')
          .select()
          .eq('follower_id', currentLoggedInUser!.id)
          .eq('following_id', targetUserId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isFollowingTarget = res != null;
        });
      }
    } catch (_) {}
  }

  Future<void> _quickChangeAvatar() async {
    if (currentLoggedInUser == null) return;

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final fileFile = File(pickedFile.path);
      final fileExtension = pickedFile.path.split('.').last;
      final fileName =
          '${currentLoggedInUser!.id}_avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await supabase.storage.from('avatars').upload(fileName, fileFile);

      final newPhotoUrl =
          supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('profiles')
          .update({'avatar_url': newPhotoUrl})
          .eq('id', currentLoggedInUser!.id);

      _handleRefresh();
    } catch (_) {
      // ignore error
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _toggleFollowTarget() async {
    if (currentLoggedInUser == null) return;

    final previous = _isFollowingTarget;

    setState(() {
      _isFollowingTarget = !_isFollowingTarget;
      _localFollowersCount += _isFollowingTarget ? 1 : -1;
    });

    try {
      if (!previous) {
        await supabase.from('followers').insert({
          'follower_id': currentLoggedInUser!.id,
          'following_id': targetUserId,
        });
      } else {
        await supabase.from('followers').delete().eq(
            'follower_id', currentLoggedInUser!.id).eq(
            'following_id', targetUserId);
      }

      await supabase.from('profiles').update({
        'followers_count': _localFollowersCount
      }).eq('id', targetUserId);
    } catch (_) {
      setState(() {
        _isFollowingTarget = previous;
      });
    }
  }

  void _navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    ).then((value) {
      if (value == true) _handleRefresh();
    });
  }

  void _showSnackBar(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xff7C3AED),
      ),
    );
  }

  Future<Map<String, dynamic>> _getProfileAndUserData() async {
    Map<String, dynamic> profile = {};
    List videos = [];
    int totalLikes = 0;

    try {
      final res = await supabase
          .from('profiles')
          .select()
          .eq('id', targetUserId)
          .maybeSingle();

      if (res != null) {
        profile = res;
        _localFollowersCount = profile['followers_count'] ?? 0;
        _localFollowingCount = profile['following_count'] ?? 0;
        totalLikes = profile['total_likes'] ?? 0;
      }
    } catch (_) {}

    try {
      videos = await supabase
          .from('videos')
          .select()
          .eq('user_id', targetUserId)
          .order('created_at');
    } catch (_) {}

    return {
      'profile': profile,
      'videos': videos,
      'total_likes': totalLikes,
    };
  }

  Future<void> _handleRefresh() async {
    setState(() {});
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(value.toString(),
            style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white38)),
      ],
    );
  }

  Widget _squareButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: const Color(0xff26262B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121214),
      appBar: AppBar(
        title: Text(_isMyOwnProfile
            ? 'الملف الشخصي'
            : 'ملف المستخدم'),
        centerTitle: true,
        backgroundColor: const Color(0xff1A1A1E),
      ),

      body: FutureBuilder(
        future: _getProfileAndUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final profile = data['profile'];
          final videos = data['videos'];
          final likes = data['total_likes'];

          final username = profile['username'] ?? '';
          final name = profile['display_name'] ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 45,
                  backgroundImage: NetworkImage(
                    profile['avatar_url'] ??
                        'https://i.pravatar.cc/300',
                  ),
                ),

                const SizedBox(height: 10),

                Text(name,
                    style: const TextStyle(color: Colors.white)),

                Text("@$username",
                    style: const TextStyle(color: Colors.white38)),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn("لايكات", likes),
                    _buildStatColumn("متابعون", _localFollowersCount),
                    _buildStatColumn("يتابع", _localFollowingCount),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isMyOwnProfile
                            ? _navigateToEditScreen
                            : _toggleFollowTarget,
                        child: Text(_isMyOwnProfile
                            ? "تعديل الملف"
                            : "متابعة"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (videos.isEmpty)
                  const Text("لا يوجد فيديوهات",
                      style:
                          TextStyle(color: Colors.white38))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: videos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemBuilder: (context, i) {
                      final v = videos[i];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                videoUrl: v['video_url'],
                                videoData: v,
                                profileData: profile,
                              ),
                            ),
                          );
                        },
                        child: VideoGridThumbnail(
                          videoUrl: v['video_url'],
                          fallbackThumbnail:
                              v['thumbnail_url'],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}