import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class FileViewer extends StatefulWidget {
  final String category;
  final MethodChannel platform;
  const FileViewer({super.key, required this.category, required this.platform});

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  List<Map<dynamic, dynamic>> _files = [];
  bool _isLoading = true;

  bool _isSelectionMode = false;
  final Set<String> _selectedPaths = {};

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> result = await widget.platform.invokeMethod(
        'getFilesInCategory',
        {"category": widget.category.toLowerCase()},
      );
      if (mounted) {
        setState(() {
          _files = result.cast<Map<dynamic, dynamic>>();
          _selectedPaths.clear();
          _isSelectionMode = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedPaths.clear();
    });
  }

  void _toggleFileSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedPaths.isEmpty) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Files"),
          content: Text(
            "Are you sure you want to delete ${_selectedPaths.length} items?",
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "DELETE",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await widget.platform.invokeMethod("deleteFiles", {
          "category": widget.category.toLowerCase(),
          "paths": _selectedPaths.toList(),
        });
        // Reload list after deletion
        _fetchFiles();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error deleting files: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isGrid =
        widget.category.toLowerCase() == "images" ||
        widget.category.toLowerCase() == "videos";

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? "${_selectedPaths.length} Selected"
              : "Viewing ${widget.category}",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _toggleSelectionMode,
              )
            : const BackButton(),
        actions: [
          if (_isSelectionMode && _selectedPaths.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              onPressed: _deleteSelected,
            )
          else if (!_isSelectionMode && _files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? const Center(child: Text("No files found in this category."))
          : isGrid
          ? _buildGridView()
          : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        bool isImage = widget.category.toLowerCase() == "images";
        String path = file['path'] ?? "";
        bool isSelected = _selectedPaths.contains(path);

        return GestureDetector(
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
              });
              _toggleFileSelection(path);
            }
          },
          onTap: () {
            if (_isSelectionMode) {
              _toggleFileSelection(path);
            } else {
              // Normal tap action (e.g. open file fullscreen) could go here
              setState(() {
                _isSelectionMode = true;
              });
              _toggleFileSelection(path);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: Colors.blueAccent, width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                        child: Container(
                          width: double.infinity,
                          color: Colors.black12,
                          child: isImage
                              ? Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  cacheWidth: 200, // Important for memory
                                  errorBuilder: (context, e, s) =>
                                      const Icon(Icons.broken_image_rounded),
                                )
                              : VideoThumbnailWidget(videoPath: path),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file['name'] ?? "Unknown",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${(file['size'] / (1024 * 1024)).toStringAsFixed(1)} MB",
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        bool isApps = widget.category.toLowerCase() == "apps";
        String path = file['path'] ?? "";
        String? base64Icon = file['icon'];
        bool isSelected = _selectedPaths.contains(path);

        return GestureDetector(
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
              });
              _toggleFileSelection(path);
            }
          },
          onTap: () {
            if (_isSelectionMode) {
              _toggleFileSelection(path);
            } else {
              setState(() {
                _isSelectionMode = true;
              });
              _toggleFileSelection(path);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent.withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: Colors.blueAccent, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: isSelected
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
            ),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? Colors.blueAccent : Colors.black26,
                    ),
                  ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isApps && base64Icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(
                              base64Icon.replaceAll(RegExp(r'\s+'), ''),
                            ),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          isApps
                              ? Icons.apps_rounded
                              : Icons.description_rounded,
                          color: isApps ? Colors.purple : Colors.green,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file['name'] ?? "Unknown",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${(file['size'] / (1024 * 1024)).toStringAsFixed(1)} MB",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isSelectionMode)
                  const Icon(Icons.more_vert_rounded, color: Colors.black26),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VideoThumbnailWidget extends StatelessWidget {
  final String videoPath;
  const VideoThumbnailWidget({super.key, required this.videoPath});

  Future<String?> _getThumbnail() async {
    final tempDir = await getTemporaryDirectory();
    final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 200,
      quality: 50,
    );
    return thumbnailPath;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Image.file(File(snapshot.data!), fit: BoxFit.cover);
        }
        return const Center(
          child: Icon(
            Icons.play_circle_filled_rounded,
            color: Colors.white70,
            size: 40,
          ),
        );
      },
    );
  }
}
