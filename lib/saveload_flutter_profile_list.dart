import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'saveload_core.dart';
import 'saveload_core_common.dart';
import 'saveload_flutter_game_list.dart';
import 'saveload_flutter_profile_picker.dart';

class ProfileState extends ChangeNotifier {
  int _profileIndex = 0;
  int get profileIndex => _profileIndex;
  void setIndex(int index) {
    _profileIndex = index;
    notifyListeners();
  }

  List<String> _profileList = [];
  List<String> get profileList => _profileList;
  void updateList(List<String> profileList) {
    _profileList = profileList;
    if (_profileList.isEmpty) {
      _profileIndex = -1;
    } else if (_profileIndex >= profileList.length) {
      _profileIndex = profileList.isEmpty ? -1 : profileList.length - 1;
    } else if (_profileIndex < 0 && profileList.isNotEmpty) {
      _profileIndex = 0;
    }
    notifyListeners();
  }

  String _folder = '';
  String get folder => _folder;
  void setFolder(String folder) {
    _folder = folder;
    notifyListeners();
  }

  String _file = '';
  String get file => _file;
  void setFile(String file) {
    _file = file;
    notifyListeners();
  }
}

class ProfileCenterSelectedList extends StatefulWidget {
  const ProfileCenterSelectedList({super.key});
  @override
  State<ProfileCenterSelectedList> createState() => _ProfileCenterSelectedListState();
}

class _ProfileCenterSelectedListState extends State<ProfileCenterSelectedList> {
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
    _loadProfileList();
  }

  Future<void> _loadProfileList() async {
    setState(() => _isLoading = true);
    try {
      final profileState = context.read<ProfileState>();
      final gameState = context.read<GameState>();
      final gameList = gameState.gameList;
      final gameIndex = gameState.gameIndex;
      final gameName = getFileName(gameList[gameIndex]);
      final (profileList, folder, file) = await profileListFunc(gameName);
      Future.microtask(() {
        profileState.updateList(profileList);
        profileState.setFolder(folder);
        profileState.setFile(file);
        _scrollToIndex();
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToIndex() {
    final profileState = context.read<ProfileState>();
    final profileIndex = profileState.profileIndex;
    if (profileIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (!context.mounted) return;
      final double itemMarginHeightLocal = _itemHeight + _itemMarginHeight * 2;
      final double targetPosition = profileIndex * itemMarginHeightLocal;
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
    return Consumer<ProfileState>(
      builder: (context, profileState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile List'),
            centerTitle: true,
            actions: [_buildRefreshButton(), _buildAddButton(), _buildDeleteButton(profileState)],
          ),
          body: Column(
            children: [
              Container(height: _itemSizedBoxHeight, color: Colors.blue),
              _isLoading ? Expanded(child: Center(child: CircularProgressIndicator())) : _buildProfileListView(profileState),
              Container(height: _itemSizedBoxHeight, color: Colors.blue),
              _buildProfileContainer(profileState),
            ],
          ),
          floatingActionButton: profileState.profileList.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    profileState.setIndex(0);
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

  Widget _buildProfileContainer(ProfileState profileState) {
    final profileIndex = profileState.profileIndex;
    final profileList = profileState.profileList;
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
          profileList.isEmpty ? 'NO PROFILE' : getFileName(profileList[profileIndex]),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildProfileListView(ProfileState profileState) {
    final profileIndex = profileState.profileIndex;
    final profileList = profileState.profileList;
    if (profileList.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_box, size: 64, color: Colors.grey.shade300),
              Text('No profile available'),
              ElevatedButton(onPressed: _loadProfileList, child: Text('Refresh list')),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemExtent: _itemHeight + _itemMarginHeight * 2,
        controller: _scrollController,
        itemCount: profileList.length,
        itemBuilder: (context, index) {
          final bool isSelected = index == profileIndex;
          return GestureDetector(
            key: ValueKey(profileList[index]),
            onTap: () {
              profileState.setIndex(index);
              _scrollToIndex();
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
                  child: Text(getFileName(profileList[index]), textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRefreshButton() {
    return IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfileList);
  }

  Widget _buildAddButton() {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        await showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Container(padding: EdgeInsets.all(20), child: ProfilePicker()),
          ),
        );
        await _loadProfileList();
      },
    );
  }

  Widget _buildDeleteButton(ProfileState profileState) {
    final profileIndex = profileState.profileIndex;
    final profileList = profileState.profileList;
    final profileName = profileList.isEmpty ? '' : getFileName(profileList[profileIndex]);
    if (profileList.isEmpty) {
      return IconButton(icon: Icon(Icons.delete, color: Colors.grey), onPressed: null);
    }
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () async {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Profile Delete', textAlign: TextAlign.center),
              content: Text(
                profileName,
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
                      await profileDelete(game: gameName, profile: profileName);
                      await _loadProfileList();
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
