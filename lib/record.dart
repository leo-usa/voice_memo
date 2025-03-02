import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voice_memo/API/whisper_api.dart';
import 'package:voice_memo/API/api_key.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'services/directory_service.dart';

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
    
    // Configure audio player
    audioPlayer.setReleaseMode(ReleaseMode.stop);
    
    // Set up audio player listeners
    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      print("Player state changed: $state");
    });
    
    audioPlayer.onDurationChanged.listen((Duration d) {
      print("Duration changed: $d");
    });
    
    audioPlayer.onPositionChanged.listen((Duration p) {
      print("Position changed: $p");
    });
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
        // Get the documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Create proper file paths
        audioPath = '${appDocDir.path}/temp_recording_$timestamp.m4a';
        
        // Create a proper file URL for macOS using file:// format
        final fileUrl = 'file://${Uri.file(audioPath).toFilePath(windows: false)}';
        print('Starting recording to: $fileUrl'); // Debug log
        
        // Start recording with specified path
        await audioRecord.start(
          path: fileUrl,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        
        setState(() {
          isRecording = true;
          isPlaying = false;
          _stopwatch.reset();
          _stopwatch.start();
          _timer = Timer.periodic(Duration(seconds: 1), (timer) {
            setState(() {});
          });
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
// Audio recording stop
  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      print('Recording stopped, path: $path'); // Debug log
      
      // Verify file exists and has content
      if (path != null) {
        // Convert URL back to file path if needed
        String filePath = Uri.parse(path).toFilePath();
        print('Using file path: $filePath'); // Debug log
        
        File recordingFile = File(filePath);
        if (await recordingFile.exists()) {
          int fileSize = await recordingFile.length();
          print('Recording file size: $fileSize bytes'); // Debug log
          
          if (fileSize > 0) {
            setState(() {
              isRecording = false;
              isLoading = true;
              _stopwatch.stop();
              if (_timer.isActive) {
                _timer.cancel();
              }
            });

            // Check if API key is configured
            if (apiKey.isEmpty || apiKey == 'your-openai-api-key') {
              print('Error: OpenAI API key not configured');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please configure your OpenAI API key'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            // Calculate recording length in minutes
            int lengthInSeconds = _stopwatch.elapsed.inSeconds;
            int lengthInMinutes = (lengthInSeconds / 60).ceil();
            
            // Create date and time format
            final formatter = DateFormat('yyyyMMdd_HHmmss');
            final formattedDate = formatter.format(DateTime.now());
            
            // Split date and time
            final datePart = formattedDate.substring(0, 8);
            final timePart = formattedDate.substring(9);

            // Create file names with new format
            final fileNameOriginalText = '${datePart}_${timePart}_${lengthInMinutes}min_original.txt';
            final fileNameCleanedText = '${datePart}_${timePart}_${lengthInMinutes}min_cleaned.txt';
            final fileNameSummaryText = '${datePart}_${timePart}_${lengthInMinutes}min_summary.txt';
            final fileNameAudio = '${datePart}_${timePart}_${lengthInMinutes}min_audio.m4a';
            final fileNameTitle = '${datePart}_${timePart}_${lengthInMinutes}min_title';

            final title = 'Memo ${formattedDate} (${lengthInMinutes}min)';
            
            try {
              var req = await requestWhisper(filePath, null);
              print('Whisper response: $req'); // Debug log
              
              var sum = await requestSummary(req);
              print('Summary response: $sum'); // Debug log
              
              var clean = await requestClean(req);
              print('Clean response: $clean'); // Debug log
              
              transcript = req;
              cleanedText = clean;
              summaryText = sum;

              // Do functions to save files
              await saveAudioToFile(filePath, fileNameAudio);
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
                      'File saved successfully!',
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
            } catch (e) {
              print('API error: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error processing recording: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            print('Recording file is empty');
          }
        } else {
          print('Recording file does not exist');
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playRecording() async {
    try {
      // Create proper file URL for playback
      final file = File(audioPath);
      if (await file.exists()) {
        final fileUrl = 'file://${Uri.file(audioPath).toFilePath(windows: false)}';
        print("Playing audio from: $fileUrl");
        
        // Set up audio player
        await audioPlayer.setSourceDeviceFile(audioPath);  // Use setSourceDeviceFile instead of setSourceUrl
        await audioPlayer.resume();
        
        setState(() {
          isPlaying = true;
        });
        
        // Listen for playback completion
        audioPlayer.onPlayerComplete.listen((event) {
          setState(() {
            isPlaying = false;
          });
        });
      } else {
        throw Exception('Audio file not found');
      }
    } catch (e) {
      print('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> stopPlaying() async {
    try {
      await audioPlayer.pause();
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
      final directory = await DirectoryService.getSaveDirectory();
      final destinationPath = '$directory/$fileNameAudio';
      
      // Verify source file exists
      final sourceFile = File(audioPath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        print('Audio saved to: $destinationPath');
        
        // Verify the copy worked
        final destFile = File(destinationPath);
        if (await destFile.exists()) {
          final sourceSize = await sourceFile.length();
          final destSize = await destFile.length();
          print('Verified saved file: source size = $sourceSize bytes, destination size = $destSize bytes');
          
          // Delete the temporary file after successful copy
          await sourceFile.delete();
          print('Deleted temporary file: $audioPath');
        }
      } else {
        print('Source audio file does not exist: $audioPath');
        throw Exception('Source audio file not found');
      }
    } catch (e) {
      print('Error saving audio to file: $e');
      throw e;
    }
  }
// Function to save text file
  Future<void> saveTextToFile(String text, String fileName) async {
    try {
      final directory = await DirectoryService.getSaveDirectory();
      final destinationPath = '$directory/$fileName';

      final file = File(destinationPath);
      await file.writeAsString(text);

      print('Text saved to: $destinationPath');
    } catch (e) {
      print('Error saving text to file: $e');
      throw e;
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
