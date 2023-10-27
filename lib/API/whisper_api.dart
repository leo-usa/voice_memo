import 'dart:io';
import 'api_key.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final Uri whisperUrl =
    Uri.parse("https://api.openai.com/v1/audio/transcriptions");
final Uri promptUrl = Uri.parse("https://api.openai.com/v1/chat/completions");

final Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $apiKey',
};

class WhisperRequest {
  File? file;
  final String model = "whisper-1";

  WhisperRequest(File? file) {
    this.file = file;
  }
}

Future<String?> requestWhisper(File file) async {
  try {
    WhisperRequest request = WhisperRequest(file);
    if (file == null) {
      return null;
    }
    http.Response response = await http.post(
      whisperUrl,
      headers: headers,
      body: json.encode(request),
    );
    String chatResponse = response.text;
    return chatResponse;
  } catch (e) {
    print("requestWhisper error $e");
  }
  return null;
}
