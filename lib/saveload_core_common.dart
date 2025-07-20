import 'saveload_core.dart';

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
