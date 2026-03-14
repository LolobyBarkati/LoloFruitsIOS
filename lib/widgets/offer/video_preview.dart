import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreview extends StatefulWidget {
  final String url;
  const VideoPreview({required this.url, super.key});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller!.play();
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}