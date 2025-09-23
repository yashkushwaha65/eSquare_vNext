// lib/screens/pre_survey/tabs/photos_tab.dart
import 'dart:io';

import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreGateInProvider>(context);
    final canUpload =
        _selectedPosition != null && _descriptionController.text.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photo Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select position and add a description before uploading',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

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
                // **FIXED**: Using the correct key 'Type' from your API response
                value: doc['Type']?.toString(),
                child: Text(doc['Type']?.toString() ?? 'Invalid Type'),
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
            onChanged: (text) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: canUpload
                      ? () {
                          provider.pickAndProcessImages(
                            ImageSource.gallery,
                            _selectedPosition!,
                            _descriptionController.text,
                          );
                          _descriptionController.clear();
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: canUpload
                      ? () {
                          provider.pickAndProcessImages(
                            ImageSource.camera,
                            _selectedPosition!,
                            _descriptionController.text,
                          );
                          _descriptionController.clear();
                        }
                      : null,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (provider.photos.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.photos.length,
              itemBuilder: (context, index) {
                final photo = provider.photos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(photo.url),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo.docName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(photo.description),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.removePhoto(photo),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No photos uploaded yet.'),
              ),
            ),
        ],
      ),
    );
  }
}
