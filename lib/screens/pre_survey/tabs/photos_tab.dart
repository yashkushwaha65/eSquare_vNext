// lib/screens/pre_survey/tabs/photos_tab.dart
import 'dart:io';

import 'package:esquare/core/models/photoMdl.dart';
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class PhotosTab extends StatefulWidget {
  const PhotosTab({super.key});

  @override
  State<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<PhotosTab> {
  String? _selectedPosition;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onPositionChanged(String? newValue) {
    setState(() {
      _selectedPosition = newValue;
    });
  }

  // MODIFIED: This now shows the enhanced dialog for a GROUP of photos.
  void _showEditPhotoGroupDialog(
    BuildContext context,
    PreGateInProvider provider,
    String docName,
    List<Photo> photoGroup,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EditPhotoGroupDialog(provider: provider, photoGroup: photoGroup),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreGateInProvider>(
      builder: (context, provider, child) {
        // Group photos by their `docName` (Container Position)
        final groupedPhotos = <String, List<Photo>>{};
        for (var photo in provider.photos) {
          (groupedPhotos[photo.docName] ??= []).add(photo);
        }

        final canAddNewPhotos =
            provider.photos.length < PreGateInProvider.maxPhotos;
        final areFieldsFilled =
            _selectedPosition != null && _descriptionController.text.isNotEmpty;
        final canUpload = canAddNewPhotos && areFieldsFilled;

        if (provider.isProcessingImage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/anims/loading.json',
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 16),
                const Text('Processing Image...'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section for adding NEW photos ---
              const Text(
                'Add New Photos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add up to ${PreGateInProvider.maxPhotos} photos in total. You have added ${provider.photos.length}.',
                style: TextStyle(
                  color: canAddNewPhotos ? Colors.grey.shade700 : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              IgnorePointer(
                ignoring: !canAddNewPhotos,
                child: Opacity(
                  opacity: canAddNewPhotos ? 1.0 : 0.5,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'Container Position',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        hint: const Text('Choose a position...'),
                        items: provider.docTypes.map<DropdownMenuItem<String>>((
                          doc,
                        ) {
                          return DropdownMenuItem<String>(
                            value: doc['Type']?.toString(),
                            child: Text(
                              doc['Type']?.toString() ?? 'Invalid Type',
                            ),
                          );
                        }).toList(),
                        onChanged: _onPositionChanged,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                        ),
                        maxLines: 3,
                        onChanged: (text) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImagePickerButton(
                              context: context,
                              provider: provider,
                              source: ImageSource.gallery,
                              iconAsset: 'assets/icons/imagefull.svg',
                              isEnabled: canUpload,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildImagePickerButton(
                              context: context,
                              provider: provider,
                              source: ImageSource.camera,
                              iconAsset: 'assets/icons/camerafull.svg',
                              isEnabled: canUpload,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 48),

              // --- Section for displaying and editing EXISTING photos ---
              const Text(
                'Uploaded Photos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (groupedPhotos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('No photos uploaded yet.'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groupedPhotos.keys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final docName = groupedPhotos.keys.elementAt(index);
                    final photoGroup = groupedPhotos[docName]!;
                    final firstPhoto = photoGroup.first;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        docName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        firstPhoto.description,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showEditPhotoGroupDialog(
                                    context,
                                    provider,
                                    docName,
                                    photoGroup,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: photoGroup.length,
                                itemBuilder: (ctx, idx) {
                                  final photo = photoGroup[idx];
                                  final isNetworkImage = photo.url.startsWith(
                                    'http',
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: isNetworkImage
                                          ? Image.network(
                                              photo.url,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(photo.url),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerButton({
    required BuildContext context,
    required PreGateInProvider provider,
    required ImageSource source,
    required String iconAsset,
    required bool isEnabled,
  }) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 50,
        child: IconButton(
          icon: SvgPicture.asset(iconAsset),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: !isEnabled
              ? null
              : () async {
                  await provider.pickAndProcessImages(
                    context,
                    source,
                    _selectedPosition!,
                    _descriptionController.text,
                  );
                  if (mounted) {
                    setState(() {
                      _descriptionController.clear();
                      _selectedPosition = null;
                    });
                  }
                },
        ),
      ),
    );
  }
}

// ADDED: The new, enhanced dialog widget.
class EditPhotoGroupDialog extends StatefulWidget {
  final PreGateInProvider provider;
  final List<Photo> photoGroup;

  const EditPhotoGroupDialog({
    super.key,
    required this.provider,
    required this.photoGroup,
  });

  @override
  State<EditPhotoGroupDialog> createState() => _EditPhotoGroupDialogState();
}

class _EditPhotoGroupDialogState extends State<EditPhotoGroupDialog> {
  late final TextEditingController _descriptionController;
  late String? _selectedPosition;
  late String _originalPosition;

  @override
  void initState() {
    super.initState();
    final firstPhoto = widget.photoGroup.first;
    _originalPosition = firstPhoto.docName;
    _selectedPosition = firstPhoto.docName;
    _descriptionController = TextEditingController(
      text: firstPhoto.description,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAddMorePhotos =
        widget.provider.photos.length < PreGateInProvider.maxPhotos;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Photo Group',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              // Form and Photos
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Form Fields
                    DropdownButtonFormField<String>(
                      value: _selectedPosition,
                      decoration: const InputDecoration(
                        labelText: 'Container Position',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.provider.docTypes
                          .map<DropdownMenuItem<String>>(
                            (doc) => DropdownMenuItem<String>(
                              value: doc['Type']?.toString(),
                              child: Text(
                                doc['Type']?.toString() ?? 'Invalid Type',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedPosition = val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Photo Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount:
                          widget.photoGroup.length + (canAddMorePhotos ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == widget.photoGroup.length) {
                          // This is the "Add More" button
                          return InkWell(
                            onTap: () async {
                              await widget.provider.pickAndProcessImages(
                                context,
                                ImageSource.gallery,
                                _originalPosition, // Add to the original group
                                _descriptionController.text,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_a_photo,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }

                        final photo = widget.photoGroup[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: photo.url.startsWith('http')
                                  ? Image.network(photo.url, fit: BoxFit.cover)
                                  : Image.file(
                                      File(photo.url),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      widget.provider.removePhoto(photo),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes'),
                  onPressed: () {
                    if (_selectedPosition != null &&
                        _descriptionController.text.isNotEmpty) {
                      widget.provider.updatePhotoGroupDetails(
                        _originalPosition,
                        _selectedPosition!,
                        _descriptionController.text,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
