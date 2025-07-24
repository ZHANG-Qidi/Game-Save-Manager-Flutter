import 'dart:io';
import 'package:ini/ini.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path_lib;
import 'saveload_core_common.dart';

Future<void> safeCreateFolder(Directory dir) async {
  try {
    if (await dir.exists()) {
      // print('Directory exists');
      return;
    }
    await dir.create(recursive: true);
    print('New directory success: ${dir.path}');
  } catch (e) {
    throw Exception('New directory failed: $e');
  }
}

Future<void> copyDirectory(Directory source, Directory destination) async {
  try {
    await destination.create(recursive: true);
    await for (final entity in source.list()) {
      final newDestination = Directory(
        [destination.path, entity.path.split(Platform.pathSeparator).last].join(Platform.pathSeparator),
      );
      if (entity is File) {
        await entity.copy(newDestination.path);
      } else if (entity is Directory) {
        await copyDirectory(entity, newDestination);
      }
    }
  } catch (e) {
    throw Exception('Copy directory error with: $e');
  }
}

Future<List<FileSystemEntity>> listDirectoryContents(Directory dir) async {
  try {
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: ${dir.path}');
    }
    final contents = <FileSystemEntity>[];
    await for (final entity in dir.list()) {
      contents.add(entity);
    }
    return contents;
  } catch (e) {
    throw Exception('Failed to list contentes: $e');
  }
}

Future<List<String>> listDirectoryFiles(String dirString) async {
  try {
    final dir = Directory(dirString);
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: ${dir.path}');
    }
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(entity);
      }
    }
    return files.map((file) => file.path).toList();
  } catch (e) {
    throw Exception('Failed to list files: $e');
  }
}

Future<List<String>> listDirectorySubDirectories(String dirString) async {
  try {
    final dir = Directory(dirString);
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: ${dir.path}');
    }
    final directories = <Directory>[];
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        directories.add(entity);
      }
    }
    return directories.map((directory) => directory.path).toList();
  } catch (e) {
    throw Exception('Failed to list subdirectories: $e');
  }
}

Future<List<File>> listDirectoryAllFiles(Directory dir) async {
  try {
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: ${dir.path}');
    }
    final files = <File>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    return files;
  } catch (e) {
    throw Exception('Directory traversal error: $e');
  }
}

Future<List<File>> listDirectoryIniFiles(Directory dir) async {
  try {
    final files = <File>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.ini')) {
        files.add(entity);
      }
    }
    return files;
  } catch (e) {
    throw Exception('Directory traversal error: $e');
  }
}

Future<Map> readIniFile(String game) async {
  try {
    final file = File(['SaveLoad', game, 'Path.ini'].join(Platform.pathSeparator));
    final content = await file.readAsString();
    final config = Config.fromString(content);
    var values = {};
    values['folder'] = config.get('path', 'folder');
    values['file'] = config.get('path', 'file');
    return values;
  } on FileSystemException catch (e) {
    throw Exception('File system error with: $e');
  } catch (e) {
    throw Exception('Read ini file error with: $e');
  }
}

Future<void> writeIniFile({required String game, String saveFolder = '', String saveFile = ''}) async {
  try {
    final config = Config();
    config.addSection("path");
    config.set("path", "folder", saveFolder);
    config.set("path", "file", saveFile);
    final output = config.toString();
    final file = File(['SaveLoad', game, 'Path.ini'].join(Platform.pathSeparator));
    await file.writeAsString(output);
  } on FileSystemException catch (e) {
    throw Exception('File system error with: $e');
  } catch (e) {
    throw Exception('Write ini file error with: $e');
  }
}

Future<List<String>> gameListFunc() async {
  try {
    final dir = Directory('SaveLoad');
    await safeCreateFolder(dir);
    final directories = await listDirectorySubDirectories(dir.path);
    return directories;
  } catch (e) {
    throw Exception('Get the list of Games error: $e');
  }
}

Future<(List<String>, String, String)> profileListFunc(String game) async {
  try {
    if (game.isEmpty) {
      return (List<String>.empty(), '', '');
    }
    final dir = Directory(['SaveLoad', game].join(Platform.pathSeparator));
    final directories = await listDirectorySubDirectories(dir.path);
    final pathIni = await readIniFile(game);
    final String folder = pathIni['folder'];
    final String file = pathIni['file'];
    return (directories, folder, file);
  } catch (e) {
    throw Exception('Get the list of Profiles error: $e');
  }
}

