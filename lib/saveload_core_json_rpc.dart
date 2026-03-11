import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const String rpcEndpoint = '/jsonrpc';
}

Future<dynamic> fetchJsonRPC(String method, [List<dynamic>? params]) async {
  final String url = ApiConfig.rpcEndpoint;
  try {
    final int requestId = DateTime.now().millisecondsSinceEpoch;
    final request = {'jsonrpc': '2.0', 'method': method, 'params': params ?? [], 'id': requestId};
    final response = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode(request));
    if (response.statusCode != 200) {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final dynamic responseId = responseData['id'];
    if (responseId != requestId) {
      throw Exception(
        'RPC ID Mismatch: Request id=$requestId, Response id=$responseId, \nRPC Error: ${responseData['error']['code']} ${responseData['error']['message']}',
      );
    }
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

Future<String> saveRename({
  required String game,
  required String profile,
  required String saveFolder,
  required String saveFile,
  required String save,
  required String name,
}) async {
  try {
    final responseBody = await fetchJsonRPC('saveRename', [game, profile, saveFolder, saveFile, save, name]);
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

Future<List<String>> listDirectoryFilesNames(String dirString) async {
  try {
    final responseBody = await fetchJsonRPC('listDirectoryFilesNames', [dirString]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<List<String>> listDirectorySubDirectoriesNames(String dirString) async {
  try {
    final responseBody = await fetchJsonRPC('listDirectorySubDirectoriesNames', [dirString]);
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

Future<List<String>> funcListMdnsServer() async {
  try {
    final responseBody = await fetchJsonRPC('funcListMdnsServer');
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> handleSync({
  required String game,
  required String profile,
  required String save,
  required String url,
  required String port,
}) async {
  try {
    final responseBody = await fetchJsonRPC('handleSync', [game, profile, save, url, port]);
    return responseBody;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}
