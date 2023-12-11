import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voice_memo/API/whisper_api.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'dart:async';

late Record audioRecord;
late AudioPlayer audioPlayer;
bool isRecording = false;
bool isPlaying = false;
bool isLoading = false;
String audioPath = '';
String? transcript;
late Timer _timer;
late Stopwatch _stopwatch;
String? cleanedText;
String? summaryText;

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  _RecordPageState createState() => _RecordPageState();
}

// Initialize audio recording, playback, and timer
class _RecordPageState extends State<RecordPage> {
  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = Record();
    _stopwatch = Stopwatch();
  }
// Release resources when the state is disposed
  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    _stopwatch.stop();
    _timer.cancel();
    super.dispose();
  }
// Audio recording start
  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();
        setState(() {
          isRecording = true;
          isPlaying = false;
          audioPath = '';
          _stopwatch.reset();
          _stopwatch.start();
          // Start the timer to update the recording duration
          _timer = Timer.periodic(Duration(seconds: 1), (timer) {
            setState(() {});
          });
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }
// Audio recording stop
  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        isLoading = true; // Set loading in progress
        _stopwatch.stop();
        if (_timer.isActive) {
          _timer.cancel();
        }
      });
      // Create date and time format
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(DateTime.now());

      // Create file names with adding time stamp
      final fileNameOriginalText = 'recording_Original_$formattedDate.txt';
      final fileNameCleanedText = 'recording_Cleaned_$formattedDate.txt';
      final fileNameSummaryText = 'recording_Summary_$formattedDate.txt';
      final fileNameAudio = 'recording_Audio_$formattedDate';
      final fileNameTitle = 'recording_Title_$formattedDate';

      final title = 'Memo $formattedDate';

      print(path);

      var req = await requestWhisper(path!, null);
      var sum = await requestSummary(req);
      var clean = await requestClean(req);
      transcript = req;
      cleanedText = clean;
      summaryText = sum;

      // Do functions to save files
      await saveAudioToFile(path, fileNameAudio);
      await saveTextToFile(transcript!, fileNameOriginalText);
      await saveTextToFile(cleanedText!, fileNameCleanedText);
      await saveTextToFile(summaryText!, fileNameSummaryText);
      await saveTextToFile(title, fileNameTitle);

      if (!mounted) return;

      setState(() {
        isLoading = false; // Loading finished
      });

      // Show message after file is saved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Align(
            alignment: Alignment.center,
            child: Text(
              'File saved succesfully!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 16,
              ),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.only(
            bottom: 20.0,
          ), 
          behavior: SnackBarBehavior.floating, 
        ),
      );
      // await updateFileNames();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
      print("AUDIO PATH: $audioPath");
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
// Function to save audio
  Future<void> saveAudioToFile(String audioPath, String fileNameAudio) async {
    try {
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final destinationPath = '${appDocumentsDir.path}/$fileNameAudio';
      await File(audioPath).copy(destinationPath);
      print('Audio saved to: $destinationPath');
    } catch (e) {
      print('Error saving audio to file: $e');
    }
  }
// Function to save text file
  Future<void> saveTextToFile(String text, String fileNameOriginalText) async {
    try {
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final destinationPath = '${appDocumentsDir.path}/$fileNameOriginalText';

      final file = File(destinationPath);
      await file.writeAsString(text);

      print('Transcript saved to: $destinationPath');
    } catch (e) {
      print('Error saving transcript to file: $e');
    }
  }

  String _formattedTime(Duration duration) {
    return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (!isLoading)
            Container(
              alignment: Alignment.topCenter,
              height: MediaQuery.of(context).size.height * 0.22,
              child: Lottie.asset(
                'assets/img/lottie/hexSpinnerLogo.json',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          if (!isLoading)
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 30,
                    left: 0,
                    right: 0,
                    child: !isRecording
                        ? Text(
                            "Tap to start recording",
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          )
                        : SizedBox.shrink(),
                  ),
                  if (isRecording)
                    Positioned(
                      top: 30,
                      child: Text(
                        '${_formattedTime(_stopwatch.elapsed)}',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Positioned(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary,
                            blurRadius: 10.0,
                            spreadRadius: 0.0,
                          ),
                        ],
                      ),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100.0)),
                          minimumSize: const Size(170, 170),
                        ),
                        onPressed: isRecording ? stopRecording : startRecording,
                        child: Icon(
                          isRecording
                              ? Icons.stop
                              : Icons.keyboard_voice_outlined,
                          size: 70.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isLoading)
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    "Please wait a sec...\nI'm writing your memo",
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
