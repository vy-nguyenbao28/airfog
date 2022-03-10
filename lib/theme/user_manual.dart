import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class UserManual extends StatefulWidget {
  final String youtubeURL;
  UserManual(this.youtubeURL);
  @override
  _UserManual createState() => _UserManual();
}

class _UserManual extends State<UserManual> {
  late YoutubePlayerController _youtubeController;
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController(
      initialVideoId: YoutubePlayerController.convertUrlToId(widget.youtubeURL)!,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        desktopMode: true,
        privacyEnhanced: true,
        useHybridComposition: true,
      ),
    );
    _youtubeController.onEnterFullscreen = () {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      log('Entered Fullscreen');
    };
    _youtubeController.onExitFullscreen = () {
      log('Exited Fullscreen');
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return SizedBox(
      height: kIsWeb ? screenSize.height / 1.13 : screenSize.height,
      width: screenSize.width,
      child: YoutubePlayerControllerProvider(
        controller: _youtubeController,
        child: YoutubePlayerIFrame(
          controller: _youtubeController,
        ),
      ),
    );
  }

}