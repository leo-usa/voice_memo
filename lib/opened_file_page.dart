import 'package:flutter/material.dart';
import 'dart:io';

class OpenedFilePage extends StatefulWidget {
  final String title;
  final String titlePath;
  final String originalText;
  final String originalTextPath;
  final String audioPath;
  final Function updateList;

  const OpenedFilePage(
      {Key? key,
      required this.title,
      required this.titlePath,
      required this.originalText,
      required this.originalTextPath,
      required this.audioPath,
      required this.updateList})
      : super(key: key);

  @override
  State<OpenedFilePage> createState() => _OpenedFilePageState();
}

class _OpenedFilePageState extends State<OpenedFilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, // Määrä vaihtoehtoja: Original, Cleaned, Summary, Audio
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> deleteFiles(BuildContext context, String titlePath,
      String originalTextPath, String audioPath, Function updateList) async {
    List<String> filePaths = [
      titlePath,
      originalTextPath,
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

  void showDeleteConfirmationDialog(BuildContext context, String titlePath,
      String originalTextPath, String audioPath, Function updateList) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Files'),
          content: Text('Are you sure you want to delete these files?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Sulje dialogi
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await deleteFiles(context, titlePath, originalTextPath,
                    audioPath, updateList); // Poista tiedostot
                widget.updateList();
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
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
                if (value == 'copy') {
                  // Tässä voit toteuttaa tiedoston kopioinnin
                } else if (value == 'share') {
                  // Tässä voit toteuttaa tiedoston jakamisen
                } else if (value == 'moveFile') {
                  // Tässä voit toteuttaa tiedoston siirron
                } else if (value == 'delete') {
                  showDeleteConfirmationDialog(
                      context,
                      widget.titlePath,
                      widget.originalTextPath,
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
                    value: 'copy',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.copy), // Kuvake tässä
                        SizedBox(
                            width: 8.0), // Pieni väli ikonin ja tekstin välillä
                        Text('Copy text'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.share), // Kuvake tässä
                        SizedBox(
                            width: 8.0), // Pieni väli ikonin ja tekstin välillä
                        Text('Share text'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'moveFile',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.drive_file_move_outline), // Kuvake tässä
                        SizedBox(
                            width: 8.0), // Pieni väli ikonin ja tekstin välillä
                        Text('Move file'),
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
                    'Cleaned content for ${widget.title}',
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
                    'Summary content for ${widget.title}',
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
          Center(child: Text('Audio content for ${widget.audioPath}')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Tiedoston muokkausnäkymän toiminnallisuuteen siirtyminen
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.edit),
      ),
    );
  }
}
