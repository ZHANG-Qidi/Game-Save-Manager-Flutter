import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

Future<String> fetchGet() async {
  try {
    final response = await http.get(Uri.parse('/index.html'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error: $e');
  }
}

Future<String> saveDownload({required String game, required String profile, required String save}) async {
  try {
    final url = '/download';
    final body = jsonEncode({'game': game, 'profile': profile, 'save': save});
    final response = await http.post(Uri.parse(url), body: body, headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      final contentDisposition = response.headers['content-disposition'];
      String? filename;
      if (contentDisposition != null) {
        final regex = RegExp(r'filename="(.+)"');
        final match = regex.firstMatch(contentDisposition);
        if (match != null) {
          filename = match.group(1);
        }
      }
      final blob = html.Blob([response.bodyBytes], 'application/zip');
      final anchor = html.AnchorElement(href: html.Url.createObjectUrlFromBlob(blob))
        ..download = filename ?? [game, profile, '$save.zip'].join('_')
        ..click();
      Future.delayed(Duration(seconds: 2), () {
        html.Url.revokeObjectUrl(anchor.href!);
      });
      return 'OK';
    } else {
      // print('Download failed: ${response.statusCode}');
      return 'NG';
    }
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> saveUpload({required String game, required String profile}) async {
  try {
    final input = html.FileUploadInputElement()..accept = '.zip';
    input.click();
    await input.onChange.first;
    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;
    final bytes = reader.result as List<int>;
    final Map<String, dynamic> jsonParams = {'game': game, 'profile': profile};
    final uri = Uri.parse('/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name))
      ..fields['params'] = json.encode(jsonParams);
    final response = await request.send();
    if (response.statusCode == 200) {
      // print('Upload successful!');
      return await response.stream.bytesToString();
    } else {
      // print('Upload failed:${response.statusCode}');
      return 'NG';
    }
  } catch (e) {
    throw Exception('Error with: $e');
  }
}
