import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/src/source.dart' as audio;

class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;

  const AudioMessageWidget({Key? key, required this.audioUrl})
      : super(key: key);

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration currentPos = Duration.zero;
  Duration maxDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializePlayer();
  }

  void _initializePlayer() async {
    print(widget.audioUrl);
    audio.Source urlSource = UrlSource(widget.audioUrl);
    await _audioPlayer.setSource(urlSource).timeout(const Duration(hours: 1));
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed) {
        setState(() {
          isPlaying = false;
          currentPos = Duration.zero;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        maxDuration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        currentPos = p;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          Slider(
            activeColor: Colors.white,
            value: currentPos.inSeconds.toDouble(),
            min: 0,
            max: maxDuration.inSeconds.toDouble(),
            onChanged: (value) {
              setState(() {
                currentPos = Duration(seconds: value.toInt());
              });
            },
            onChangeEnd: (value) {
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    audio.Source urlSource = UrlSource(widget.audioUrl);
                    _audioPlayer.play(urlSource);
                  }
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
              ),
              Text(
                "${currentPos.inMinutes}:${(currentPos.inSeconds % 60).toString().padLeft(2, '0')} / ${maxDuration.inMinutes}:${(maxDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
