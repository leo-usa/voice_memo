import 'package:flutter/material.dart';
import 'opened_file_page.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'services/directory_service.dart';

class FileItem {
  final String name;
  final String titlePath;
  final String date;
  final String folderName;
  final String originalText;
  final String originalTextPath;
  final String cleanedText;
  final String cleanedTextPath;
  final String summaryText;
  final String summaryTextPath;
  final String audioPath;

  FileItem({
    required this.name,
    required this.titlePath,
    required this.date,
    required this.folderName,
    required this.originalText,
    required this.originalTextPath,
    required this.cleanedText,
    required this.cleanedTextPath,
    required this.summaryText,
    required this.summaryTextPath,
    required this.audioPath,
  });
}

final List<FileItem> filenames = <FileItem>[];

Future<void> updateFileNames() async {
  final directory = await DirectoryService.getSaveDirectory();

  filenames.clear();

  Map<String, Map<String, String>> timestampToData = {};

  final dir = Directory(directory);
  await for (var entity in dir.list(recursive: true, followLinks: false)) {
    var path = entity.path;

    List<String> pathParts = path.split('/');
    String filename = pathParts.last;

    // Parse filename parts (date_time_lengthmin_type.*)
    List<String> filenameParts = filename.split('_');
    if (filenameParts.length < 4) continue; // Skip if filename doesn't match expected format

    String datePart = filenameParts[0];
    String timePart = filenameParts[1];
    String lengthPart = filenameParts[2];
    String typePart = filenameParts[3].split('.')[0]; // Remove extension

    String timestamp = '${datePart}_$timePart';

    if (!timestampToData.containsKey(timestamp)) {
      timestampToData[timestamp] = {};
    }

    bool isAudio = typePart == 'audio';
    bool isOriginalText = typePart == 'original';
    bool isCleanedText = typePart == 'cleaned';
    bool isSummaryText = typePart == 'summary';
    bool isTitle = typePart == 'title';

    if (isAudio) {
      String data = path;
      timestampToData[timestamp]!["audio_path"] = data;
      timestampToData[timestamp]!["length"] = lengthPart;
    } else if (isOriginalText) {
      String data = File(path).readAsStringSync();
      print("$path text: $data");
      timestampToData[timestamp]!["original_text"] = data;
      timestampToData[timestamp]!["original_text_path"] = path;
    } else if (isCleanedText) {
      String data = File(path).readAsStringSync();
      print("$path text: $data");
      timestampToData[timestamp]!["cleaned_text"] = data;
      timestampToData[timestamp]!["cleaned_text_path"] = path;
    } else if (isSummaryText) {
      String data = File(path).readAsStringSync();
      print("$path text: $data");
      timestampToData[timestamp]!["summary_text"] = data;
      timestampToData[timestamp]!["summary_text_path"] = path;
    } else if (isTitle) {
      String data = File(path).readAsStringSync();
      timestampToData[timestamp]!["title"] = data;
      timestampToData[timestamp]!["title_path"] = path;
    }
  }

  print(timestampToData);

  List<String> sortedKeys = timestampToData.keys.toList()..sort();

  for (String timestamp in sortedKeys) {
    Map<String, dynamic> data = timestampToData[timestamp]!;

    String title = data.containsKey("title") ? data["title"] : timestamp;
    String titlePath = data.containsKey("title_path") ? data["title_path"] : "";
    String audioPath = data.containsKey("audio_path") ? data["audio_path"] : "";
    String originalText = data.containsKey("original_text")
        ? data["original_text"]
        : "Missing transcription!";
    String originalTextPath = data.containsKey("original_text_path")
        ? data["original_text_path"]
        : "";
    String cleanedText = data.containsKey("cleaned_text")
        ? data["cleaned_text"]
        : "Missing transcription!";
    String cleanedTextPath =
        data.containsKey("cleaned_text_path") ? data["cleaned_text_path"] : "";
    String summaryText = data.containsKey("summary_text")
        ? data["summary_text"]
        : "Missing transcription!";
    String summaryTextPath =
        data.containsKey("summary_text_path") ? data["summary_text_path"] : "";

    List<String> dateParts = timestamp.split('_');
    String dateStr = dateParts[0];
    
    int year = int.parse(dateStr.substring(0, 4));
    int month = int.parse(dateStr.substring(4, 6));
    int day = int.parse(dateStr.substring(6, 8));

    print(originalText);

    String timestampDate = "$year.$month.$day";

    FileItem fileItem = FileItem(
      name: title,
      titlePath: titlePath,
      date: timestampDate,
      folderName: "root",
      originalText: originalText,
      originalTextPath: originalTextPath,
      cleanedText: cleanedText,
      cleanedTextPath: cleanedTextPath,
      summaryText: summaryText,
      summaryTextPath: summaryTextPath,
      audioPath: audioPath,
    );
    filenames.insert(0, fileItem);
  }
}

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
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, ""); // Empty string
      },
    );
  }

  void updateList() {}

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
            FileUtilities.openFile(context, fileItem, updateList);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? [] // if search is empty, show empty list
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
            // set the selected suggestion to search field
            query = fileItem.name;
            // show results by the chosen suggestion
            showResults(context);
          },
        );
      },
    );
  }
}

//Search inside a folder, only searches from the files that are inside a folder
class FolderSearchDelegate extends SearchDelegate<String> {
  final List<FileItem> folderContent;
  final String folderName;

  FolderSearchDelegate(this.folderContent, this.folderName);

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, "");
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Show results from the files that are inside a folder
    final List<FileItem> results = _performSearch(query);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (BuildContext context, int index) {
        FileItem fileItem = results[index];
        return ListTile(
          title: Text(fileItem.name),
          subtitle: Text(fileItem.date),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? [] // if search is empty, show empty list
        : folderContent
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

  List<FileItem> _performSearch(String query) {
    // Toteuta haku kansion sisällä
    return folderContent.where((file) {
      // Voit suorittaa haun haluamallasi tavalla tässä
      return file.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}

// File management methods
class FileUtilities {
  static void openFile(
      BuildContext context, FileItem fileItem, Function updateList) {
    // Avaa tiedosto valitussa näkymässä
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OpenedFilePage(
            title: fileItem.name,
            titlePath: fileItem.titlePath,
            originalText: fileItem.originalText,
            originalTextPath: fileItem.originalTextPath,
            cleanedText: fileItem.cleanedText,
            cleanedTextPath: fileItem.cleanedTextPath,
            summaryText: fileItem.summaryText,
            summaryTextPath: fileItem.summaryTextPath,
            audioPath: fileItem.audioPath,
            updateList: updateList),
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await updateFileNames();
    setState(() {});
  }

  void updateList() async {
    await _initializeData();
  }

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
                    FileUtilities.openFile(context, fileItem, updateList);
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

  void updateList() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search field
              showSearch(
                  context: context,
                  delegate: FolderSearchDelegate(folderContent, folderName));
            },
          ),
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
                            FileUtilities.openFile(
                                context, fileItem, updateList);
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