Future<List<String>> saveListFunc({required String game, required String profile}) async {
  try {
    if (game.isEmpty || profile.isEmpty) {
      return List<String>.empty();
    }
    final dir = Directory(['SaveLoad', game, profile].join(Platform.pathSeparator));
    var contents = await listDirectoryContents(dir);
    List<String> contentsString = contents.map((dir) => dir.path).toList();
    contentsString = await saveListFuncRemove(contentsString);
    return contentsString;
  } catch (e) {
    throw Exception('Get the list of sub directory error: $e');
  }
}

Future<List<String>> saveListFuncRemove(List<String> contentsString) async {
  List<String> contentsStringToRemove = [];
  contentsString.sort((a, b) => b.compareTo(a));
  Map<String, int> commentMap = {};
  for (final content in contentsString) {
    final comment = getComment(content);
    commentMap[comment] = commentMap[comment] ?? 0;
    commentMap[comment] = commentMap[comment]! + 1;
    if (commentMap[comment]! > 3) {
      contentsStringToRemove.add(content);
      final type = await FileSystemEntity.type(content);
      if (type == FileSystemEntityType.file) {
        await File(content).delete();
      } else if (type == FileSystemEntityType.directory) {
        await Directory(content).delete(recursive: true);
      }
    }
  }
  for (final content in contentsStringToRemove) {
    contentsString.removeWhere((item) => item == content);
  }
  // print('commentMap = ${commentMap.toString()}');
  return contentsString;
}

Future<String> gameNew({required String game, String saveFolder = '', String saveFile = ''}) async {
  try {
    if (game.isEmpty) {
      return 'NG';
    }
    final dir = Directory(['SaveLoad', game].join(Platform.pathSeparator));
    await safeCreateFolder(dir);
    await writeIniFile(game: game, saveFolder: saveFolder, saveFile: saveFile);
    return 'OK';
  } catch (e) {
    throw Exception('Game new error with: $e');
  }
}

Future<String> gameDelete(String game) async {
  final dir = Directory(['SaveLoad', game].join(Platform.pathSeparator));
  try {
    if (game.isEmpty) {
      return 'NG';
    }
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: ${dir.path}');
    }
    await dir.delete(recursive: true);
    print("Game delete success: ${dir.path}");
    return 'OK';
  } catch (e) {
    throw Exception('Game delete error with: $e');
  }
}

Future<String> profileNew({required String game, required String profile}) async {
  try {
    if (game.isEmpty || profile.isEmpty) {
      return 'NG';
    }
    await safeCreateFolder(Directory(['SaveLoad', game, profile].join(Platform.pathSeparator)));
    return 'OK';
  } catch (e) {
    throw Exception('Profile new error with: $e');
  }
}

