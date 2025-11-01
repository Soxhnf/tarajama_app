import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _videoFile;
  VideoPlayerController? _controller;
  bool _showControls = false; // controls visibility
  bool _isMuted = false; // mute state
  bool _isFullScreen = false; // fullscreen state
  double _playbackSpeed = 1.0; // playback speed
  bool _showSubtitles = false; // subtitle state

  final List<double> _playbackSpeeds = [0.5, 0.75, 1.0, 1.5, 1.75, 2.0];

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      _videoFile = file;
      _controller?.dispose();
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
        })
        ..addListener(() {
          setState(() {}); // Update time tracking
        });
      setState(() {
        _showControls = false;
        _isMuted = false; // Reset mute state when new video is loaded
        _playbackSpeed = 1.0; // Reset playback speed when new video is loaded
        _showSubtitles = false; // Reset subtitle state when new video is loaded
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  void togglePlayPause() {
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void toggleFullScreen() {
    if (_isFullScreen) {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _controller!.setPlaybackSpeed(speed);
    });
  }

  void toggleSubtitles() {
    setState(() {
      _showSubtitles = !_showSubtitles;
    });
    // Note: For actual subtitle functionality, you would need to implement
    // subtitle parsing and display logic here
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Playback Speed',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _playbackSpeeds.length,
            itemBuilder: (context, index) {
              final speed = _playbackSpeeds[index];
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: _playbackSpeed == speed ? Colors.red : Colors.white,
                    fontWeight: _playbackSpeed == speed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  changePlaybackSpeed(speed);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Reset orientation when widget is disposed
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(title: const Text('Video Uploader')),
      body: WillPopScope(
        onWillPop: () async {
          if (_isFullScreen) {
            toggleFullScreen();
            return false;
          }
          return true;
        },
        child: Center(
          child: _videoFile == null
              ? const Text('No video selected.')
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),

                      // --- Controls Overlay ---
                      if (_showControls)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black38,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Time tracking above progress bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_controller!.value.position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_controller!.value.duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Progress bar (seekable) - Height set to 8
                                SizedBox(
                                  height: 8,
                                  child: VideoProgressIndicator(
                                    _controller!,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.red,
                                      backgroundColor: Colors.white30,
                                      bufferedColor: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Play/Pause button, Mute button, Playback Speed, Subtitles, and Fullscreen button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left side buttons
                                    Row(
                                      children: [
                                        // Play/Pause button
                                        ElevatedButton(
                                          onPressed: togglePlayPause,
                                          style: ElevatedButton.styleFrom(
                                            shape: const CircleBorder(),
                                            padding: const EdgeInsets.all(8),
                                            backgroundColor: Colors.black54,
                                            minimumSize: Size.zero,
                                          ),
                                          child: Icon(
                                            _controller!.value.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Mute button
                                        ElevatedButton(
                                          onPressed: toggleMute,
                                          style: ElevatedButton.styleFrom(
                                            shape: const CircleBorder(),
                                            padding: const EdgeInsets.all(8),
                                            backgroundColor: Colors.black54,
                                            minimumSize: Size.zero,
                                          ),
                                          child: Icon(
                                            _isMuted ? Icons.volume_off : Icons.volume_up,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Right side buttons - Playback Speed, Subtitles, and Fullscreen
                                    Row(
                                      children: [
                                        // Playback Speed button
                                        ElevatedButton(
                                          onPressed: _showPlaybackSpeedDialog,
                                          style: ElevatedButton.styleFrom(
                                            shape: const CircleBorder(),
                                            padding: const EdgeInsets.all(8),
                                            backgroundColor: Colors.black54,
                                            minimumSize: Size.zero,
                                          ),
                                          child: Text(
                                            '${_playbackSpeed}x',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Subtitle button
                                        ElevatedButton(
                                          onPressed: toggleSubtitles,
                                          style: ElevatedButton.styleFrom(
                                            shape: const CircleBorder(),
                                            padding: const EdgeInsets.all(8),
                                            backgroundColor: _showSubtitles ? Colors.red : Colors.black54,
                                            minimumSize: Size.zero,
                                          ),
                                          child: Icon(
                                            Icons.subtitles,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Fullscreen button
                                        ElevatedButton(
                                          onPressed: toggleFullScreen,
                                          style: ElevatedButton.styleFrom(
                                            shape: const CircleBorder(),
                                            padding: const EdgeInsets.all(8),
                                            backgroundColor: Colors.black54,
                                            minimumSize: Size.zero,
                                          ),
                                          child: Icon(
                                            _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: _isFullScreen ? null : FloatingActionButton(
        onPressed: pickVideo,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}