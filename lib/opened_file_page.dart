import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

// ignore: must_be_immutable
class OpenedFilePage extends StatefulWidget {
  String title;
  final String titlePath;
  final String originalText;
  final String originalTextPath;
  String cleanedText;
  final String cleanedTextPath;
  final String summaryText;
  final String summaryTextPath;
  final String audioPath;
  final Function updateList;

// Constructor for OpenedFilePage
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
  late Widget cleanedText; // Change this to Widget type

  @override
  void initState() {
    super.initState();
    // Initialize TabController and AudioPlayer
    _tabController = TabController(
      length: 4, // Number of options: Original, Cleaned, Summary, Audio
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
    // Dispose of resources when the state is disposed
    _tabController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }
// Function to add paragraph breaks and format titles in bold
  RichText addParagraphBreaksAndBoldTitles(String text, BuildContext context) {
    List<TextSpan> spans = [];

    // Find titles, list items, and other text
    var regex = RegExp(r'##\s*(.*?)\r?\n|\*\s*(.*?)\r?\n|([^#\*]+)');
    var matches = regex.allMatches(text);

    // Get theme data from context
    var theme = Theme.of(context);
    var defaultTextStyle = theme.textTheme.bodyLarge; // Change if needed
    var headerTextStyle = theme.textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.bold); // Style for titles
    var listItemStyle = theme.textTheme.bodyLarge; // Style for list items

    for (var match in matches) {
      if (match.group(1) != null) {
        // Add bold title
        spans.add(TextSpan(
          text: match.group(1)!.trim() + '\n',
          style: headerTextStyle,
        ));
      } else if (match.group(2) != null) {
        // Add list item
        spans.add(TextSpan(
          text: "• " + match.group(2)!.trim() + '\n',
          style: listItemStyle,
        ));
      } else if (match.group(3) != null) {
        // Add normal text
        spans.add(TextSpan(
          text: match.group(3)!.replaceAll("||", "\n"),
          style: defaultTextStyle,
        ));
      }
    }

    // Return RichText containing all TextSpan objects
    return RichText(
      text: TextSpan(
        children: spans,
        style: defaultTextStyle,
      ),
    );
  }

// Function to toggle audio playback
  void toggleAudio() async {
    try {
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        final file = File(widget.audioPath);
        if (await file.exists()) {
          await audioPlayer.setSourceDeviceFile(widget.audioPath);
          await audioPlayer.resume();
        } else {
          throw Exception('Audio file not found');
        }
      }
      setState(() {
        isPlaying = !isPlaying;
      });
      
      // Listen for playback completion
      audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          isPlaying = false;
        });
      });
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

// Function to format duration as a string
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }
// Function to delete files
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
        // File deleted successfully
        print('File deleted successfully: $filePath');
      } catch (error) {
        // Error deleting file
        print('Error deleting file $filePath: $error');
      }
    }
    await updateList();
    Navigator.of(context).pop();
  }

// Function to rewrite file contents
  Future<void> rewriteFileContents(String filePath, String newContents) async {
    File file = File(filePath);
    await file.writeAsString(newContents);
  }

// Function to show delete confirmation dialog
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

// Function to show rename dialog
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
    Widget formattedCleanedText =
        addParagraphBreaksAndBoldTitles(widget.cleanedText, context);
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
          // Content for each option
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.originalText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          fontSize: 16.0,
                        ),
                  ),
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
                  formattedCleanedText, 
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
                    widget.summaryText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
