import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'saveload_core.dart';
import 'saveload_core_common.dart';

class FileSystemState with ChangeNotifier {
  List<String> _folders = [];
  void setFolders(List<String> folder) {
    _folders = folder;
    notifyListeners();
  }

  List<String> _files = [];
  void setFiles(List<String> files) {
    _files = files;
    notifyListeners();
  }

  String _path = '';
  String get path => _path;
  void setPath(String path) {
    _path = path;
    notifyListeners();
  }

  String _folderSelected = '';
  String get folderSelected => _folderSelected;
  void setFolderSelected(String folder) {
    _folderSelected = folder;
  }

  String _fileSelected = '';
  String get fileSelected => _fileSelected;
  void setFileSelected(String folder) {
    _fileSelected = folder;
  }

  PathItem get pathFolder {
    return PathItem(path: _path, isFolder: true, displayName: getFileName(_path));
  }

  List<PathItem> get folderItems {
    return _folders
        .map((folderPath) => PathItem(path: folderPath, isFolder: true, displayName: getFileName(folderPath)))
        .toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  }

  List<PathItem> get fileItems {
    return _files
        .map(
          (filePath) => PathItem(
            path: filePath,
            isFolder: false,
            displayName: getFileName(filePath),
            fileExtension: getExtension(filePath).toLowerCase(),
          ),
        )
        .toList()
      ..sort((a, b) {
        final typeCompare = a.fileExtension.compareTo(b.fileExtension);
        if (typeCompare != 0) return typeCompare;
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });
  }
}

class PathItem {
  final String path;
  final bool isFolder;
  final String displayName;
  final String fileExtension;
  PathItem({required this.path, required this.isFolder, required this.displayName, this.fileExtension = ''});
}

class FileBrowserDialog extends StatefulWidget {
  final bool isFolderMode;
  const FileBrowserDialog({super.key, required this.isFolderMode});
  @override
  State<FileBrowserDialog> createState() => _FileBrowserDialogState();
}

