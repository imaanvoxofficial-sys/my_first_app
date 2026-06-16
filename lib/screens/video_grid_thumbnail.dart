import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // 🟢 تم الاعتماد على المشغل الرسمي لضمان استقرار الـ Build

class VideoGridThumbnail extends StatefulWidget {
  final String videoUrl;
  final String? fallbackThumbnail;
  const VideoGridThumbnail({super.key, required this.videoUrl, this.fallbackThumbnail});

  @override
  State<VideoGridThumbnail> createState() => _VideoGridThumbnailState();
}

class _VideoGridThumbnailState extends State<VideoGridThumbnail> {
  VideoPlayerController? _thumbnailController; 
  bool _isReady = false;
  bool _isDisposed = false;
  bool _hasFallback = false;

  @override
  void initState() {
    super.initState();
    _hasFallback = widget.fallbackThumbnail != null && widget.fallbackThumbnail!.isNotEmpty;
    
    if (!_hasFallback) {
      _loadFirstFrame();
    }
  }

  Future<void> _loadFirstFrame() async {
    try {
      if (widget.videoUrl.isEmpty) return;
      
      _thumbnailController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _thumbnailController!.initialize();
      
      if (mounted && !_isDisposed) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint("خطأ في تحميل فريم الغلاف المصغر: $e");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _thumbnailController?.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasFallback) {
      return Image.network(
        widget.fallbackThumbnail!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (_isReady && _thumbnailController != null && !_isDisposed) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _thumbnailController!.value.size.width,
          height: _thumbnailController!.value.size.height,
          child: VideoPlayer(_thumbnailController!), 
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xff1E1E24),
      child: const Center(
        child: Icon(Icons.video_library_rounded, color: Colors.white12, size: 30),
      ),
    );
  }
}