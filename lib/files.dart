import 'package:flutter/material.dart';
import 'opened_file_page.dart'; // Tuo OpenedFilePage

class FileItem {
  final String name;
  final String date;
  final String folderName;
  // final String originalText;
  // final String cleanedText;
  // final String summaryText;
  // final String audio;

  FileItem({
    required this.name,
    required this.date,
    required this.folderName,
    // required this.originalText,
    // required this.cleanedText,
    // required this.summaryText,
    // required this.audio,
  });
}

final List<FileItem> filenames = <FileItem>[
  FileItem(
    name: 'Memo 1',
    date: '23.10.2023',
    folderName: 'Meeting notes',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Memo 2',
    date: '15.10.2023',
    folderName: 'Meeting notes',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Memo 3',
    date: '4.10.2023',
    folderName: 'Email drafts',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Memo 4',
    date: '4.10.2023',
    folderName: 'Ideas',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Memo 5',
    date: '1.10.2023',
    folderName: 'Ideas',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Memo 6',
    date: '27.9.2023',
    folderName: 'Ideas',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Memo 7',
    date: '25.9.2023',
    folderName: 'Meeting notes',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
];

final List<String> foldernames = <String>[
  'Meeting notes',
  'Email drafts',
  'Ideas',
];

class FilesPage extends StatefulWidget {
  const FilesPage({Key? key}) : super(key: key);

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class FileUtils {
  static void openFile(BuildContext context, FileItem fileItem) {
    // Avaa tiedosto valitussa näkymässä
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OpenedFilePage(title: fileItem.name),
      ),
    );
  }
}

class FileListTile extends StatelessWidget {
  final FileItem fileItem;
  final void Function() onTap;

  const FileListTile({
    Key? key,
    required this.fileItem,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(fileItem.name),
          subtitle: Text(fileItem.date),
          trailing: const Icon(Icons.arrow_forward),
          onTap: onTap,
        ),
        const Divider(),
      ],
    );
  }
}

class _FilesPageState extends State<FilesPage> {
  bool isFoldersTabSelected = false;
  String selectedFolder = '';
  List<FileItem> selectedFolderContent = [];

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
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newFolderName.isNotEmpty) {
                  setState(() {
                    foldernames.add(newFolderName);
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openFolder(String folderName) {
    setState(() {
      selectedFolder = folderName;
      isFoldersTabSelected = true;
      selectedFolderContent = getFolderContent(folderName);
    });

    // Avaa kansion sisällön uudessa näkymässä
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FolderViewPage(
          folderName: folderName,
          folderContent: selectedFolderContent,
        ),
      ),
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
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                text: 'All',
              ),
              Tab(
                text: 'Folders',
              ),
            ],
            onTap: (index) {
              setState(() {
                isFoldersTabSelected = index == 1;
              });
            },
          ),
          toolbarHeight: 60.0, // AppBarin korkeus
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              itemCount: filenames.length,
              itemBuilder: (BuildContext context, int index) {
                FileItem fileItem = filenames[index];
                return FileListTile(
                  fileItem: fileItem,
                  onTap: () {
                    FileUtils.openFile(context, fileItem);
                  },
                );
              },
            ),
            // Folders Tab
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
                      onTap: () {
                        _openFolder(folderName);
                      },
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ],
        ),
        floatingActionButton: isFoldersTabSelected
            ? FloatingActionButton(
                onPressed: () {
                  _showCreateFolderDialog(context);
                },
                shape: const CircleBorder(),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  List<FileItem> getFolderContent(String folderName) {
    // Palauta luettelo tiedostoista
    return filenames.where((file) => file.folderName == folderName).toList();
  }
}

class FolderViewPage extends StatelessWidget {
  final String folderName;
  final List<FileItem> folderContent;

  FolderViewPage({
    required this.folderName,
    required this.folderContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(folderName),
          actions: [
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'renameFolder') {
                  // Tässä voit toteuttaa kansion nimen muokkaamisen
                } else if (value == 'deleteFolder') {
                  // Tässä voit toteuttaa kansion poistamisen
                }
              },
              icon: const Icon(Icons.more_vert),
              offset: const Offset(0, kToolbarHeight),
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(
                    value: 'renameFolder',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.edit),
                        SizedBox(
                          width: 8.0,
                        ),
                        Text('Rename folder'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'deleteFolder',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.delete_outlined),
                        SizedBox(
                          width: 8.0,
                        ),
                        Text('Delete folder'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
          toolbarHeight: 60.0, // AppBarin korkeus tähän
        ),
        body: folderContent.isEmpty
            ? const Center(
                child: Text('Folder is empty'),
              )
            : ListView.builder(
                itemCount: folderContent.length,
                itemBuilder: (BuildContext context, int index) {
                  FileItem fileItem = folderContent[index];
                  bool isFileInFolder = fileItem.folderName ==
                      folderName; // Check if the file belongs to opened folder
                  return FileListTile(
                    fileItem: fileItem,
                    onTap: () {
                      if (isFileInFolder) {
                        FileUtils.openFile(context, fileItem);
                      }
                    },
                  );
                },
              ));
  }
}
