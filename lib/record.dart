import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voice_memo/API/whisper_api.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

late Record audioRecord;
late AudioPlayer audioPlayer;
bool isRecording = false;
bool isPlaying = false;
String audioPath = '';
String? transcript;

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
     // Luo päivämäärä- ja aikaformaatti
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(DateTime.now());

    // Luo tiedostonimi yhdistämällä annettu nimi, päivämäärä ja aika
    final fileNameOriginalText = 'recording_Original_$formattedDate.txt';
    final fileNameAudio = 'recording_Audio_$formattedDate';
    
    
    print(path);
    
      var req = await requestWhisper(path!, null);
      transcript = req;
      await saveAudioToFile(path!, fileNameAudio);
      await saveTextToFile(transcript!, fileNameOriginalText);
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
           Lottie.asset(
          'assets/img/lottie/hexSpinner.json', // Polku Lottie-tiedostoon
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shadowColor: Colors.blueAccent,
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.0)),
                minimumSize: const Size(170, 170), //////// HERE
              ),
              onPressed: isRecording ? stopRecording : startRecording,
              icon: Align(
                alignment: Alignment.center,
                child: Icon(isRecording ? Icons.stop : Icons.keyboard_voice_outlined, 
                size: 80.0,),
                ),
              label: Text(''),
            ),
            const SizedBox(height: 25),
            if (audioPath.isNotEmpty)
              ElevatedButton(
                onPressed: isPlaying ? stopPlaying : playRecording,
                child: Text(isPlaying ? 'Stop' : 'Play'),
              ),
if (transcript != null) Text("$transcript"),
          ],
        ),
      ),
    );
  }
}
