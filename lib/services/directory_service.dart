import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DirectoryService {
  static const String _savedDirectoryKey = 'saved_directory';
  
  static Future<String> getDefaultDirectory() async {
    // Get the user's home directory
    final home = await getApplicationDocumentsDirectory();
    final userHome = Directory(home.path.split('Data')[0]);
    
    // Create path to Documents/Memo
    final memoDir = Directory('${userHome.path}Documents/Memo');
    
    // Create the directory if it doesn't exist
    if (!await memoDir.exists()) {
      await memoDir.create(recursive: true);
      print('Created Memo directory at: ${memoDir.path}');
    }
    
    return memoDir.path;
  }
  
  static Future<String> getSaveDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedDirectoryKey) ?? await getDefaultDirectory();
  }
  
  static Future<void> setSaveDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedDirectoryKey, path);
  }
  
  static Future<void> resetToDefault() async {
    final defaultDir = await getDefaultDirectory();
    await setSaveDirectory(defaultDir);
  }
} 