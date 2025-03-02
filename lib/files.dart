import 'package:flutter/material.dart';
import 'opened_file_page.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'services/directory_service.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;

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
  final String title;  // LLM generated title
  final List<String> keywords;  // User editable keywords

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
    this.title = '',  // Default empty title
    this.keywords = const [],  // Default empty keywords list
  });

  // Create a new FileItem with updated fields
  FileItem copyWith({
    String? name,
    String? titlePath,
    String? date,
    String? folderName,
    String? originalText,
    String? originalTextPath,
    String? cleanedText,
    String? cleanedTextPath,
    String? summaryText,
    String? summaryTextPath,
    String? audioPath,
    String? title,
    List<String>? keywords,
  }) {
    return FileItem(
      name: name ?? this.name,
      titlePath: titlePath ?? this.titlePath,
      date: date ?? this.date,
      folderName: folderName ?? this.folderName,
      originalText: originalText ?? this.originalText,
      originalTextPath: originalTextPath ?? this.originalTextPath,
      cleanedText: cleanedText ?? this.cleanedText,
      cleanedTextPath: cleanedTextPath ?? this.cleanedTextPath,
      summaryText: summaryText ?? this.summaryText,
      summaryTextPath: summaryTextPath ?? this.summaryTextPath,
      audioPath: audioPath ?? this.audioPath,
      title: title ?? this.title,
      keywords: keywords ?? this.keywords,
    );
  }
}

final List<FileItem> filenames = <FileItem>[];

