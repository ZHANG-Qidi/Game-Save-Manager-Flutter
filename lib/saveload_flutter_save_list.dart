import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'saveload_core.dart';
import 'saveload_core_common.dart';
import 'saveload_flutter_game_list.dart';
import 'saveload_flutter_profile_list.dart';

class SaveState extends ChangeNotifier {
  int _saveIndex = 0;
  int get saveIndex => _saveIndex;
  void setIndex(int index) {
    _saveIndex = index;
    notifyListeners();
  }

  List<String> _saveList = [];
  List<String> get saveList => _saveList;
  void updateList(List<String> saveList) {
    _saveList = saveList;
    if (saveList.isEmpty) {
      _saveIndex = -1;
    } else if (_saveIndex >= saveList.length) {
      _saveIndex = saveList.isEmpty ? -1 : saveList.length - 1;
    } else if (_saveIndex < 0 && saveList.isNotEmpty) {
      _saveIndex = 0;
    }
    notifyListeners();
  }
}

class SaveCenterSelectedList extends StatefulWidget {
  const SaveCenterSelectedList({super.key});
  @override
  State<SaveCenterSelectedList> createState() => _SaveCenterSelectedListState();
}

class _SaveCenterSelectedListState extends State<SaveCenterSelectedList> {
  late final ScrollController _scrollController;
  late final TextEditingController _commentController;
  final double _itemHeight = 80.0;
  final double _itemMarginHeight = 4.0;
  final double _itemSizedBoxHeight = 2.0;
  final double _bottomInfoHeight = 60.0;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _commentController = TextEditingController();
    _loadSaveList(savePath: 'NG');
  }

  Future<void> _loadSaveList({String savePath = ''}) async {
    setState(() => _isLoading = true);
    try {
      final saveState = context.read<SaveState>();
      final gameState = context.read<GameState>();
      final gameList = gameState.gameList;
      final gameIndex = gameState.gameIndex;
      final gameName = getFileName(gameList[gameIndex]);
      final profileState = context.read<ProfileState>();
      final profileList = profileState.profileList;
      final profileIndex = profileState.profileIndex;
      final profileName = getFileName(profileList[profileIndex]);
      final saveList = await saveListFunc(game: gameName, profile: profileName);
      await Future.microtask(() async {
        saveState.updateList(saveList);
        await _loadSaveIndex(savePath);
        _scrollToIndex();
        await _loadComment();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSaveIndex(String savePath) async {
    final saveState = context.read<SaveState>();
    final saveList = saveState.saveList;
    final comment = _commentController.text;
    int saveIndex = saveState.saveIndex;
    if (saveList.isEmpty) return;
    final commentSelected = getComment(saveList[saveIndex]);
    if ('NG' == savePath) return;
    final indexMap = {for (var i = 0; i < saveList.length; i++) saveList[i]: i};
    if (savePath.isNotEmpty) {
      saveIndex = indexMap[savePath] ?? -1;
      if (-1 == saveIndex) return;
    } else if (commentSelected == comment) {
      return;
    } else {
      final saveListFilter = comment.isNotEmpty
          ? saveList.where((item) => (comment == getComment(item))).toList()
          : saveList.where((item) => !item.contains('@')).toList();
      if (saveListFilter.isNotEmpty) {
        int indexDiffMin = saveList.length;
        int closestIndex = saveIndex;
        for (final save in saveListFilter) {
          final indexSave = indexMap[save] ?? -1;
          if (-1 == indexSave) continue;
          final indexDiff = (saveIndex - indexSave).abs();
          if (indexDiff < indexDiffMin) {
            closestIndex = indexSave;
            indexDiffMin = indexDiff;
          }
        }
        saveIndex = closestIndex;
      }
    }
    saveState.setIndex(saveIndex);
  }

  Future<void> _loadComment() async {
    final saveState = context.read<SaveState>();
    final saveList = saveState.saveList;
    final saveIndex = saveState.saveIndex;
    String comment = '';
    if (saveList.isNotEmpty) {
      final saveName = saveList[saveIndex];
      comment = getComment(saveName);
    }
    _commentController.text = comment;
  }

  void _scrollToIndex() {
    final saveState = context.read<SaveState>();
    final saveIndex = saveState.saveIndex;
    if (saveIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (!mounted) return;
      final double itemMarginHeightLocal = _itemHeight + _itemMarginHeight * 2;
      final double targetPosition = saveIndex * itemMarginHeightLocal;
      final double screenHeight = MediaQuery.of(context).size.height;
      final double appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 56;
      final double availableHeight = screenHeight - appBarHeight - _bottomInfoHeight * 3 - _itemSizedBoxHeight * 4;
      final double centerPosition = targetPosition - (availableHeight - itemMarginHeightLocal) / 2;
      final double maxScroll = _scrollController.position.maxScrollExtent + itemMarginHeightLocal;
      final double minScroll = _scrollController.position.minScrollExtent;
      final double adjustedPosition = centerPosition.clamp(minScroll, maxScroll);
      _scrollController.animateTo(adjustedPosition, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SaveState>(
      builder: (context, saveState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Save List'),
            centerTitle: true,
            actions: [
              _buildRefreshButton(),
              _buildDeleteButton(saveState),
              _buildDownloadButton(saveState),
              _buildUploadButton(saveState),
            ],
          ),
          body: Column(
            children: [
              Container(height: _itemSizedBoxHeight, color: Colors.blue),
              _isLoading ? Expanded(child: Center(child: CircularProgressIndicator())) : _buildSaveListView(saveState),
              Container(height: _itemSizedBoxHeight, color: Colors.blue),
              _buildSaveContainer(saveState),
              Container(height: _itemSizedBoxHeight, color: Colors.blue),
              _buildCommentContainer(),
              Container(height: _itemSizedBoxHeight, color: Colors.blue),
              _buildSaveLoadContainer(saveState),
            ],
          ),
          floatingActionButton: saveState.saveList.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    saveState.setIndex(0);
                    _scrollToIndex();
                    _loadComment();
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.first_page, color: Colors.white),
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildSaveContainer(SaveState saveState) {
    final saveIndex = saveState.saveIndex;
    final saveList = saveState.saveList;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.shade100, blurRadius: 10, spreadRadius: 2)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          saveList.isEmpty ? 'NO SAVE' : getFileName(saveList[saveIndex]),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSaveListView(SaveState saveState) {
    final saveIndex = saveState.saveIndex;
    final saveList = saveState.saveList;
    if (saveList.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_box, size: 64, color: Colors.grey.shade300),
              Text('No save available'),
              ElevatedButton(onPressed: _loadSaveList, child: Text('Refresh list')),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemExtent: _itemHeight + _itemMarginHeight * 2,
        controller: _scrollController,
        itemCount: saveList.length,
        itemBuilder: (context, index) {
          final bool isSelected = index == saveIndex;
          return GestureDetector(
            key: ValueKey(saveList[index]),
            onTap: () {
              saveState.setIndex(index);
              _scrollToIndex();
              _loadComment();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _itemHeight,
              margin: EdgeInsets.symmetric(vertical: _itemMarginHeight),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                boxShadow: isSelected ? [BoxShadow(color: Colors.blue.shade200, blurRadius: 10, spreadRadius: 2)] : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isSelected ? 24 : 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black,
                  ),
                  child: Text(getFileName(saveList[index]), textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRefreshButton() {
    return IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSaveList);
  }

  Widget _buildDeleteButton(SaveState saveState) {
    final saveList = saveState.saveList;
    final saveIndex = saveState.saveIndex;
    final saveName = saveList.isEmpty ? '' : getFileName(saveList[saveIndex]);
    if (saveList.isEmpty) {
      return IconButton(icon: Icon(Icons.delete, color: Colors.grey), onPressed: null);
    }
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () async {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Save Delete', textAlign: TextAlign.center),
              content: Text(
                saveName,
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              actions: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirm'),
                  onPressed: () async {
                    try {
                      Navigator.pop(context);
                      if (!context.mounted) return;
                      final gameState = context.read<GameState>();
                      final gameName = getFileName(gameState.gameList[gameState.gameIndex]);
                      final profileState = context.read<ProfileState>();
                      final profileName = getFileName(profileState.profileList[profileState.profileIndex]);
                      final saveFolder = profileState.folder;
                      final saveFile = profileState.file;
                      await saveDelete(
                        game: gameName,
                        profile: profileName,
                        saveFolder: saveFolder,
                        saveFile: saveFile,
                        save: saveName,
                      );
                      await _loadSaveList();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: ${e.toString()}')));
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDownloadButton(SaveState saveState) {
    final saveList = saveState.saveList;
    final saveIndex = saveState.saveIndex;
    final saveName = saveList.isEmpty ? '' : getFileName(saveList[saveIndex]);
    if (saveList.isEmpty) {
      return IconButton(icon: Icon(Icons.download, color: Colors.grey), onPressed: null);
    }
    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () async {
        final gameState = context.read<GameState>();
        final gameName = getFileName(gameState.gameList[gameState.gameIndex]);
        final profileState = context.read<ProfileState>();
        final profileName = getFileName(profileState.profileList[profileState.profileIndex]);
        final result = await saveDownload(game: gameName, profile: profileName, save: saveName);
        late String message;
        if ('NG' == result) {
          message = 'Download $saveName Failed';
        } else {
          message = 'Download $saveName Success';
        }
        if (!mounted) return;
        showTopSnackBar(
          Overlay.of(context),
          'NG' == result ? CustomSnackBar.error(message: message) : CustomSnackBar.success(message: message),
          displayDuration: Duration(milliseconds: 100),
        );
      },
    );
  }

  Widget _buildUploadButton(SaveState saveState) {
    return IconButton(
      icon: const Icon(Icons.upload),
      onPressed: () async {
        final gameState = context.read<GameState>();
        final gameName = getFileName(gameState.gameList[gameState.gameIndex]);
        final profileState = context.read<ProfileState>();
        final profileName = getFileName(profileState.profileList[profileState.profileIndex]);
        final result = await saveUpload(game: gameName, profile: profileName);
        late String message;
        if ('NG' == result) {
          message = 'Upload save to ${[gameName, profileName].join(pathSeparator)} Failed';
        } else {
          message = 'Upload save to ${[gameName, profileName].join(pathSeparator)} Sucess';
        }
        if (!mounted) return;
        showTopSnackBar(
          Overlay.of(context),
          'NG' == result ? CustomSnackBar.error(message: message) : CustomSnackBar.success(message: message),
          displayDuration: Duration(milliseconds: 100),
        );
        await Future.microtask(() async {
          await _loadSaveList(savePath: result);
        });
      },
    );
  }

  Widget _buildCommentContainer() {
    return SizedBox(
      height: _bottomInfoHeight,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
              readOnly: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveLoadContainer(SaveState saveState) {
    final saveList = saveState.saveList;
    final saveIndex = saveState.saveIndex;
    final saveName = saveList.isEmpty ? '' : getFileName(saveList[saveIndex]);
    final gameState = context.read<GameState>();
    final gameList = gameState.gameList;
    final gameIndex = gameState.gameIndex;
    final gameName = gameList.isEmpty ? '' : getFileName(gameList[gameIndex]);
    final profileState = context.read<ProfileState>();
    final profileList = profileState.profileList;
    final profileIndex = profileState.profileIndex;
    final profileName = profileList.isEmpty ? '' : getFileName(profileList[profileIndex]);
    final saveFolder = profileState.folder;
    final saveFile = profileState.file;
    return SizedBox(
      height: _bottomInfoHeight,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(_bottomInfoHeight * 0.9),
                backgroundColor: Colors.blue.shade100,
              ),
              icon: const Icon(Icons.save),
              label: const Text('Save', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final comment = _commentController.text;
                final result = await saveNew(
                  game: gameName,
                  profile: profileName,
                  saveFolder: saveFolder,
                  saveFile: saveFile,
                  comment: comment,
                );
                late String message;
                if ('NG' == result) {
                  message = 'Save from ${saveFolder.isEmpty ? saveFile : saveFolder} Failed';
                } else {
                  message = 'Save from ${saveFolder.isEmpty ? saveFile : saveFolder} Success';
                }
                if (!mounted) return;
                showTopSnackBar(
                  Overlay.of(context),
                  'NG' == result ? CustomSnackBar.error(message: message) : CustomSnackBar.success(message: message),
                  displayDuration: Duration(milliseconds: 100),
                );
                await Future.microtask(() async {
                  await _loadSaveList(savePath: result);
                });
              },
            ),
          ),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(_bottomInfoHeight * 0.9),
                backgroundColor: Colors.red.shade100,
              ),
              icon: const Icon(Icons.restore),
              label: const Text('Load', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final result = await saveLoad(
                  game: gameName,
                  profile: profileName,
                  saveFolder: saveFolder,
                  saveFile: saveFile,
                  save: saveName,
                );
                late String message;
                if ('OK' == result) {
                  message = 'Load save to ${saveFolder.isEmpty ? saveFile : saveFolder} Success';
                } else if ('NG' == result) {
                  message = 'Load save to ${saveFolder.isEmpty ? saveFile : saveFolder} Failed';
                }
                if (!mounted) return;
                showTopSnackBar(
                  Overlay.of(context),
                  'OK' == result ? CustomSnackBar.success(message: message) : CustomSnackBar.error(message: message),
                  displayDuration: Duration(milliseconds: 100),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
