import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/products_api.dart';

class ProductMediaPreview extends StatelessWidget {
  const ProductMediaPreview({
    super.key,
    required this.product,
    this.media,
    this.enableVideoPlayback = false,
    this.autoPlayVideo = false,
  });

  final LendProduct product;
  final LendProductImage? media;
  final bool enableVideoPlayback;
  final bool autoPlayVideo;

  @override
  Widget build(BuildContext context) {
    final media = this.media ?? product.primaryMedia;

    if (media == null || media.url.isEmpty) {
      return const ColoredBox(color: Color(0xFFE2E2E2));
    }

    if (media.isVideo) {
      return _NetworkVideoPreview(
        key: ValueKey(media.url),
        url: media.url,
        enablePlayback: enableVideoPlayback,
        autoPlay: autoPlayVideo,
      );
    }

    return Image.network(
      media.url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(color: Color(0xFFE2E2E2));
      },
    );
  }
}

class _NetworkVideoPreview extends StatefulWidget {
  const _NetworkVideoPreview({
    super.key,
    required this.url,
    required this.enablePlayback,
    required this.autoPlay,
  });

  final String url;
  final bool enablePlayback;
  final bool autoPlay;

  @override
  State<_NetworkVideoPreview> createState() => _NetworkVideoPreviewState();
}

class _NetworkVideoPreviewState extends State<_NetworkVideoPreview> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initializeFuture = _controller.initialize().then((_) async {
      await _controller.seekTo(Duration.zero);
      if (widget.autoPlay) {
        await _controller.play();
      } else {
        await _controller.pause();
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NetworkVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.autoPlay == widget.autoPlay ||
        !_controller.value.isInitialized) {
      return;
    }

    if (widget.autoPlay) {
      _controller.play();
    } else {
      _controller.pause();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlayback() async {
    if (!widget.enablePlayback || !_controller.value.isInitialized) {
      return;
    }

    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            !_controller.value.isInitialized) {
          return const _VideoFallback();
        }

        final size = _controller.value.size;

        return ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enablePlayback ? _togglePlayback : null,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFFD5E3FF));
  }
}