Future<void> updateFileNames() async {
  final directory = await DirectoryService.getSaveDirectory();
  print('Loading files from directory: $directory'); // Debug log

  filenames.clear();

  try {
    final dir = Directory(directory);
    if (!await dir.exists()) {
      print('Directory does not exist: $directory');
      return;
    }

    // First, look for metadata files
    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('_metadata.json')) {
        try {
          final Map<String, dynamic> jsonData = await FileUtilities.readJsonFile(entity.path);
          print('Reading metadata file: ${entity.path}'); // Debug log
          print('Metadata content: $jsonData'); // Debug log

          String originalText = '';
          String cleanedText = '';
          String summaryText = '';

          try {
            if (jsonData['original_text_path'] != null) {
              originalText = await File(jsonData['original_text_path']).readAsString();
            }
            if (jsonData['cleaned_text_path'] != null) {
              cleanedText = await File(jsonData['cleaned_text_path']).readAsString();
            }
            if (jsonData['summary_text_path'] != null) {
              summaryText = await File(jsonData['summary_text_path']).readAsString();
            }
          } catch (e) {
            print('Error reading text files: $e');
          }

          // Format the date
          String dateStr = jsonData['date'] ?? '';
          if (dateStr.length >= 8) {
            String year = dateStr.substring(0, 4);
            String month = dateStr.substring(4, 6);
            String day = dateStr.substring(6, 8);
            dateStr = "$year.$month.$day";
          }

          // Clean up title by removing extra quotes
          String title = jsonData['title'] ?? '';
          if (title.startsWith('"') && title.endsWith('"')) {
            title = title.substring(1, title.length - 1);
          }

          FileItem fileItem = FileItem(
            name: path.basename(entity.path),
            titlePath: entity.path,  // Use the actual metadata file path
            date: dateStr,
            folderName: "root",
            originalText: originalText,
            originalTextPath: jsonData['original_text_path'] ?? '',
            cleanedText: cleanedText,
            cleanedTextPath: jsonData['cleaned_text_path'] ?? '',
            summaryText: summaryText,
            summaryTextPath: jsonData['summary_text_path'] ?? '',
            audioPath: jsonData['audio_path'] ?? '',
            title: title,
            keywords: (jsonData['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
          );
          filenames.insert(0, fileItem);
        } catch (e) {
          print('Error processing metadata file ${entity.path}: $e');
        }
      }
    }

    // Sort files by date
    filenames.sort((a, b) => b.date.compareTo(a.date));
  } catch (e) {
    print('Error updating file names: $e');
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
          onKeywordsChanged: (newKeywords) {
            // Handle keywords change
          },
          onTitleChanged: (newTitle) async {
            try {
              await FileUtilities.updateTitle(fileItem, newTitle, updateList);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Title updated successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update title: $e')),
              );
            }
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
  static Future<void> updateKeywords(FileItem fileItem, List<String> newKeywords, VoidCallback onUpdate) async {
    try {
      // Get the metadata file path from the titlePath
      final String filePath = fileItem.titlePath;
      print('Updating keywords in file: $filePath'); // Debug log
      
      // Read existing metadata
      final Map<String, dynamic> jsonData = await readJsonFile(filePath);
      
      // Update only the keywords field, preserving all other metadata
      jsonData['keywords'] = newKeywords;
      
      print('Writing JSON data: ${jsonEncode(jsonData)}'); // Debug log
      await File(filePath).writeAsString(jsonEncode(jsonData));
      print('Keywords updated: $newKeywords'); // Debug log
      
      onUpdate();
    } catch (e) {
      print('Error updating keywords: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  static Future<Map<String, dynamic>> readJsonFile(String filePath) async {
    try {
      final String jsonString = await File(filePath).readAsString();
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error reading JSON file: $e');
      return {};
    }
  }

  static Future<void> openFile(BuildContext context, FileItem fileItem, VoidCallback onUpdate) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OpenedFilePage(
          title: fileItem.title,
          titlePath: fileItem.titlePath,
          originalText: fileItem.originalText,
          originalTextPath: fileItem.originalTextPath,
          cleanedText: fileItem.cleanedText,
          cleanedTextPath: fileItem.cleanedTextPath,
          summaryText: fileItem.summaryText,
          summaryTextPath: fileItem.summaryTextPath,
          audioPath: fileItem.audioPath,
          updateList: onUpdate,
        ),
      ),
    );
  }

  static Future<List<FileItem>> getFiles(String directory) async {
    try {
      final dir = Directory(directory);
      if (!await dir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await dir.list().toList();
      final List<FileItem> fileItems = [];

      for (var file in files) {
        if (file is File && file.path.endsWith('_metadata.json')) {
          try {
            final Map<String, dynamic> jsonData = await readJsonFile(file.path);
            print('Reading metadata file: ${file.path}'); // Debug log
            print('Metadata content: $jsonData'); // Debug log
            
            String originalText = '';
            String cleanedText = '';
            String summaryText = '';
            
            try {
              if (jsonData['original_text_path'] != null) {
                originalText = await File(jsonData['original_text_path']).readAsString();
              }
              if (jsonData['cleaned_text_path'] != null) {
                cleanedText = await File(jsonData['cleaned_text_path']).readAsString();
              }
              if (jsonData['summary_text_path'] != null) {
                summaryText = await File(jsonData['summary_text_path']).readAsString();
              }
            } catch (e) {
              print('Error reading text files: $e');
            }

            // Format the date
            String dateStr = jsonData['date'] ?? '';
            if (dateStr.length >= 8) {
              String year = dateStr.substring(0, 4);
              String month = dateStr.substring(4, 6);
              String day = dateStr.substring(6, 8);
              dateStr = "$year.$month.$day";
            }

            // Clean up title by removing extra quotes
            String title = jsonData['title'] ?? '';
            if (title.startsWith('"') && title.endsWith('"')) {
              title = title.substring(1, title.length - 1);
            }
            
            fileItems.add(FileItem(
              name: path.basename(file.path),
              titlePath: file.path,
              date: dateStr,
              folderName: 'root',
              originalText: originalText,
              originalTextPath: jsonData['original_text_path'] ?? '',
              cleanedText: cleanedText,
              cleanedTextPath: jsonData['cleaned_text_path'] ?? '',
              summaryText: summaryText,
              summaryTextPath: jsonData['summary_text_path'] ?? '',
              audioPath: jsonData['audio_path'] ?? '',
              title: title,
              keywords: (jsonData['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
            ));
          } catch (e) {
            print('Error processing file ${file.path}: $e');
          }
        }
      }

      fileItems.sort((a, b) => b.date.compareTo(a.date));
      return fileItems;
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }

  static Future<void> updateTitle(FileItem fileItem, String newTitle, VoidCallback onUpdate) async {
    try {
      final String filePath = fileItem.titlePath;
      print('Updating title in file: $filePath'); // Debug log
      
      final Map<String, dynamic> jsonData = await readJsonFile(filePath);
      jsonData['title'] = newTitle;
      
      print('Writing JSON data: ${jsonEncode(jsonData)}'); // Debug log
      await File(filePath).writeAsString(jsonEncode(jsonData));
      print('Title updated to: $newTitle'); // Debug log
      
      onUpdate();
    } catch (e) {
      print('Error updating title: $e');
      rethrow;
    }
  }
}

// File list element
class FileListTile extends StatelessWidget {
  final FileItem fileItem;
  final void Function() onTap;
  final void Function(List<String>) onKeywordsChanged;
  final void Function(String) onTitleChanged;

  const FileListTile({
    Key? key,
    required this.fileItem,
    required this.onTap,
    required this.onKeywordsChanged,
    required this.onTitleChanged,
  }) : super(key: key);

  void _editKeywords(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: fileItem.keywords.join(', '),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Keywords'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter keywords separated by commas.\nExample: meeting, notes, important',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'keyword1, keyword2, keyword3',
                  helperText: 'Press Enter or click Save when done',
                ),
                maxLines: null,
                onSubmitted: (value) {
                  final List<String> newKeywords = value
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  onKeywordsChanged(newKeywords);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final List<String> newKeywords = controller.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                onKeywordsChanged(newKeywords);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editTitle(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: fileItem.title,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Title'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter new title',
            ),
            maxLines: null,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                onTitleChanged(value);
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  onTitleChanged(newTitle);
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

  String _formatDateTime(String dateStr) {
    try {
      // Extract date and time parts from the format "YYYYMMDD_HHMMSS"
      final String datePart = dateStr.substring(0, 8);
      final String timePart = dateStr.substring(9, 15);
      
      final year = datePart.substring(0, 4);
      final month = datePart.substring(4, 6);
      final day = datePart.substring(6, 8);
      
      final hour = timePart.substring(0, 2);
      final minute = timePart.substring(2, 4);
      
      return "$year.$month.$day at $hour:$minute";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  fileItem.title.isNotEmpty ? fileItem.title : path.basenameWithoutExtension(fileItem.name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () => _editTitle(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format date and add recording length
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(text: _formatDateTime(fileItem.name.split('_metadata.json')[0])),
                    TextSpan(
                      text: ' • ${fileItem.name.split('_')[2]}', // Length part from filename
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (fileItem.keywords.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...fileItem.keywords.map((keyword) => Chip(
                          label: Text(
                            keyword,
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                        )),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _editKeywords(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                )
              else
                TextButton(
                  onPressed: () => _editKeywords(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Add keywords',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
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
                  onKeywordsChanged: (newKeywords) async {
                    try {
                      await FileUtilities.updateKeywords(fileItem, newKeywords, updateList);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Keywords updated successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update keywords: $e')),
                      );
                    }
                  },
                  onTitleChanged: (newTitle) async {
                    try {
                      await FileUtilities.updateTitle(fileItem, newTitle, updateList);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title updated successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update title: $e')),
                      );
                    }
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
                        onKeywordsChanged: (newKeywords) {
                          // Handle keywords change
                        },
                        onTitleChanged: (newTitle) async {
                          try {
                            await FileUtilities.updateTitle(fileItem, newTitle, updateList);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Title updated successfully')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update title: $e')),
                            );
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