class _FileBrowserDialogState extends State<FileBrowserDialog> {
  PathItem? _selectedItem;
  bool showDrivePicker = false;
  List<String> drives = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    initContents();
  }

  Future<void> loadFileSystem(String path) async {
    setState(() => _isLoading = true);
    try {
      final fileSystemState = context.read<FileSystemState>();
      final folders = await listDirectorySubDirectories(path);
      final files = await listDirectoryFiles(path);
      await Future.microtask(() {
        fileSystemState.setPath(path);
        fileSystemState.setFolders(folders);
        fileSystemState.setFiles(files);
        if (widget.isFolderMode) {
          _selectedItem = fileSystemState.pathFolder;
        } else {
          _selectedItem = null;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> initContents() async {
    setState(() => _isLoading = true);
    try {
      drives = await getRootDirectory();
      if (!mounted) return;
      final path = await getAppDataPath();
      await loadFileSystem(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> loadFolder(FileSystemState fileSystemState) async {
    setState(() => showDrivePicker = false);
    final path = _selectedItem!.path;
    await loadFileSystem(path);
  }

  Future<void> loadFolderParent(FileSystemState fileSystemState) async {
    if (drives.contains(fileSystemState.path)) {
      setState(() => showDrivePicker = true);
      return;
    }
    final path = getDirname(fileSystemState.path);
    await loadFileSystem(path);
  }

  Future<void> _switchDrive(FileSystemState fileSystemState, String newDrive) async {
    setState(() => showDrivePicker = false);
    final path = newDrive;
    await loadFileSystem(path);
  }

  @override
  Widget build(BuildContext context) {
    final fileSystemState = Provider.of<FileSystemState>(context);
    final items = widget.isFolderMode
        ? fileSystemState.folderItems
        : [...fileSystemState.folderItems, ...fileSystemState.fileItems];
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isFolderMode ? 'Select folder' : 'Select file')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (showDrivePicker) _buildDriveSelector(fileSystemState),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 28),
                    color: Theme.of(context).primaryColor,
                    onPressed: () async {
                      await loadFolderParent(fileSystemState);
                    },
                    tooltip:
                        'Up to "${getFileName(fileSystemState.path).isEmpty ? pathSeparator : getFileName(fileSystemState.path)}"',
                    style: IconButton.styleFrom(backgroundColor: Colors.blue.shade50, padding: const EdgeInsets.all(0)),
                  ),
                  SizedBox(width: 8),
                  Expanded(child: _buildParentPathDisplay(fileSystemState)),
                ],
              ),
              const SizedBox(height: 8),
              _isLoading
                  ? Expanded(child: Center(child: CircularProgressIndicator()))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildListItem(context, item, fileSystemState);
                        },
                      ),
                    ),
              const SizedBox(height: 8),
              _buildBottomControls(fileSystemState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentPathDisplay(FileSystemState fileSystemState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mirrorPath(fileSystemState.path),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(FileSystemState fileSystemState) {
    final isOpenEnabled = _selectedItem != null && _selectedItem!.isFolder;
    final isSelectEnabled = widget.isFolderMode
        ? (_selectedItem != null && _selectedItem!.isFolder)
        : (_selectedItem != null && !_selectedItem!.isFolder);
    return Column(
      children: [
        _textBoxFolderOrFile(isOpenEnabled),
        const SizedBox(height: 4),
        _buttonOpen(fileSystemState, isOpenEnabled),
        const SizedBox(height: 4),
        _buttonSelect(fileSystemState, isSelectEnabled, isOpenEnabled),
      ],
    );
  }

  Widget _textBoxFolderOrFile(bool isOpenEnabled) {
    return TextField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: _selectedItem != null ? (isOpenEnabled ? 'Folder' : 'File') : 'Select Folder or File',
        suffixIcon: _selectedItem != null
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _selectedItem = null))
            : null,
      ),
      readOnly: true,
      controller: TextEditingController(text: _selectedItem?.displayName ?? ''),
    );
  }

  Widget _buttonOpen(FileSystemState fileSystemState, bool isOpenEnabled) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
            onPressed: isOpenEnabled && _selectedItem!.path != fileSystemState.pathFolder.path
                ? () => loadFolder(fileSystemState)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buttonSelect(FileSystemState fileSystemState, bool isSelectEnabled, bool isOpenEnabled) {
    final selectButtonText = widget.isFolderMode ? 'Select Folder' : 'Select File';
    final selectButtonIcon = widget.isFolderMode ? Icons.folder : Icons.file_open;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(selectButtonIcon),
            label: Text(selectButtonText),
            onPressed: isSelectEnabled
                ? () {
                    if (isOpenEnabled) {
                      fileSystemState.setFolderSelected(_selectedItem!.path);
                      fileSystemState.setFileSelected('');
                    } else {
                      fileSystemState.setFolderSelected('');
                      fileSystemState.setFileSelected(_selectedItem!.path);
                    }
                    Navigator.of(context).pop();
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, PathItem item, FileSystemState fileSystemState) {
    final isSelected = _selectedItem != null ? _selectedItem!.path == item.path : false;
    return SmartTapWidget(
      onSingleTap: () async {
        setState(() {
          _selectedItem = item;
        });
      },
      onDoubleTap: () async {
        _selectedItem = item;
        if (item.isFolder) {
          await loadFolder(fileSystemState);
        } else if (!widget.isFolderMode && !item.isFolder) {
          fileSystemState.setFolderSelected('');
          fileSystemState.setFileSelected(_selectedItem!.path);
          Navigator.of(context).pop();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(vertical: 2.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.purple.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.shade200, blurRadius: 10, spreadRadius: 2)] : null,
        ),
        child: ListTile(
          leading: item.isFolder ? const Icon(Icons.folder, color: Colors.amber, size: 32) : _getFileIcon(item.path, 32),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 100),
            style: TextStyle(
              fontSize: isSelected ? 18 : 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black,
            ),
            child: Text(item.displayName),
          ),
        ),
      ),
    );
  }

  Icon _getFileIcon(String filePath, double size) {
    final extension = getExtension(filePath).toLowerCase();
    switch (extension) {
      case '.pdf':
        return Icon(Icons.picture_as_pdf, color: Colors.red, size: size);
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icon(Icons.image, color: Colors.amber, size: size);
      case '.mp3':
      case '.wav':
      case '.flac':
        return Icon(Icons.audiotrack, color: Colors.green, size: size);
      case '.txt':
      case '.md':
        return Icon(Icons.text_snippet, color: Colors.blueGrey, size: size);
      case '.exe':
      case '.msi':
        return Icon(Icons.adb, color: Colors.blue, size: size);
      case '.zip':
      case '.rar':
      case '.7z':
        return Icon(Icons.archive, color: Colors.orange, size: size);
      default:
        return Icon(Icons.insert_drive_file, size: size);
    }
  }

  Widget _buildDriveSelector(FileSystemState fileSystemState) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: drives.map((drive) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChoiceChip(
              label: Text(drive),
              selected: fileSystemState.path == drive,
              onSelected: (selected) async {
                await _switchDrive(fileSystemState, drive);
              },
            ),
          );
        }).toList(),
      ),
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
