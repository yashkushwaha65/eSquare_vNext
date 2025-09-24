import 'package:esquare/core/models/pre_gate_in_summaryMdl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_theme.dart';


class FilterSection extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final TextEditingController fromDateController;
  final TextEditingController toDateController;
  final String searchCriteria;
  final TextEditingController searchTextController;
  final bool isFiltersExpanded;
  final Animation<double> filterAnimation;
  final List<PreGateInSummary> sortedSummaries;
  final Function(BuildContext, bool) onSelectDateTime;
  final Function(String?) onSearchCriteriaChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterSection({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.fromDateController,
    required this.toDateController,
    required this.searchCriteria,
    required this.searchTextController,
    required this.isFiltersExpanded,
    required this.filterAnimation,
    required this.sortedSummaries,
    required this.onSelectDateTime,
    required this.onSearchCriteriaChanged,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  List<Widget> _getActiveFilters() {
    List<Widget> filters = [];

    final dateRange =
        '${DateFormat('MMM dd').format(fromDate)} - ${DateFormat('MMM dd').format(toDate)}';
    filters.add(
      _buildActiveFilterChip('Date Range', dateRange, Icons.date_range),
    );

    if (searchCriteria != 'All') {
      filters.add(
        _buildActiveFilterChip('Search By', searchCriteria, Icons.search),
      );
    }

    if (searchTextController.text.isNotEmpty) {
      filters.add(
        _buildActiveFilterChip(
          'Search',
          searchTextController.text,
          Icons.filter_alt,
        ),
      );
    }

    return filters;
  }

  Widget _buildActiveFilterChip(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(icon, size: 16, color: AppTheme.primaryColor),
        label: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        side: const BorderSide(color: AppTheme.primaryColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildExpandedFilters(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: fromDateController,
                readOnly: true,
                onTap: () => onSelectDateTime(context, true),
                decoration: const InputDecoration(
                  labelText: 'From Date',
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: toDateController,
                readOnly: true,
                onTap: () => onSelectDateTime(context, false),
                decoration: const InputDecoration(
                  labelText: 'To Date',
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: searchCriteria,
                decoration: const InputDecoration(
                  labelText: 'Search By',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
                items: <String>['All', 'ContainerNo', 'VehicleNo', 'SurveyNo', 'ISOCode']
                    .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: onSearchCriteriaChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: searchTextController,
                decoration: InputDecoration(
                  labelText: 'Search Text',
                  prefixIcon: const Icon(
                    Icons.manage_search,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: searchTextController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 18,
                      color: Color(0xFF757575),
                    ),
                    onPressed: () => searchTextController.clear(),
                  )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search, size: 20),
                label: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: onApplyFilters,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  'Reset',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: onClearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Filters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sortedSummaries.length} Results',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _getActiveFilters()),
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: filterAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _buildExpandedFilters(context),
            ),
          ),
        ],
      ),
    );
  }
}