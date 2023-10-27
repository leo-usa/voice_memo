import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voice_memo/API/whisper_api.dart';

late Record audioRecord;
late AudioPlayer audioPlayer;
bool isRecording = false;
bool isPlaying = false;
String audioPath = '';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = Record();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();
        setState(() {
          isRecording = true;
          isPlaying = false;
          audioPath = '';
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      var file = File(path!);
      print(file);
      var req = requestWhisper(file);
      print(req);
      setState(() {
        isRecording = false;
        audioPath = path!;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
    } catch (e) {
      print('Error playing audio : $e');
    }
  }

  Future<void> stopPlaying() async {
    try {
      await audioPlayer.stop();
      setState(() {
        isPlaying = false;
      });
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: Text(isRecording ? 'Stop' : 'Record'),
            ),
            SizedBox(height: 25),
            if (audioPath.isNotEmpty)
              ElevatedButton(
                onPressed: isPlaying ? stopPlaying : playRecording,
                child: Text(isPlaying ? 'Stop Playback' : 'Play'),
              ),
          ],
        ),
      ),
    );
  }
}
