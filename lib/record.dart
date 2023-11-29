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

class _RecordPageState extends State<RecordPage> {
  
  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = Record();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    _stopwatch.stop();
    _timer.cancel();
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
          _stopwatch.reset();
    _stopwatch.start();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
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
      await saveAudioToFile(path, fileNameAudio);
      await saveTextToFile(transcript!, fileNameOriginalText);
      await saveTextToFile(cleanedText!, fileNameCleanedText);
      await saveTextToFile(summaryText!, fileNameSummaryText);
      await saveTextToFile(title, fileNameTitle);
      setState(() {
        isRecording = false;
        audioPath = path;
       _stopwatch.stop();
    _timer.cancel();
      });

      if (!mounted) return;

      // Tiedoston tallennuksen jälkeen näytä viesti
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
          ), // Työntää SnackBaria ylöspäin
          behavior: SnackBarBehavior.floating, // Tehdään SnackBarista kelluva
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
  String _formattedTime(Duration duration) {
    return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(
       
      //),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width,
            //widthFactor: 0.8, // Säädä tarpeen mukaan
            child:
            Lottie.asset(
              'assets/img/lottie/hexSpinnerLogo.json', // Polku Lottie-tiedostoon
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
            ),
           if(isRecording) Text(
              '${_formattedTime(_stopwatch.elapsed)}',
              style: TextStyle(fontSize: 40.0),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
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
                child: Icon(
                  isRecording ? Icons.stop : Icons.keyboard_voice_outlined,
                  size: 80.0,
                ),
              ),
              label: Text(''),
            ),
            const SizedBox(height: 25),
            if (audioPath.isNotEmpty)
              ElevatedButton(
                onPressed: isPlaying ? stopPlaying : playRecording,
                child: Text(isPlaying ? 'Stop' : 'Play'),
              ),
          ],
        ),
      ),
    );
  }
}
