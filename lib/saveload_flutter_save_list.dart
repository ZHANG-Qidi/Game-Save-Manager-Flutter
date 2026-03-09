import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'saveload_core.dart';
import 'saveload_core_common.dart';
import 'saveload_flutter_game_list.dart';
import 'saveload_flutter_profile_list.dart';

class SaveState extends ChangeNotifier {
  String get save {
    if (_saveList.isEmpty) return '';
    return _saveList[_saveIndex];
  }

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
  late final TextEditingController _renameController;
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
    _renameController = TextEditingController();
    _loadSaveList(save: 'NG');
  }

  Future<void> _loadSaveList({String save = ''}) async {
    setState(() => _isLoading = true);
    try {
      final saveState = context.read<SaveState>();
      final gameState = context.read<GameState>();
      final profileState = context.read<ProfileState>();
      final saveList = await saveListFunc(game: gameState.game, profile: profileState.profile);
      await Future.microtask(() async {
        saveState.updateList(saveList);
        await _loadSaveIndex(save);
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

  Future<void> _loadSaveIndex(String save) async {
    final saveState = context.read<SaveState>();
    final saveList = saveState.saveList;
    final comment = _commentController.text;
    int saveIndex = saveState.saveIndex;
    if (saveList.isEmpty) return;
    if ('NG' == save) return;
    final indexMap = {for (var i = 0; i < saveList.length; i++) saveList[i]: i};
    if (save.isNotEmpty) {
      saveIndex = indexMap[save] ?? -1;
      if (-1 == saveIndex) return;
    } else if (getComment(saveState.save) == comment) {
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
    String comment = '';
    if (saveState.save.isNotEmpty) {
      comment = getComment(saveState.save);
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
              _buildRenameButton(saveState),
              _buildSyncButton(saveState),
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
    _renameController.dispose();
    super.dispose();
  }

  Widget _buildSaveContainer(SaveState saveState) {
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
          saveState.save.isEmpty ? 'NO SAVE' : saveState.save,
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
                  child: Text(saveList[index], textAlign: TextAlign.center),
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
    final saveName = saveState.save;
    if (saveName.isEmpty) {
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
                      final profileState = context.read<ProfileState>();
                      final saveFolder = profileState.folder;
                      final saveFile = profileState.file;
                      await saveDelete(
                        game: gameState.game,
                        profile: profileState.profile,
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
    final saveName = saveState.save;
    if (saveName.isEmpty) {
      return IconButton(icon: Icon(Icons.download, color: Colors.grey), onPressed: null);
    }
    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () async {
        final gameState = context.read<GameState>();
        final gameName = gameState.game;
        final profileState = context.read<ProfileState>();
        final profileName = profileState.profile;
        final result = await saveDownload(game: gameName, profile: profileName, save: saveName);
        late String message;
        if ('NG' == result) {
          message = 'Download save from ${[gameName, profileName, saveName].join(pathSeparator)} Failed';
        } else {
          message = 'Download save from ${[gameName, profileName, saveName].join(pathSeparator)} Success';
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
        final gameName = gameState.game;
        final profileState = context.read<ProfileState>();
        final profileName = profileState.profile;
        final result = await saveUpload(game: gameName, profile: profileName);
        late String message;
        if ('NG' == result) {
          message = 'Upload save to ${[gameName, profileName].join(pathSeparator)} Failed';
        } else {
          message = 'Upload save to ${[gameName, profileName, result].join(pathSeparator)} Success';
        }
        if (!mounted) return;
        showTopSnackBar(
          Overlay.of(context),
          'NG' == result ? CustomSnackBar.error(message: message) : CustomSnackBar.success(message: message),
          displayDuration: Duration(milliseconds: 100),
        );
        await Future.microtask(() async {
          await _loadSaveList(save: result);
        });
      },
    );
  }

  bool containsWindowsInvalidChars(String name) {
    final invalidChars = RegExp(r'[<>:"/\\|?*@]');
    return invalidChars.hasMatch(name);
  }

  Widget _buildRenameButton(SaveState saveState) {
    final saveName = saveState.save;
    final commentOld = _commentController.text;
    if (saveName.isEmpty) {
      return IconButton(icon: Icon(Icons.edit, color: Colors.grey), onPressed: null);
    }
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () async {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Rename Save', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _renameController..text = commentOld,
                    decoration: const InputDecoration(labelText: 'Comment', border: OutlineInputBorder()),
                    textAlign: TextAlign.center,
                    maxLength: 50,
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  onPressed: () {
                    _renameController.clear();
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.drive_file_rename_outline),
                  label: const Text('Rename'),
                  onPressed: () async {
                    final commentNew = _renameController.text.trim();
                    final saveExtension = getFileExtension(saveName);
                    final savePrefix = getPrefix(saveName);
                    final newName = '$savePrefix${commentNew.isNotEmpty ? '@$commentNew' : ''}$saveExtension';
                    if (newName.isEmpty || newName == saveName) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Please enter a valid new name')));
                      }
                      return;
                    }
                    if (containsWindowsInvalidChars(commentNew)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid characters! Windows names cannot contain: < > : " / \\ | ? * @'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    try {
                      final gameState = context.read<GameState>();
                      final profileState = context.read<ProfileState>();
                      final saveFolder = profileState.folder;
                      final saveFile = profileState.file;
                      final result = await saveRename(
                        game: gameState.game,
                        profile: profileState.profile,
                        saveFolder: saveFolder,
                        saveFile: saveFile,
                        save: saveName,
                        name: newName,
                      );
                      await Future.microtask(() async {
                        await _loadSaveList(save: newName);
                      });
                      if (context.mounted) {
                        late String message;
                        if ('NG' == result) {
                          message = 'Renamed $saveName to: $newName Failed';
                        } else {
                          message = 'Renamed $saveName to: $newName Success';
                        }
                        showTopSnackBar(
                          Overlay.of(context),
                          'NG' == result ? CustomSnackBar.error(message: message) : CustomSnackBar.success(message: message),
                          displayDuration: Duration(milliseconds: 100),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rename failed: ${e.toString()}')));
                      }
                    } finally {
                      _renameController.clear();
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

  Widget _buildSyncButton(SaveState saveState) {
    final saveName = saveState.save;
    if (saveName.isEmpty) {
      return IconButton(icon: Icon(Icons.sync, color: Colors.grey), onPressed: null);
    }
    return IconButton(
      icon: const Icon(Icons.sync),
      onPressed: () async {
        showDialog(
          context: context,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        final mDNSServerList = await listMdnsServer();
        if (!mounted) return;
        Navigator.pop(context);
        try {
          final selectedServer = await _showStringListDialog(context: context, stringList: mDNSServerList);
          if (selectedServer != null) {
            Map<String, dynamic> jsonMap = jsonDecode(selectedServer);
            final String host = jsonMap['host'] ?? 'Unknown';
            final String ipv4 = jsonMap['ipv4'] ?? 'Unknown';
            final String port = jsonMap['port'] ?? 'Unknown';
            if (!mounted) return;
            final gameState = context.read<GameState>();
            final profileState = context.read<ProfileState>();
            final result = await syncSaveToReceiver(
              game: gameState.game,
              profile: profileState.profile,
              save: saveName,
              url: ipv4,
              port: port,
            );
            late String message;
            if ('NG' == result) {
              message = 'Sync $saveName to: $host ($ipv4) Failed';
            } else {
              message = 'Sync $saveName to: $host ($ipv4) Success';
            }
            if (!mounted) return;
            showTopSnackBar(
              Overlay.of(context),
              'NG' == result ? CustomSnackBar.error(message: message) : CustomSnackBar.success(message: message),
              displayDuration: Duration(milliseconds: 100),
            );
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: ${e.toString()}')));
        }
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
    final gameState = context.read<GameState>();
    final gameName = gameState.game;
    final profileState = context.read<ProfileState>();
    final profileName = profileState.profile;
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
                  await _loadSaveList(save: result);
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
                  save: saveState.save,
                );
                late String message;
                if ('NG' == result) {
                  message = 'Load save to ${saveFolder.isEmpty ? saveFile : saveFolder} Failed';
                } else {
                  message = 'Load save to ${saveFolder.isEmpty ? saveFile : saveFolder} Success';
                }
                if (!mounted) return;
                showTopSnackBar(
                  Overlay.of(context),
                  'NG' == result ? CustomSnackBar.error(message: message) : CustomSnackBar.success(message: message),
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

class StringListDialog extends StatefulWidget {
  final List<String> stringList;
  const StringListDialog({super.key, required this.stringList});
  @override
  State<StringListDialog> createState() => _StringListDialogState();
}

class _StringListDialogState extends State<StringListDialog> {
  String? _selectedItem;
  bool _selectedFlag = false;
  late TextEditingController _textController;
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    if (_selectedItem != null) {
      Navigator.of(context).pop(_selectedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        appBar: AppBar(title: Text('Sync Save'), backgroundColor: Theme.of(context).appBarTheme.backgroundColor),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: widget.stringList.isEmpty
                    ? const Center(child: Text('No Server to display'))
                    : ListView.builder(
                        itemCount: widget.stringList.length,
                        itemBuilder: (context, index) {
                          final item = widget.stringList[index];
                          return _buildListItem(context, item);
                        },
                      ),
              ),
              const SizedBox(height: 8),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String item) {
    final isSelected = _selectedFlag && _selectedItem == item;
    Map<String, dynamic> jsonMap = jsonDecode(item);
    final String host = jsonMap['host'] ?? 'Unknown';
    final String ipv4 = jsonMap['ipv4'] ?? 'Unknown';
    final String port = jsonMap['port'] ?? 'Unknown';
    return SmartTapWidget(
      onSingleTap: () {
        setState(() {
          _selectedItem = item;
          _selectedFlag = true;
          _textController.text = '$host ($ipv4:$port)';
        });
      },
      onDoubleTap: () {
        setState(() {
          _selectedItem = item;
          _selectedFlag = true;
          _textController.text = '$host ($ipv4:$port)';
        });
        _confirmSelection();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 2.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.purple.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.shade200, blurRadius: 10, spreadRadius: 2)] : null,
        ),
        child: ListTile(
          leading: const Icon(Icons.computer, color: Colors.blueGrey, size: 32),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 100),
            style: TextStyle(
              fontSize: isSelected ? 18 : 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black,
            ),
            child: Text(host),
          ),
          subtitle: Text('$ipv4:$port'),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Server',
            suffixIcon: _selectedItem != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _selectedItem = null;
                      _selectedFlag = false;
                      _textController.clear();
                    }),
                  )
                : null,
          ),
          readOnly: true,
          controller: _textController,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.sync),
                label: Text('Sync'),
                onPressed: _selectedItem != null
                    ? () {
                        _confirmSelection();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SmartTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onSingleTap;
  final VoidCallback onDoubleTap;
  final Duration doubleTapThreshold;
  const SmartTapWidget({
    super.key,
    required this.child,
    required this.onSingleTap,
    required this.onDoubleTap,
    this.doubleTapThreshold = const Duration(milliseconds: 300),
  });
  @override
  State<SmartTapWidget> createState() => _SmartTapWidgetState();
}

class _SmartTapWidgetState extends State<SmartTapWidget> {
  DateTime? _lastTapTime;
  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) <= widget.doubleTapThreshold) {
      widget.onDoubleTap();
    } else {
      widget.onSingleTap();
    }
    _lastTapTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(behavior: HitTestBehavior.translucent, onTap: _handleTap, child: widget.child);
  }
}

Future<String?> _showStringListDialog({required BuildContext context, required List<String> stringList}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: StringListDialog(stringList: stringList),
      ),
    ),
  );
}
