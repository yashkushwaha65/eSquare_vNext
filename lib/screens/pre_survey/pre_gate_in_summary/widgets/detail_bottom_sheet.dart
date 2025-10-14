// lib/screens/pre_survey/pre_gate_in_summary/widgets/detail_bottom_sheet.dart
import 'package:esquare/core/models/containerMdl.dart';
import 'package:esquare/core/models/detailsMdl.dart';
import 'package:esquare/core/models/photoMdl.dart';
import 'package:esquare/core/models/pre_gate_in_summaryMdl.dart';
import 'package:esquare/core/models/surveyMdl.dart';
import 'package:esquare/core/models/transporterMdl.dart';
import 'package:esquare/core/theme/app_theme.dart';
import 'package:esquare/screens/pre_survey/pre_gate_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DetailBottomSheet extends StatelessWidget {
  final PreGateInSummary item;

  const DetailBottomSheet({super.key, required this.item});

  void _navigateToEditPage(BuildContext context) {
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF616161),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _buildDetailSection('Container No: ${item.containerNo}', [
                  _buildDetailRow('ISO Code', item.isoCode),
                  _buildDetailRow('Type', item.containerType),
                  _buildDetailRow('Size', item.size.toString()),
                  _buildDetailRow('Category', item.category),
                  _buildDetailRow('Shipping Line', item.lineName),
                  _buildDetailRow(
                    'Gross Weight',
                    '${item.grossWt.toStringAsFixed(2)} kg',
                  ),
                  _buildDetailRow(
                    'Tare Weight',
                    '${item.tareWt.toStringAsFixed(2)} kg',
                  ),
                  _buildDetailRow(
                    'Payload',
                    '${item.payLoad.toStringAsFixed(2)} kg',
                  ),
                  _buildDetailRow('MFG Month', item.mfgMonth),
                  _buildDetailRow('MFG Year', item.mfgYear.toString()),
                  _buildDetailRow('Location', item.location.toString()),
                ]),
                const SizedBox(height: 20),
                _buildDetailSection('Transport Details', [

                  _buildDetailRow('Transporter', item.transporter),
                  _buildDetailRow('Vehicle Number', item.vehicleNo),
                  _buildDetailRow('Driver Name', item.driverName),
                  _buildDetailRow('Driver Licence No', item.driverLicenceNo),
                ]),
                const SizedBox(height: 20),
                _buildDetailSection('Survey Details', [
                  // _buildDetailRow('Survey No', item.surveyNo),
                  _buildDetailRow('Survey Date', item.surveyDate),
                  _buildDetailRow('Survey Type', item.surveyType),
                  _buildDetailRow('Container Status', item.containerStatus),
                  _buildDetailRow('Condition', item.condition),
                  _buildDetailRow('Examined Type', item.examinType),
                  _buildDetailRow('Remarks', item.remarks.toString()),
                ]),
                if (item.attachments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDetailSection('Attachments', [
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.attachments.length,
                        itemBuilder: (context, index) {
                          final attachment = item.attachments[index];
                          final imageUrl = attachment.filePath1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
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
                                  width: 150,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: Lottie.asset(
                                            'assets/anims/loading.json',
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text(
                      'Edit Survey',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditPage(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
