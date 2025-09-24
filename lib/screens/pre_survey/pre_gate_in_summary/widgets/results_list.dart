import 'package:esquare/core/models/pre_gate_in_summaryMdl.dart';
import 'package:esquare/core/theme/app_theme.dart';
import 'package:esquare/providers/pre_gate_in_summarayPdr.dart';
import 'package:flutter/material.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening edit page for ${item.containerNo}'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showItemDetails(context, item),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, AppTheme.primaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Survey No: ${item.surveyNo}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Container: ${item.containerNo}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Size/Type: ${item.size} ${item.containerType}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF616161),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.surveyDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SLID: ${item.lineName}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF616161),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () => _navigateToEditPage(context, item),
                              tooltip: 'Edit',
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.attachments.length,
                            itemBuilder: (context, index) {
                              final attachment = item.attachments[index];
                              final imageUrl = attachment.filePath1;
                              debugPrint("Loading image from URL: $imageUrl");
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: Image.network(imageUrl),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: AppTheme.primaryColor,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          debugPrint("Error loading image: $error");
                                          return const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}