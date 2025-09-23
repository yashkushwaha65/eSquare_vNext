// lib/models/survey.dart
import 'package:esquare/core/models/containerMdl.dart';
import 'package:esquare/core/models/detailsMdl.dart';
import 'package:esquare/core/models/photoMdl.dart';
import 'package:esquare/core/models/transporterMdl.dart';

class Survey {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String containerId;
  final ContainerModel container;
  final Transporter transporter;
  final Details details;
  final List<Photo> photos;

  Survey({
    this.id,
    this.createdAt,
    this.updatedAt,
    required this.containerId,
    required this.container,
    required this.transporter,
    required this.details,
    required this.photos,
  });
}