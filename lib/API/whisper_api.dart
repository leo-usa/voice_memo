import 'dart:io';
import 'api_key.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final Uri whisperUrl =
    Uri.parse("https://api.openai.com/v1/audio/transcriptions");
final Uri promptUrl = Uri.parse("https://api.openai.com/v1/chat/completions");

final Map<String, String> headers = {
  'Content-Type': 'multipart/form-data',
  'Authorization': 'Bearer $apiKey',
};

Future<String> requestWhisper(String file, String? lang) async {
  try {
    var request = http.MultipartRequest('POST', whisperUrl);
    request.headers.addAll(({'Authorization': 'Bearer $apiKey'}));
    request.fields["model"] = 'whisper-1';
    request.fields["response_format"] = "text";
    if (lang != null) request.fields["language"] = lang;
    request.files.add(await http.MultipartFile.fromPath('file', file));
    var response = await request.send();
    var respStream = await http.Response.fromStream(response);
    final respData = respStream.body;

    /*http.Response response = await http.post(
      whisperUrl,
      headers: headers,
      body: {request.file, request.model, null, null, null, null},
    );*/

    print(respData);
    return respData;
  } catch (e) {
    print("requestWhisper error: $e");
  }
  return "null";
}
