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

    print(respData);
    return respData;
  } catch (e) {
    print("requestWhisper error: $e");
  }
  return "null";
}

var testTxt =
    "Suomen kielen kirosanat ovat ei-kirjaimellisesti käytettyjä suomenkielisiä sanoja, jotka rikkovat jotain kulttuurista tabua. Tällaiset tabut liittyvät esimerkiksi uskontoon, eritteisiin tai seksuaalisuuteen. Useat suomen kielessä nykyään kirosanana käytetyt sanat eivät alun perin olleet kirosanoja, vaan ovat muuttuneet sellaisiksi vähitellen. Paitsi parahduksiin ja noitumiseen, suomen kielen kirosanoja käytetään muun muassa vahvistussanoina (helvetin hyvä), sävypartikkeleina tai ylimääräisinä lisäyksinä (No kerro jo jumalauta). Kirosanoja voidaan käyttää myös kieltosanattomissa mutta merkitykseltään kielteisissä ilmauksissa, joita Lari Kotilainen nimittää aggressiiviksi (Vittu tästä jutusta kukaan tykkää). Käsitykset siitä, mitkä sanat ovat kirosanoja, vaihtelevat. Solvaussanoja (mulkku), miedompia päivittelysanoja (jestas), kiertoilmaisuja (voi perjantai) ja muuta karkeaa kielenkäyttöä ei aina pidetä kirosanoina. Suomen kielessä uskonnollisperäiset kirosanat ovat vuosisatojen kuluessa menettäneet voimaansa, kun taas seksuaalisperäiset ovat voimistuneet. Kirosanat eivät välttämättä ole aina halventavia, vaan ne voivat ilmaista myös ryhmään kuulumista ja läheisyyttä.";

Future<String> requestSummary(String text) async {
  try {
    var body = {
      "model": "gpt-4-1106-preview",
      "messages": [
        {
          "role": "user",
          "content":
              "Please summarize the following text in the language it is in: $text (if this fails for any reason, simply respond with 'unable to summarize')"
        }
      ]
    };
    var response = await http.post(
      promptUrl,
      headers: headers,
      body: json.encode(body),
    );
    String respBody = utf8.decode(response.bodyBytes);
    Map<String, dynamic> respJson = json.decode(respBody);
    List<dynamic> choices = respJson['choices'];
    Map<String, dynamic> message = choices[0]['message'];
    print(message['content']);
    return message['content'];
  } catch (e) {
    print("requestSummary error: $e");
  }
  return "null";
}

Future<String> requestClean(String text) async {
  try {
    var body = {
      "model": "gpt-4-1106-preview",
      "messages": [
        {
          "role": "user",
          "content":
              "DO NOT comment on my request; simply write the desired sentence in response. As a voice to text translator, provide a polished version of the following text. Format the response to match the context. Pay attention to logical organization and clarity.  Use '##' to mark the beginning of each title or heading and use the '||' symbol to separate different paragraphs. IF the sentence mentions the word list, use '*' to mark items in list. Ensure the text is readable and coherent. Write the response only in the same language as a reference text. IF this fails for any reason, simply respond with 'unable to clean up'. \n Here's the text, pay special attention that you use the same language as the transcript: \n $text"
        }
      ]
    };
    var response = await http.post(
      promptUrl,
      headers: headers,
      body: json.encode(body),
    );
    String respBody = utf8.decode(response.bodyBytes);
    Map<String, dynamic> respJson = json.decode(respBody);
    List<dynamic> choices = respJson['choices'];
    Map<String, dynamic> message = choices[0]['message'];
    print(message['content']);
    return message['content'];
  } catch (e) {
    print("requestClean error: $e");
  }
  return "null";
}