Future<String> profileDelete({required String game, required String profile}) async {
  try {
    if (game.isEmpty || profile.isEmpty) {
      return 'NG';
    }
    final dir = Directory(['SaveLoad', game, profile].join(Platform.pathSeparator));
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: ${dir.path}');
    }
    await dir.delete(recursive: true);
    print("Profile delete success: ${dir.path}");
    return 'OK';
  } catch (e) {
    throw Exception('Profile delete error with: $e');
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
    if (game.isEmpty || profile.isEmpty) {
      return 'NG';
    }
    DateFormat formatter = DateFormat('yyyy-MM-dd HH-mm-ss');
    DateTime modifiedTimeLast = DateTime(1970);
    if (saveFolder.isNotEmpty) {
      final dir = Directory(saveFolder);
      final fileList = await listDirectoryAllFiles(dir);
      for (final entity in fileList) {
        final DateTime modifiedTime = await entity.lastModified();
        if (modifiedTime.isAfter(modifiedTimeLast)) {
          modifiedTimeLast = modifiedTime;
        }
      }
      final String strModifiedTimeLast = formatter.format(modifiedTimeLast);
      String targetFolder;
      if (comment.isEmpty) {
        targetFolder = ['SaveLoad', game, profile, strModifiedTimeLast].join(Platform.pathSeparator);
      } else {
        targetFolder = ['SaveLoad', game, profile, '$strModifiedTimeLast@$comment'].join(Platform.pathSeparator);
      }
      final sourceDir = Directory(saveFolder);
      final destDir = Directory(targetFolder);
      if (!await destDir.exists()) {
        await copyDirectory(sourceDir, destDir);
      }
      return targetFolder;
    }
    if (saveFile.isNotEmpty) {
      modifiedTimeLast = await File(saveFile).lastModified();
      final String strModifiedTimeLast = formatter.format(modifiedTimeLast);
      String targetFile;
      if (comment.isEmpty) {
        targetFile = ['SaveLoad', game, profile, strModifiedTimeLast + path_lib.extension(saveFile)].join(Platform.pathSeparator);
      } else {
        targetFile = [
          'SaveLoad',
          game,
          profile,
          '$strModifiedTimeLast@$comment${path_lib.extension(saveFile)}',
        ].join(Platform.pathSeparator);
      }
      final sourceFile = File(saveFile);
      final destFile = File(targetFile);
      if (!await destFile.exists()) {
        await sourceFile.copy(destFile.path);
      }
      return targetFile;
    }
    return 'NG';
  } catch (e) {
    throw Exception('Save new error with: $e');
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
    if (game.isEmpty || profile.isEmpty || save.isEmpty) {
      return 'NG';
    }
    final savePath = ['SaveLoad', game, profile, save].join(Platform.pathSeparator);
    if (saveFolder.isNotEmpty) {
      final dir = Directory(savePath);
      if (!await dir.exists()) {
        throw Exception('Directory does not exist: ${dir.path}');
      }
      await dir.delete(recursive: true);
      print("Save delete success: ${dir.path}");
    }
    if (saveFile.isNotEmpty) {
      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }
      await file.delete();
      print("Save delete success: ${file.path}");
    }
    return 'OK';
  } catch (e) {
    throw Exception('Save delete error with: $e');
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
    if (game.isEmpty || profile.isEmpty || save.isEmpty) {
      return 'NG';
    }
    final savePath = ['SaveLoad', game, profile, save].join(Platform.pathSeparator);
    if (saveFolder.isNotEmpty) {
      final sourcePath = Directory(savePath);
      final destPath = Directory(saveFolder);
      if (await destPath.exists()) {
        await destPath.delete(recursive: true);
      }
      await copyDirectory(sourcePath, destPath);
      print("Save load success: ${sourcePath.path}");
      return 'OK';
    }
    if (saveFile.isNotEmpty) {
      final sourcePath = File(savePath);
      final destPath = File(saveFile);
      if (await destPath.exists()) {
        destPath.delete();
      }
      await sourcePath.copy(destPath.path);
      print("Save load success: ${sourcePath.path}");
      return 'OK';
    }
    return 'NG';
  } catch (e) {
    throw Exception('Save load error with: $e');
  }
}

Future<String> pathSeparatorGet() async {
  try {
    String result = Platform.pathSeparator;
    return result;
  } catch (e) {
    throw Exception('Error with: $e');
  }
}

Future<String> getAppDataPath() async {
  if (Platform.isWindows) {
    return Platform.environment['APPDATA'] ?? 'null';
  } else if (Platform.isMacOS) {
    return '${Platform.environment['HOME']}/Library/Application Support';
  } else if (Platform.isLinux) {
    final pathDeck = '${Platform.environment['HOME']}/.local/share/Steam/steamapps/compatdata';
    if (await FileSystemEntity.isDirectory(pathDeck)) {
      return pathDeck;
    }
    return Platform.environment['HOME'] ?? 'null';
  }
  return 'null';
}

Future<List<String>> getRootDirectory() async {
  if (Platform.isWindows) {
    List<String> availableDrives = [];
    for (int i = 65; i <= 90; i++) {
      String driveLetter = String.fromCharCode(i);
      String path = '$driveLetter:${Platform.pathSeparator}';
      if (await Directory(path).exists()) {
        availableDrives.add(path);
      }
    }
    return availableDrives;
  } else if (Platform.isMacOS) {
    return ['${Platform.environment['HOME']}/Library/Application Support'];
  } else if (Platform.isLinux) {
    final pathDeck = '${Platform.environment['HOME']}/.local/share/Steam/steamapps/compatdata';
    if (await FileSystemEntity.isDirectory(pathDeck)) {
      return [pathDeck];
    }
    return [Platform.environment['HOME'] ?? 'null'];
  }
  return ['null'];
}
