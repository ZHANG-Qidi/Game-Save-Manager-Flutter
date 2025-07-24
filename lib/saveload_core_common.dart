import 'saveload_core.dart';

String mirrorPath(String path) {
  return path.split(pathSeparator).reversed.join(pathSeparator);
}

String getFileName(String path) {
  return path.split(pathSeparator).last;
}

String getComment(String path) {
  return path.contains('@') ? (path.split('@').last).split('.').first : '';
}

String? _cachedPathSeparator;
Future<void> initPathSeparator() async {
  _cachedPathSeparator = await pathSeparatorGet();
}

String get pathSeparator {
  return _cachedPathSeparator!;
}

String getExtension(String filePath, [int level = 1]) {
  String fileName = filePath.split('/').last.split('\\').last;
  List<String> parts = fileName.split('.');
  if (parts.length <= 1) {
    return '';
  }
  int start = parts.length - level;
  if (start < 1) start = 1;
  return '.${parts.sublist(start).join('.')}';
}

String getDirname(String path) {
  path = path.replaceAll(RegExp(r'[\\/]+$'), '');
  final driveMatch = RegExp(r'^([A-Za-z]:)\\[^\\]+$').firstMatch(path);
  if (driveMatch != null) return '${driveMatch.group(1)}$pathSeparator';
  final isWindowsRoot = RegExp(r'^[A-Za-z]:$').hasMatch(path);
  if (isWindowsRoot) return '$path$pathSeparator';
  if (path == '') return pathSeparator;
  List<String> segments = path.split(pathSeparator);
  if (segments.length <= 1) return '.';
  final result = segments.sublist(0, segments.length - 1).join(pathSeparator);
  if (result == '') return pathSeparator;
  return result;
}
