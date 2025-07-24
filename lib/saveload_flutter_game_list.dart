import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'saveload_core.dart';
import 'saveload_core_common.dart';
import 'saveload_flutter_game_picker.dart';
import 'saveload_flutter_profile_list.dart';

class GameState extends ChangeNotifier {
  int _gameIndex = 0;
  int get gameIndex => _gameIndex;
  void setIndex(int index) {
    _gameIndex = index;
    notifyListeners();
  }

  List<String> _gameList = [];
  List<String> get gameList => _gameList;
  void updateList(List<String> gameList) {
    _gameList = gameList;
    if (_gameList.isEmpty) {
      _gameIndex = -1;
    } else if (_gameIndex >= gameList.length) {
      _gameIndex = gameList.isEmpty ? -1 : gameList.length - 1;
    } else if (_gameIndex < 0 && gameList.isNotEmpty) {
      _gameIndex = 0;
    }
    notifyListeners();
  }
}

class GameCenterSelectedList extends StatefulWidget {
  const GameCenterSelectedList({super.key});
  @override
  State<GameCenterSelectedList> createState() => _GameCenterSelectedListState();
}

class _GameCenterSelectedListState extends State<GameCenterSelectedList> {
  late final ScrollController _scrollController;
  final double _itemHeight = 80.0;
  final double _itemMarginHeight = 4.0;
  final double _itemSizedBoxHeight = 2.0;
  final double _bottomInfoHeight = 60.0;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadGameList();
  }

  Future<void> _loadGameList() async {
    setState(() => _isLoading = true);
    try {
      final gameState = context.read<GameState>();
      final gameList = await gameListFunc();
      Future.microtask(() {
        gameState.updateList(gameList);
        _scrollToIndex();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToIndex() {
    final gameState = context.read<GameState>();
    final gameIndex = gameState.gameIndex;
    if (gameIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (!mounted) return;
      final double itemMarginHeightLocal = _itemHeight + _itemMarginHeight * 2;
      final double targetPosition = gameIndex * itemMarginHeightLocal;
      final double screenHeight = MediaQuery.of(context).size.height;
      final double appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 56;
      final double availableHeight = screenHeight - appBarHeight - _bottomInfoHeight - _itemSizedBoxHeight * 2;
      final double centerPosition = targetPosition - (availableHeight - itemMarginHeightLocal) / 2;
      final double maxScroll = _scrollController.position.maxScrollExtent + itemMarginHeightLocal;
      final double minScroll = _scrollController.position.minScrollExtent;
      final double adjustedPosition = centerPosition.clamp(minScroll, maxScroll);
      _scrollController.animateTo(adjustedPosition, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Game List'),
            centerTitle: true,
            actions: [_buildRefreshButton(), _buildAddButton(), _buildDeleteButton(gameState)],
          ),
          body: Column(
            children: [
              Container(height: _itemSizedBoxHeight, color: Colors.blue),
              _isLoading ? Expanded(child: Center(child: CircularProgressIndicator())) : _buildGameListView(gameState),
              Container(height: _itemSizedBoxHeight, color: Colors.blue),
              _buildGameContainer(gameState),
            ],
          ),
          floatingActionButton: gameState.gameList.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    gameState.setIndex(0);
                    _scrollToIndex();
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
    super.dispose();
  }

  Widget _buildGameContainer(GameState gameState) {
    final gameIndex = gameState.gameIndex;
    final gameList = gameState.gameList;
    return Container(
      height: _bottomInfoHeight,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.blue.shade100, blurRadius: 10, spreadRadius: 2)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          gameList.isEmpty ? 'NO GAME' : getFileName(gameList[gameIndex]),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildGameListView(GameState gameState) {
    final gameIndex = gameState.gameIndex;
    final gameList = gameState.gameList;
    if (gameList.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.games, size: 64, color: Colors.grey.shade300),
              Text('No games available'),
              ElevatedButton(onPressed: _loadGameList, child: Text('Refresh list')),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemExtent: _itemHeight + _itemMarginHeight * 2,
        controller: _scrollController,
        itemCount: gameList.length,
        itemBuilder: (context, index) {
          final bool isSelected = index == gameIndex;
          return GestureDetector(
            key: ValueKey(gameList[index]),
            onTap: () async {
              gameState.setIndex(index);
              final gameName = getFileName(gameList[index]);
              final (profileList, folder, file) = await profileListFunc(gameName);
              Future.microtask(() {
                if (!context.mounted) return;
                final profileState = context.read<ProfileState>();
                profileState.updateList(profileList);
                profileState.setFolder(folder);
                profileState.setFile(file);
                _scrollToIndex();
              });
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
                  child: Text(getFileName(gameList[index]), textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRefreshButton() {
    return IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGameList);
  }

  Widget _buildAddButton() {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        await showDialog(
          context: context,
          builder: (context) => Dialog(
            insetPadding: EdgeInsets.all(10),
            child: Container(padding: EdgeInsets.all(10), child: GamePicker()),
          ),
        );
        await _loadGameList();
      },
    );
  }

  Widget _buildDeleteButton(GameState gameState) {
    final gameList = gameState.gameList;
    final gameIndex = gameState.gameIndex;
    final gameName = gameList.isEmpty ? '' : getFileName(gameList[gameIndex]);
    if (gameList.isEmpty) {
      return IconButton(icon: Icon(Icons.delete, color: Colors.grey), onPressed: null);
    }
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () async {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Game Delete', textAlign: TextAlign.center),
              content: Text(
                gameName,
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
                      await gameDelete(gameName);
                      await _loadGameList();
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
}
