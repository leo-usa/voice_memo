import 'package:flutter/material.dart';
import 'opened_file_page.dart';

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
    name: 'Sales Presentation Meeting',
    date: '23.10.2023',
    folderName: 'Meeting notes',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Project Kickoff',
    date: '15.10.2023',
    folderName: 'Meeting notes',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Weekly Newsletter',
    date: '4.10.2023',
    folderName: 'Email drafts',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Design Inspiration',
    date: '4.10.2023',
    folderName: 'Ideas',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Creative Marketing Strategies',
    date: '1.10.2023',
    folderName: 'Ideas',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'New Product Ideas',
    date: '27.9.2023',
    folderName: 'Ideas',
    // originalText: 'Original text for',
    // cleanedText: 'Cleaned text for',
    // summaryText: 'Summary text for',
    // audio: 'Audio for'
  ),
  FileItem(
    name: 'Client Meeting Notes',
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

// Search functionality
class MySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, ""); // Asetetaan hakutulokseksi tyhjä merkkijono
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searchResults = filenames
        .where((file) => file.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (BuildContext context, int index) {
        FileItem fileItem = searchResults[index];
        return FileListTile(
          fileItem: fileItem,
          onTap: () {
            FileUtilities.openFile(context, fileItem);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? [] // Näytä tyhjä lista, jos hakukenttä on tyhjä
        : filenames
            .where(
                (file) => file.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (BuildContext context, int index) {
        FileItem fileItem = suggestionList[index];
        return ListTile(
          title: Text(fileItem.name),
          onTap: () {
            // Aseta valittu ehdotus hakukenttään
            query = fileItem.name;
            // Näytä tulokset valitun ehdotuksen perusteella
            showResults(context);
          },
        );
      },
    );
  }
}

// File management methods
class FileUtilities {
  static void openFile(BuildContext context, FileItem fileItem) {
    // Avaa tiedosto valitussa näkymässä
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OpenedFilePage(title: fileItem.name),
      ),
    );
  }
}

// File list element
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

// Main files page view
class FilesPage extends StatefulWidget {
  const FilesPage({Key? key}) : super(key: key);

  @override
  State<FilesPage> createState() => _FilesPageState();
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

    // Opens folder in new view
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
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Show search field
                showSearch(
                  context: context,
                  delegate: MySearchDelegate(), // Search functionality
                );
              },
            ),
          ],
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
          toolbarHeight: 60.0, // AppBar custom height
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
                    FileUtilities.openFile(context, fileItem);
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
    // Return list of files
    return filenames.where((file) => file.folderName == folderName).toList();
  }
}

// Folder view
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
                // Insert file rename functionality
              } else if (value == 'deleteFolder') {
                // Insert delete folder functionality
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
      body: Column(
        children: [
          const Divider(),
          Expanded(
            child: folderContent.isEmpty
                ? const Center(
                    child: Text('Folder is empty'),
                  )
                : ListView.builder(
                    itemCount: folderContent.length,
                    itemBuilder: (BuildContext context, int index) {
                      FileItem fileItem = folderContent[index];
                      bool isFileInFolder = fileItem.folderName == folderName;
                      return FileListTile(
                        fileItem: fileItem,
                        onTap: () {
                          if (isFileInFolder) {
                            FileUtilities.openFile(context, fileItem);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
