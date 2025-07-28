import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'saveload_core.dart';
import 'saveload_flutter_game_list.dart';
import 'saveload_flutter_profile_list.dart';

class ProfilePicker extends StatefulWidget {
  const ProfilePicker({super.key});
  @override
  State<ProfilePicker> createState() => _ProfilePickerState();
}

class _ProfilePickerState extends State<ProfilePicker> {
  final TextEditingController _profileController = TextEditingController();
  Future<void> _submitForm() async {
    if (_profileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile name is required')));
      return;
    }
    if (!context.mounted) return;
    final gameState = context.read<GameState>();
    final gameName = gameState.game;
    await profileNew(game: gameName, profile: _profileController.text);
    final (profileList, folder, file) = await profileListFunc(gameName);
    if (!mounted) return;
    final profileState = context.read<ProfileState>();
    profileState.updateList(profileList);
    profileState.setIndex(profileList.indexOf(_profileController.text));
    profileState.setFolder(folder);
    profileState.setFile(file);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile Picker')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_buildProfileNameField(), const SizedBox(height: 30), _buildSubmitButton()],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNameField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _profileController,
            decoration: const InputDecoration(
              labelText: 'Profile Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_box),
            ),
            readOnly: false,
          ),
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
