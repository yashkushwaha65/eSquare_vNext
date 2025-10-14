import 'dart:io';

import 'package:camera/camera.dart';
import 'package:esquare/core/models/photoMdl.dart';
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../widgets/caution_dialog.dart';
import '../pre_gate_in_summary/widgets/custom_camera_screen.dart';

class PhotosTab extends StatefulWidget {
  const PhotosTab({super.key});

  @override
  State<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<PhotosTab>
    with AutomaticKeepAliveClientMixin {
  String? _selectedPosition;
  final _descriptionController = TextEditingController();
  List<XFile> _stagedPhotos = [];

  final supportedExtensions = ['jpg', 'jpeg', 'png', 'JPG', 'JPEG', 'PNG'];

  @override
  bool get wantKeepAlive => true;

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

  // MODIFIED: Reverted to correct staging logic
  Future<void> _pickImages(ImageSource source) async {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    final picker = ImagePicker();
    final List<XFile> stagedFiles = [];

    if (_selectedPosition == null) {
      await CautionDialog.show(
        context: context,
        title: 'Select Position',
        message: 'Please select a container position before adding photos.',
        icon: Icons.info_outline,
        iconColor: Colors.blue,
      );
      return;
    }

    final currentPhotoCount = provider.photos.length + _stagedPhotos.length;
    final remainingSlots = provider.maxPhotosTotal - currentPhotoCount;

    if (remainingSlots <= 0) {
      if (!context.mounted) return;
      await CautionDialog.show(
        context: context,
        title: 'Photo Limit Reached',
        message:
            'You have reached the maximum of ${provider.maxPhotosTotal} photos for this survey.',
        icon: Icons.info_outline,
        iconColor: Colors.blue,
      );
      return;
    }

    if (source == ImageSource.camera) {
      final cameras = await availableCameras();
      if (!context.mounted) return;
      final captured = await Navigator.push<List<XFile>>(
        context,
        MaterialPageRoute(builder: (_) => CustomCameraScreen(cameras: cameras)),
      );

      if (captured != null && captured.isNotEmpty) {
        if (captured.length > remainingSlots) {
          stagedFiles.addAll(captured.sublist(0, remainingSlots));
          if (!context.mounted) return;
          await CautionDialog.show(
            context: context,
            title: 'Photo Limit Exceeded',
            message:
                'You can only add $remainingSlots more photos. ${remainingSlots} photos have been added.',
            icon: Icons.info_outline,
            iconColor: Colors.blue,
          );
        } else {
          stagedFiles.addAll(captured);
        }
      }
    } else {
      final selectedFiles = await picker.pickMultiImage();
      if (selectedFiles.isNotEmpty) {
        final validFiles = <XFile>[];
        for (final file in selectedFiles) {
          final extension = file.path.split('.').last.toLowerCase();
          if (supportedExtensions.contains(extension)) {
            validFiles.add(file);
          }
        }

        if (validFiles.length > remainingSlots) {
          stagedFiles.addAll(validFiles.sublist(0, remainingSlots));
          if (!context.mounted) return;
          await CautionDialog.show(
            context: context,
            title: 'Photo Limit Exceeded',
            message:
                'You can only add $remainingSlots more photos. ${remainingSlots} photos have been added.',
            icon: Icons.info_outline,
            iconColor: Colors.blue,
          );
        } else {
          stagedFiles.addAll(validFiles);
        }
      }
    }

    if (stagedFiles.isNotEmpty) {
      setState(() {
        _stagedPhotos.addAll(stagedFiles);
      });
    }
  }

  void _addStagedPhotos() async {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);

    if (_selectedPosition == null) {
      CautionDialog.show(
        context: context,
        title: 'Position Not Selected',
        message: 'Please select a container position before adding photos.',
      );
      return;
    }

    if (_stagedPhotos.isEmpty) {
      CautionDialog.show(
        context: context,
        title: 'No Photos Selected',
        message: 'Please select or capture photos to add.',
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      CautionDialog.show(
        context: context,
        title: 'Description Required',
        message: 'Please enter a description for the selected photos.',
      );
      return;
    }

    // --- FIX: Call the new provider method to handle processing ---
    await provider.processAndAddStagedPhotos(
      _stagedPhotos,
      _selectedPosition!,
      _descriptionController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _stagedPhotos.clear();
      _selectedPosition = null;
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<PreGateInProvider>(
      builder: (context, provider, child) {
        final groupedPhotos = <String, List<Photo>>{};
        for (var photo in provider.photos) {
          (groupedPhotos[photo.docName] ??= []).add(photo);
        }

        final canAddNewPhotos =
            (provider.photos.length + _stagedPhotos.length) <
            provider.maxPhotosTotal;
        final isPositionSelected = _selectedPosition != null;

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
              const Text(
                'Add New Photos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total photos for this survey: ${provider.photos.length}/${provider.maxPhotosTotal}',
                style: TextStyle(
                  color: canAddNewPhotos ? Colors.grey.shade700 : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Container Position',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                hint: const Text('Choose a position...'),
                items: provider.docTypes.map<DropdownMenuItem<String>>((doc) {
                  return DropdownMenuItem<String>(
                    value: doc['Type']?.toString(),
                    child: Text(doc['Type']?.toString() ?? 'Invalid Type'),
                  );
                }).toList(),
                onChanged: _onPositionChanged,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePickerButton(
                      context: context,
                      source: ImageSource.gallery,
                      iconAsset: 'assets/icons/imagefull.svg',
                      isEnabled: isPositionSelected && canAddNewPhotos,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImagePickerButton(
                      context: context,
                      source: ImageSource.camera,
                      iconAsset: 'assets/icons/camerafull.svg',
                      isEnabled: isPositionSelected && canAddNewPhotos,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_stagedPhotos.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _stagedPhotos.map((file) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(file.path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _stagedPhotos.remove(file);
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addStagedPhotos,
                        icon: const Icon(Icons.add_to_photos),
                        label: const Text('Add Photos to Survey'),
                      ),
                    ),
                  ],
                ),
              const Divider(height: 48),
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
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirmed =
                                        await CautionDialog.showDeleteConfirmation(
                                          context,
                                          groupName: docName,
                                        );
                                    if (confirmed) {
                                      provider.removePhotoGroup(docName);
                                    }
                                  },
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
                  await _pickImages(source);
                },
        ),
      ),
    );
  }
}

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
    return Consumer<PreGateInProvider>(
      builder: (context, provider, child) {
        final canAddMorePhotos =
            provider.photos.length < provider.maxPhotosTotal;
        final currentGroupPhotos = provider.photos
            .where((p) => p.docName == _originalPosition)
            .toList();

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Photo Group',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPosition,
                          decoration: const InputDecoration(
                            labelText: 'Container Position',
                            border: OutlineInputBorder(),
                          ),
                          items: provider.docTypes
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
                              currentGroupPhotos.length +
                              (canAddMorePhotos ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == currentGroupPhotos.length) {
                              return InkWell(
                                onTap: () async {
                                  if (_descriptionController.text
                                      .trim()
                                      .isEmpty) {
                                    CautionDialog.show(
                                      context: context,
                                      title: 'Description Required',
                                      message:
                                          'Please enter a description for the group before adding new photos.',
                                    );
                                    return;
                                  }

                                  await showModalBottomSheet(
                                    context: context,
                                    builder: (ctx) => SafeArea(
                                      child: Wrap(
                                        children: <Widget>[
                                          ListTile(
                                            leading: const Icon(
                                              Icons.photo_library,
                                            ),
                                            title: const Text('Gallery'),
                                            onTap: () {
                                              Navigator.of(ctx).pop();
                                              provider.pickAndProcessImages(
                                                context,
                                                ImageSource.gallery,
                                                _selectedPosition!,
                                                _descriptionController.text
                                                    .trim(),
                                                allowMultiple: true,
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.photo_camera,
                                            ),
                                            title: const Text('Camera'),
                                            onTap: () {
                                              Navigator.of(ctx).pop();
                                              provider.pickAndProcessImages(
                                                context,
                                                ImageSource.camera,
                                                _selectedPosition!,
                                                _descriptionController.text
                                                    .trim(),
                                                allowMultiple: true,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
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

                            final photo = currentGroupPhotos[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: photo.url.startsWith('http')
                                      ? Image.network(
                                          photo.url,
                                          fit: BoxFit.cover,
                                        )
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
                                          provider.removePhoto(photo),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Changes'),
                      onPressed: () {
                        if (_selectedPosition != null &&
                            _descriptionController.text.trim().isNotEmpty) {
                          provider.updatePhotoGroupDetails(
                            _originalPosition,
                            _selectedPosition!,
                            _descriptionController.text.trim(),
                          );
                          Navigator.of(context).pop();
                        } else {
                          CautionDialog.show(
                            context: context,
                            title: 'Description Required',
                            message:
                                'Please enter a description for this photo group.',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
