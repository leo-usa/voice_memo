import 'package:flutter/material.dart';

final List<String> filenames = <String>[
  'Memo 1',
  'Memo 2',
  'Memo 3',
  'Memo 4',
  'Memo 5',
  'Memo 6',
  'Memo 7',
];
final List<String> foldernames = <String>[
  'Meeting notes',
  'Email drafts',
  'Ideas',
];

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  void _showCreateFolderDialog(BuildContext context) {
    String newFolderName = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create a New Folder'),
          content: TextField(
            onChanged: (value) {
              newFolderName = value;
            },
            decoration: const InputDecoration(labelText: 'Folder Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog on cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newFolderName.isNotEmpty) {
                  setState(() {
                    foldernames
                        .add(newFolderName); // Add the folder name to the list
                  });
                }
                Navigator.of(context).pop(); // Close the dialog on save
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Files'),
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                text: 'All',
              ),
              Tab(
                text: 'Folders',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filenames.length,
              itemBuilder: (BuildContext context, int index) {
                String fileName = filenames[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(fileName),
                      subtitle: const Text('1.10.2023'),
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
            ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: foldernames.length,
              itemBuilder: (BuildContext context, int index) {
                String folderName = foldernames[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(folderName),
                      leading: const Icon(Icons.folder_outlined),
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showCreateFolderDialog(
                context); // Open the dialog to create a folder
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
