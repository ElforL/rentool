import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

class MediaViewScreen extends StatefulWidget {
  const MediaViewScreen({
    Key? key,
    this.imageProvider,
    this.videoController,
  }) : super(key: key);

  final ImageProvider<Object>? imageProvider;
  final VideoPlayerController? videoController;

  @override
  State<MediaViewScreen> createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> {
  ChewieController? chewieController;
  bool initiated = false;

  Future<void> _initVideo() async {
    if (initiated || widget.videoController!.value.isInitialized) return;
    await widget.videoController!.initialize();
    chewieController = ChewieController(
      videoPlayerController: widget.videoController!,
      autoPlay: true,
      looping: true,
      optionsTranslation: OptionsTranslation(
        cancelButtonText: AppLocalizations.of(context)!.cancel,
        playbackSpeedButtonText: AppLocalizations.of(context)!.playback_speed,
      ),
    );
    initiated = true;
  }

  @override
  void initState() {
    super.initState();
    if (widget.videoController != null) {
      _initVideo().then((value) => setState(() {}));
    }
  }

  @override
  void dispose() {
    widget.videoController?.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.videoController?.initialize();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    Widget body;
    if (widget.videoController != null) {
      body = (widget.videoController!.value.isInitialized)
          ? Chewie(
              controller: chewieController!,
            )
          : const CircularProgressIndicator();
    } else {
      body = PhotoView(
        imageProvider: widget.imageProvider,
      );
    }

    return Center(
      child: body,
    );
  }
}
