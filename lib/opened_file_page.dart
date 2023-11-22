import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

// ignore: must_be_immutable
class OpenedFilePage extends StatefulWidget {
  String title;
  final String titlePath;
  final String originalText;
  final String originalTextPath;
  final String cleanedText;
  final String cleanedTextPath;
  final String summaryText;
  final String summaryTextPath;
  final String audioPath;
  final Function updateList;

  OpenedFilePage(
      {Key? key,
      required this.title,
      required this.titlePath,
      required this.originalText,
      required this.originalTextPath,
      required this.cleanedText,
      required this.cleanedTextPath,
      required this.summaryText,
      required this.summaryTextPath,
      required this.audioPath,
      required this.updateList})
      : super(key: key);

  @override
  State<OpenedFilePage> createState() => _OpenedFilePageState();
}

class _OpenedFilePageState extends State<OpenedFilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration totalDuration = Duration();
  Duration currentPosition = Duration();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, // Määrä vaihtoehtoja: Original, Cleaned, Summary, Audio
      vsync: this,
    );
    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => totalDuration = d);
    });
    audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() => currentPosition = p);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  void toggleAudio() async {
    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play(UrlSource(widget.audioPath));
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> deleteFiles(
      BuildContext context,
      String titlePath,
      String originalTextPath,
      String cleanedTextPath,
      String summaryTextPath,
      String audioPath,
      Function updateList) async {
    List<String> filePaths = [
      titlePath,
      originalTextPath,
      cleanedTextPath,
      summaryTextPath,
      audioPath,
    ];

    for (String filePath in filePaths) {
      try {
        await File(filePath).delete();
        // Tiedosto poistettiin onnistuneesti
        print('File deleted successfully: $filePath');
      } catch (error) {
        // Virhe tiedoston poistamisessa
        print('Error deleting file $filePath: $error');
      }
    }
    await updateList();
    Navigator.of(context).pop();
  }

  Future<void> rewriteFileContents(String filePath, String newContents) async {
    File file = File(filePath);
    await file.writeAsString(newContents);
  }

  void showDeleteConfirmationDialog(
      BuildContext context,
      String titlePath,
      String originalTextPath,
      String cleanedTextPath,
      String summaryTextPath,
      String audioPath,
      Function updateList) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete File'),
          content: Text('Are you sure you want to delete this file?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Sulje dialogi
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await deleteFiles(
                    context,
                    titlePath,
                    originalTextPath,
                    cleanedTextPath,
                    summaryTextPath,
                    audioPath,
                    updateList); // Poista tiedostot
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void showRenameDialog(
      BuildContext context, OpenedFilePage widget, String titlePath) {
    TextEditingController textEditingController =
        TextEditingController(text: widget.title);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename File'),
          content: TextField(
            controller: textEditingController,
            decoration: InputDecoration(hintText: 'Enter new file name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String newName = textEditingController.text;
                if (newName.isNotEmpty) {
                  await rewriteFileContents(titlePath, newName);
                  widget.title = newName;
                  await widget.updateList();
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120.0),
        child: AppBar(
          title: Text(widget.title),
          actions: [
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'renameFile') {
                  showRenameDialog(context, widget, widget.titlePath);
                } else if (value == 'delete') {
                  showDeleteConfirmationDialog(
                      context,
                      widget.titlePath,
                      widget.originalTextPath,
                      widget.cleanedTextPath,
                      widget.summaryTextPath,
                      widget.audioPath,
                      widget.updateList);
                }
              },
              icon: const Icon(Icons.more_vert),
              offset: const Offset(
                  0, kToolbarHeight), // Muuta offsetin arvoa tarpeidesi mukaan
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(
                    value: 'renameFile',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.edit_outlined), // Kuvake tässä
                        SizedBox(
                            width: 8.0), // Pieni väli ikonin ja tekstin välillä
                        Text('Rename file'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.delete_outlined),
                        SizedBox(
                            width: 8.0), // Pieni väli ikonin ja tekstin välillä
                        Text('Delete file'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Original'),
              Tab(text: 'Cleaned'),
              Tab(text: 'Summary'),
              Tab(text: 'Audio'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Lisää tänne kunkin vaihtoehdon sisältö
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.originalText}',
                    style: const TextStyle(
                      height: 1.5,
                      fontSize: 16.0,
                    ),
                  ),
                  // Muuta sisältöä tarpeidesi mukaan...
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.cleanedText}',
                    style: const TextStyle(
                      height: 1.5,
                      fontSize: 16.0,
                    ),
                  ),
                  // Muuta sisältöä tarpeidesi mukaan...
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.summaryText}',
                    style: const TextStyle(
                      height: 1.5,
                      fontSize: 16.0,
                    ),
                  ),
                  // Muuta sisältöä tarpeidesi mukaan...
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Asettaa Columnin kokoa sen sisällön mukaan
              children: [
                const Text(
                  'Listen the original audio of',
                  style: TextStyle(
                    height: 1.5,
                    fontSize: 14.0,
                  ),
                ),
                Text(
                  '${widget.title}',
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 20.0), // Lisää vertikaalista paddingia
                ),
                Material(
                  elevation: 5.0, // Varjostus
                  shape: CircleBorder(), // Pyöreä muoto
                  color: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary, // Kuvakkeen väri
                    ),
                    iconSize: 40.0, // Kuvakkeen koko
                    onPressed: toggleAudio,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 5.0), // Lisää vertikaalista paddingia
                ),
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Theme.of(context)
                            .colorScheme
                            .primary, // aktiivisen radan väri
                        inactiveTrackColor: Theme.of(context)
                            .colorScheme
                            .onBackground, // inaktiivisen radan väri
                        thumbColor: Theme.of(context)
                            .colorScheme
                            .primary, // liukurin väri
                        overlayColor: Colors.cyan.withAlpha(
                            32), // liukurin ympärillä näkyvän efektin väri
                        trackHeight: 4.0, // radan korkeus
                      ),
                      child: Slider(
                        value: currentPosition.inSeconds.toDouble(),
                        max: totalDuration.inSeconds.toDouble(),
                        onChanged: (value) {
                          audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 25.0), // Säädä tätä arvoa tarpeen mukaan
                          child: Text(
                            _formatDuration(currentPosition),
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 25.0), // Säädä tätä arvoa tarpeen mukaan
                          child: Text(
                            _formatDuration(totalDuration),
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Tiedoston muokkausnäkymän toiminnallisuuteen siirtyminen
      //   },
      //   shape: const CircleBorder(),
      //   child: const Icon(Icons.edit),
      // ),
    );
  }
}
