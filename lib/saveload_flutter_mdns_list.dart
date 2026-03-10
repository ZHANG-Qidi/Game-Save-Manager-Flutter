import 'dart:convert';
import 'package:flutter/material.dart';
import 'saveload_flutter_common.dart';

class MdnsBrowserDialog extends StatefulWidget {
  final List<String> stringList;
  const MdnsBrowserDialog({super.key, required this.stringList});
  @override
  State<MdnsBrowserDialog> createState() => _MdnsBrowserDialogState();
}

class _MdnsBrowserDialogState extends State<MdnsBrowserDialog> {
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
