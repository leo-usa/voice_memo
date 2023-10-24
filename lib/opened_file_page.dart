import 'package:flutter/material.dart';

class OpenedFilePage extends StatefulWidget {
  final String title;

  const OpenedFilePage({Key? key, required this.title}) : super(key: key);

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
                  // Tässä voit toteuttaa tiedoston poiston
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
          Center(child: Text('Original content for ${widget.title}')),
          Center(child: Text('Cleaned content for ${widget.title}')),
          Center(child: Text('Summary content for ${widget.title}')),
          Center(child: Text('Audio content for ${widget.title}')),
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
