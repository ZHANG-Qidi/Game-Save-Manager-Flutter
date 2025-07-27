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

class ApiConfig {
  static const String rpcEndpoint = '/jsonrpc';
}

Future<dynamic> fetchJsonRPC(String method, [List<dynamic>? params]) async {
  final String url = ApiConfig.rpcEndpoint;
  try {
    final request = {'jsonrpc': '2.0', 'method': method, 'params': params ?? [], 'id': DateTime.now().millisecondsSinceEpoch};
    final response = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(request));
    if (response.statusCode != 200) {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
    final responseData = json.decode(response.body) as Map<String, dynamic>;
    if (responseData.containsKey('error')) {
      throw Exception('RPC Error: ${responseData['error']['code']} ${responseData['error']['message']}');
    }
    return responseData['result'];
  } catch (e) {
    throw Exception('RPC call failed: $e');
  }
}

Future<List<String>> gameListFunc() async {
  try {
    final responseBody = await fetchJsonRPC('gameListFunc');
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<(List<String>, String, String)> profileListFunc(String game) async {
  try {
    final responseBody = await fetchJsonRPC('profileListFunc', [game]);
    final List<String> profileList = List<String>.from(responseBody[0]);
    final String folder = responseBody[1] as String;
    final String file = responseBody[2] as String;
    return (profileList, folder, file);
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<List<String>> saveListFunc({required String game, required String profile}) async {
  try {
    final responseBody = await fetchJsonRPC('saveListFunc', [game, profile]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> gameDelete(String game) async {
  try {
    final responseBody = await fetchJsonRPC('gameDelete', [game]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> profileNew({required String game, required String profile}) async {
  try {
    final responseBody = await fetchJsonRPC('profileNew', [game, profile]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> profileDelete({required String game, required String profile}) async {
  try {
    final responseBody = await fetchJsonRPC('profileDelete', [game, profile]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> saveNew({
  required String game,
  required String profile,
  required String saveFolder,
  required String saveFile,
  required String comment,
}) async {
  try {
    final responseBody = await fetchJsonRPC('saveNew', [game, profile, saveFolder, saveFile, comment]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> saveDelete({
  required String game,
  required String profile,
  required String saveFolder,
  required String saveFile,
  required String save,
}) async {
  try {
    final responseBody = await fetchJsonRPC('saveDelete', [game, profile, saveFolder, saveFile, save]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> saveLoad({
  required String game,
  required String profile,
  required String saveFolder,
  required String saveFile,
  required String save,
}) async {
  try {
    final responseBody = await fetchJsonRPC('saveLoad', [game, profile, saveFolder, saveFile, save]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> pathSeparatorGet() async {
  try {
    final responseBody = await fetchJsonRPC('pathSeparator');
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<List<String>> listDirectoryFiles(String dirString) async {
  try {
    final responseBody = await fetchJsonRPC('listDirectoryFiles', [dirString]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<List<String>> listDirectorySubDirectories(String dirString) async {
  try {
    final responseBody = await fetchJsonRPC('listDirectorySubDirectories', [dirString]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> getAppDataPath() async {
  try {
    final responseBody = await fetchJsonRPC('getAppDataPath');
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<List<String>> getRootDirectory() async {
  try {
    final responseBody = await fetchJsonRPC('getRootDirectory');
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> gameNew({required String game, String saveFolder = '', String saveFile = ''}) async {
  try {
    final responseBody = await fetchJsonRPC('gameNew', [game, saveFolder, saveFile]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> saveDownload({required String game, required String profile, required String save}) async {
  try {
    final url = '/download';
    final body = jsonEncode({'game': game, 'profile': profile, 'save': save});
    final response = await http.post(Uri.parse(url), body: body, headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      final blob = html.Blob([response.bodyBytes], 'application/zip');
      final anchor = html.AnchorElement(href: html.Url.createObjectUrlFromBlob(blob))
        ..download = '$save.zip'
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
      return file.name;
    } else {
      // print('Upload failed:${response.statusCode}');
      return 'NG';
    }
  } catch (e) {
    throw Exception('Error with: $e');
  }
}
