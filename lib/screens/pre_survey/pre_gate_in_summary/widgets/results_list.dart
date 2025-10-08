// lib/screens/pre_survey/pre_gate_in_summary/widgets/results_list.dart
import 'package:esquare/core/models/containerMdl.dart';
import 'package:esquare/core/models/detailsMdl.dart';
import 'package:esquare/core/models/photoMdl.dart';
import 'package:esquare/core/models/pre_gate_in_summaryMdl.dart';
import 'package:esquare/core/models/surveyMdl.dart';
import 'package:esquare/core/models/transporterMdl.dart';
import 'package:esquare/core/theme/app_theme.dart';
import 'package:esquare/providers/pre_gate_in_summarayPdr.dart';
import 'package:esquare/screens/pre_survey/pre_gate_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

import 'detail_bottom_sheet.dart';

class ResultsList extends StatelessWidget {
  final PreGateInSummaryProvider provider;
  final List<PreGateInSummary> sortedSummaries;
  final ScrollController scrollController;
  final VoidCallback onApplyFilters;

  const ResultsList({
    super.key,
    required this.provider,
    required this.sortedSummaries,
    required this.scrollController,
    required this.onApplyFilters,
  });

  void _navigateToEditPage(BuildContext context, PreGateInSummary item) {
    final survey = Survey(
      id: item.surveyID.toString(),
      containerId: item.containerNo,
      container: ContainerModel(
        id: '',
        containerNo: item.containerNo,
        mfgMonth: item.mfgMonth,
        mfgYear: item.mfgYear.toString(),
        grossWeight: item.grossWt,
        tareWeight: item.tareWt,
        payload: item.payLoad,
        shippingLine: item.lineName,
        isoCode: item.isoCode,
        sizeType: '${item.size} ${item.containerType}',
        status: item.containerStatus,
        fromLocation: item.location,
      ),
      transporter: Transporter(
        vehicleNo: item.vehicleNo,
        transporterName: item.transporter,
        driverLicense: item.driverLicenceNo,
        driverName: item.driverName,
      ),
      details: Details(
        category: item.category,
        examination: item.examinType,
        surveyType: item.surveyType,
        containerInStatus: item.containerStatus,
        grade: item.grade,
        cscAsp: item.cscAsp,
        doNo: item.doNo,
        doDate: item.doValidityDate,
        description: item.remarks,
        condition: item.condition,
      ),
      photos: item.attachments
          .map(
            (e) => Photo(
              id: '',
              url: e.filePath1,
              timestamp: '',
              docName: e.docName,
              description: e.fileDesc,
            ),
          )
          .toList(),
      createdAt: item.surveyDate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreGateInScreen(editingSurvey: survey),
      ),
    );
  }

  void _showItemDetails(BuildContext context, PreGateInSummary item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailBottomSheet(item: item),
    );
  }

  void _showSurveyPhotos(BuildContext context, PreGateInSummary item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Survey Photos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(
              height: 300, // Constrain the height of the GridView
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: item.attachments.length,
                itemBuilder: (context, index) {
                  final attachment = item.attachments[index];
                  final imageUrl = attachment.filePath1;
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            Dialog(child: Image.network(imageUrl)),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SvgPicture.asset('assets/anims/loading.json'),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search filters',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onApplyFilters(),
      color: AppTheme.primaryColor,
      child: provider.isLoading
          ? Center(
              child: Lottie.asset(
                'assets/anims/loading.json',
                height: 150,
                width: 150,
                repeat: true,
              ),
            )
          : sortedSummaries.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: sortedSummaries.length,
              itemBuilder: (context, index) {
                final item = sortedSummaries[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _showItemDetails(context, item),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Survey No: ${item.surveyNo}',
                                  style: AppTheme
                                      .lightTheme
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Text(
                              //   item.surveyDate,
                              //   style: AppTheme.lightTheme.textTheme.bodySmall
                              //       ?.copyWith(color: Colors.grey[600]),
                              // ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow('Survey Date', item.surveyDate),
                          const SizedBox(height: 8),
                          _buildInfoRow('Container:', item.containerNo),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Size/Type:',
                            '${item.size} ${item.containerType}',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Shipping Line:', item.lineName),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (item.attachments.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.photo_library,
                                    color: AppTheme.primaryColor,
                                  ),
                                  onPressed: () =>
                                      _showSurveyPhotos(context, item),
                                  tooltip: 'View Photos',
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppTheme.secondaryColor,
                                ),
                                onPressed: () =>
                                    _navigateToEditPage(context, item),
                                tooltip: 'Edit',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: AppTheme.lightTheme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
