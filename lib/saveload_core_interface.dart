typedef GameListFuncFunction = Future<List<String>> Function();
typedef ProfileListFuncFunction = Future<(List<String>, String, String)> Function(String game);
typedef SaveListFuncFunction = Future<List<String>> Function({required String game, required String profile});
typedef GameDeleteFunction = Future<String> Function(String game);
typedef ProfileNewFunction = Future<String> Function({required String game, required String profile});
typedef ProfileDeleteFunction = Future<String> Function({required String game, required String profile});
typedef SaveNewFunction =
    Future<String> Function({
      required String game,
      required String profile,
      required String saveFolder,
      required String saveFile,
      required String comment,
    });
typedef SaveDeleteFunction =
    Future<String> Function({
      required String game,
      required String profile,
      required String saveFolder,
      required String saveFile,
      required String save,
    });
typedef SaveLoadFunction =
    Future<String> Function({
      required String game,
      required String profile,
      required String saveFolder,
      required String saveFile,
      required String save,
    });
