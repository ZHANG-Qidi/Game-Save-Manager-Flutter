import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'saveload_core_common.dart';
import 'saveload_flutter_game_list.dart';
import 'saveload_flutter_profile_list.dart';
import 'saveload_flutter_save_list.dart';
import 'saveload_flutter_file_system.dart';

void main() async {
  await initPathSeparator();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameState()),
        ChangeNotifierProvider(create: (context) => ProfileState()),
        ChangeNotifierProvider(create: (context) => SaveState()),
        ChangeNotifierProvider(create: (context) => FileSystemState()),
      ],
      child: MaterialApp(
        title: 'Game-Save-Manager-Flutter',
        theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
        home: MyHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final profileState = Provider.of<ProfileState>(context);
    final bool gameStateEnabled = gameState.gameList.isNotEmpty;
    final bool profileStateEnabled = profileState.profileList.isNotEmpty;
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GameCenterSelectedList();
        break;
      case 1:
        page = ProfileCenterSelectedList();
        break;
      case 2:
        page = SaveCenterSelectedList();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(icon: Icon(Icons.gamepad), label: Text('Game')),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_box, color: gameStateEnabled ? null : Colors.grey),
                      label: Text('Profile'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_tree, color: (gameStateEnabled && profileStateEnabled) ? null : Colors.grey),
                      label: Text('Save'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    if (1 == value && !gameStateEnabled) {
                      return;
                    }
                    if (2 == value && !(gameStateEnabled && profileStateEnabled)) {
                      return;
                    }
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(color: Theme.of(context).colorScheme.primaryContainer, child: page),
              ),
            ],
          ),
        );
      },
    );
  }
}
