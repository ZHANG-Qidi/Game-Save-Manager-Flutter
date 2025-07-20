import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'saveload_core_common.dart';
import 'saveload_core_desktop.dart';
import 'saveload_flutter_game_list.dart';

class GamePicker extends StatefulWidget {
  const GamePicker({super.key});
  @override
  State<GamePicker> createState() => _GamePickerState();
}

class _GamePickerState extends State<GamePicker> {
  final TextEditingController _folderController = TextEditingController();
  final TextEditingController _fileController = TextEditingController();
  final TextEditingController _gameController = TextEditingController();
  String? _lastPickerPath;
  String? _getAppDataPath() {
    if (Platform.isWindows) {
      return Platform.environment['APPDATA'];
    } else if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/Library/Application Support';
    } else if (Platform.isLinux) {
      return Platform.environment['HOME'];
    }
    return null;
  }

  Future<void> _pickFolder() async {
    final initialDirectory = _lastPickerPath ?? _getAppDataPath();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(initialDirectory: initialDirectory);
    if (selectedDirectory != null) {
      setState(() {
        _folderController.text = selectedDirectory;
        _lastPickerPath = selectedDirectory;
        _fileController.text = '';
        _gameController.text = getFileName(selectedDirectory);
      });
    }
  }

  Future<void> _pickFile() async {
    final initialDirectory = _lastPickerPath ?? _getAppDataPath();
    FilePickerResult? result = await FilePicker.platform.pickFiles(initialDirectory: initialDirectory);
    if (result != null) {
      final filePath = result.files.single.path;
      if (filePath != null) {
        setState(() {
          _fileController.text = filePath;
          _lastPickerPath = File(filePath).parent.path;
          _folderController.text = '';
          _gameController.text = path.basenameWithoutExtension(filePath);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_gameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Game name is required')));
      return;
    }
    if (_folderController.text.isEmpty && _fileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select either folder or file')));
      return;
    }
    await gameNew(game: _gameController.text, saveFolder: _folderController.text, saveFile: _fileController.text);
    final gameList = await gameListFunc();
    if (!mounted) return;
    final gameState = context.read<GameState>();
    gameState.updateList(gameList);
    gameState.setIndex(gameList.indexOf(['SaveLoad', _gameController.text].join(Platform.pathSeparator)));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _folderController.dispose();
    _fileController.dispose();
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        appBar: AppBar(title: const Text('Game Picker')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameNameField(),
              const SizedBox(height: 30),
              _buildFolderPickerRow(),
              const SizedBox(height: 30),
              _buildFilePickerRow(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameNameField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _gameController,
            decoration: const InputDecoration(
              labelText: 'Game Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.gamepad),
            ),
            readOnly: false,
          ),
        ),
      ],
    );
  }

  Widget _buildFolderPickerRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _folderController,
            decoration: const InputDecoration(
              labelText: 'Folder Path',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 150,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('Folder Picker'),
            onPressed: _pickFolder,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePickerRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _fileController,
            decoration: const InputDecoration(
              labelText: 'File Path',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.insert_drive_file),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 150,
          child: ElevatedButton.icon(icon: const Icon(Icons.file_open), label: const Text('File Picker'), onPressed: _pickFile),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(icon: const Icon(Icons.check_circle), label: const Text('OK'), onPressed: _submitForm),
        ),
      ],
    );
  }
}
