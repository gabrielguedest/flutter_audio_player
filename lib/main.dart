import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

const imageUrl = 'https://persono-app.s3.amazonaws.com/images/relaxing-audio-02.png';

void main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.audio',
    androidNotificationChannelName: 'Aúdio playback',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageManager _pageManager = PageManager();

  @override
  void dispose() {
    _pageManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  imageUrl,
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0, top: 32.0),
                child: Text(
                  'Aúdio para dormir',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              ValueListenableBuilder<ProgressBarState>(
                valueListenable: _pageManager.progressNotifier, 
                builder: (_, value, __) {
                  return ProgressBar(
                    onSeek: _pageManager.seek,
                    progress: value.current,
                    buffered: value.buffered,
                    total: value.total,
                    progressBarColor: const Color(0xFF009dff),
                    thumbRadius: 7,
                    baseBarColor: const Color(0xFFcdcbcc),
                    bufferedBarColor: Colors.black.withOpacity(0.2),
                    timeLabelPadding: 10,
                    timeLabelTextStyle: const TextStyle(
                      color: Color(0xFFcdcbcc),
                    ),
                    thumbGlowColor: Colors.black.withOpacity(0.5),
                    thumbGlowRadius: 7,
                  );
                }
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoButton(
                    onPressed: () => _pageManager.advanceSeconds(10),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: const Icon(
                        Icons.refresh,
                        size: 28,
                        color: Color(0xFF009dff),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<ButtonState>(
                    valueListenable: _pageManager.buttonNotifier,
                    builder: (_, state, __) {

                      if (state == ButtonState.loading) {
                        return CupertinoButton(
                          onPressed: null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF009dff),
                              borderRadius: BorderRadius.circular(60)
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }

                      final icon = {
                        ButtonState.finished: Icons.restart_alt,
                        ButtonState.playing: Icons.pause,
                        ButtonState.paused: Icons.play_arrow, 
                      };

                      final action = {
                        ButtonState.finished: _pageManager.play,
                        ButtonState.playing: _pageManager.pause,
                        ButtonState.paused: _pageManager.play, 
                      };

                      return CupertinoButton(
                        onPressed: action[state],
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF009dff),
                            borderRadius: BorderRadius.circular(60)
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            icon[state]!,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  CupertinoButton(
                    onPressed: () => _pageManager.advanceSeconds(10),
                    child: const Icon(
                      Icons.refresh,
                      size: 28,
                      color: Color(0xFF009dff),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
            ]
          )
        ),
      ),
    );
  }
}


class PageManager {
  static const url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3';
  late AudioPlayer _audioPlayer;

  PageManager() {
    _init();
  }

  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);

  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );

  void dispose() {
    _audioPlayer.dispose();
  }

  void _init() async {
    _audioPlayer = AudioPlayer();

    final audioSource = LockCachingAudioSource(
      Uri.parse(url),
      tag: MediaItem(
        id: '1',
        album: 'Audios relaxantes',
        title: 'Audio para dormir',
        artUri: Uri.parse(imageUrl),
      ),
    );
    await _audioPlayer.setAudioSource(audioSource);

    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        buttonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        if (_audioPlayer.duration != null && _audioPlayer.position == _audioPlayer.duration) {
          buttonNotifier.value = ButtonState.finished;
        } else {
          buttonNotifier.value = ButtonState.paused;
        }
      } else if (processingState != ProcessingState.completed) {
        buttonNotifier.value = ButtonState.playing;
      } else { // completed
        buttonNotifier.value = ButtonState.finished;
        _audioPlayer.pause();
      }
    });

    _audioPlayer.positionStream.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });

    _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: bufferedPosition,
        total: oldState.total,
      );
    });

    _audioPlayer.durationStream.listen((totalDuration) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: totalDuration ?? Duration.zero,
      );
    });
  }

  void advanceSeconds(int seconds) {
    var seekPosition = _audioPlayer.position + Duration(seconds: seconds);

    if (seekPosition > (_audioPlayer.duration ?? Duration.zero)) {
      seekPosition = _audioPlayer.duration ?? Duration.zero;
    }

    _audioPlayer.seek(seekPosition);
  }

  void returnSeconds(int seconds) {
    var seekPosition = _audioPlayer.position - Duration(seconds: seconds);

    if (seekPosition < Duration.zero) {
      seekPosition = Duration.zero;
    }

    _audioPlayer.seek(seekPosition);
  }

  void play() {
    if (_audioPlayer.position == _audioPlayer.duration) {
      _audioPlayer.seek(Duration.zero);
    }

    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }
  
}

class ProgressBarState {
  final Duration current;
  final Duration buffered;
  final Duration total;

  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });
}

enum ButtonState {
  paused, playing, loading, finished
}