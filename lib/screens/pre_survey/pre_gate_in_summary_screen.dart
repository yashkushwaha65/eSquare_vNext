import 'dart:convert';

import 'package:esquare/core/models/pre_gate_in_summaryMdl.dart';
import 'package:esquare/providers/pre_gate_in_summarayPdr.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class PreGateInSummaryPage extends StatefulWidget {
  const PreGateInSummaryPage({super.key});

  @override
  State<PreGateInSummaryPage> createState() => _PreGateInSummaryPageState();
}

class _PreGateInSummaryPageState extends State<PreGateInSummaryPage>
    with TickerProviderStateMixin {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();
  late final TextEditingController fromDateController;
  late final TextEditingController toDateController;
  String searchCriteria = 'All';
  final TextEditingController searchTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? userId;
  int? buId;
  String? userName;
  bool _isUserDataLoading = true;
  bool _isFiltersExpanded = false;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    fromDateController = TextEditingController(
      text: DateFormat('dd MMM yyyy HH:mm').format(fromDate),
    );
    toDateController = TextEditingController(
      text: DateFormat('dd MMM yyyy HH:mm').format(toDate),
    );

    searchTextController.addListener(() {
      setState(() {});
    });

    _loadUserDataAndFetch();
  }

  Future<void> _loadUserDataAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('user');

    if (userJsonString != null) {
      final userDataMap = jsonDecode(userJsonString) as Map<String, dynamic>;

      setState(() {
        userId = userDataMap['UserID'];
        buId = userDataMap['BUID'];
        userName = userDataMap['UserName'];
        _isUserDataLoading = false;
      });

      debugPrint('✅ Loaded User Data: $userDataMap');

      if (userId != null && buId != null) {
        Provider.of<PreGateInSummaryProvider>(
          context,
          listen: false,
        ).fetchSummary(
          buId: buId!,
          fromDate: fromDateController.text,
          toDate: toDateController.text,
          slId: "0",
          searchCriteria: searchCriteria,
          searchText: searchTextController.text,
          userId: userId!,
        );
      }
    } else {
      debugPrint('❌ User data not found in SharedPreferences');
      setState(() => _isUserDataLoading = false);
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? fromDate : toDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isFromDate) {
            fromDate = newDateTime;
            fromDateController.text = DateFormat(
              'dd MMM yyyy HH:mm',
            ).format(fromDate);
          } else {
            toDate = newDateTime;
            toDateController.text = DateFormat(
              'dd MMM yyyy HH:mm',
            ).format(toDate);
          }
        });
      }
    }
  }

  List<PreGateInSummary> getSortedSummaries(
    List<PreGateInSummary> summaries,
    String criteria,
  ) {
    List<PreGateInSummary> sorted = List.from(summaries);
    switch (criteria) {
      case 'ContainerNo':
        sorted.sort((a, b) => a.containerNo.compareTo(b.containerNo));
        break;
      case 'VehicleNo':
        sorted.sort((a, b) => a.vehicleNo.compareTo(b.vehicleNo));
        break;
      case 'SurveyNo':
        sorted.sort((a, b) => a.surveyNo.compareTo(b.surveyNo));
        break;
      case 'ISOCode':
        sorted.sort((a, b) => a.isoCode.compareTo(b.isoCode));
        break;
      default:
        sorted.sort((a, b) => a.srNo.compareTo(b.srNo));
    }
    return sorted;
  }

  void _toggleFilters() {
    setState(() {
      _isFiltersExpanded = !_isFiltersExpanded;
    });
    if (_isFiltersExpanded) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _navigateToEditPage(PreGateInSummary item) {
    // TODO: Navigate to edit page
    // Example: Navigator.pushNamed(context, '/edit-gate-summary', arguments: item);

    // Temporary implementation showing navigation intent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening edit page for ${item.containerNo}'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showItemDetails(PreGateInSummary item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailBottomSheet(item),
    );
  }

  List<Widget> _getActiveFilters() {
    List<Widget> filters = [];

    // Date range filter
    final dateRange =
        '${DateFormat('MMM dd').format(fromDate)} - ${DateFormat('MMM dd').format(toDate)}';
    filters.add(
      _buildActiveFilterChip('Date Range', dateRange, Icons.date_range),
    );

    // Search criteria filter
    if (searchCriteria != 'All') {
      filters.add(
        _buildActiveFilterChip('Search By', searchCriteria, Icons.search),
      );
    }

    // Search text filter
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

  @override
  void dispose() {
    _filterAnimationController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    searchTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreGateInSummaryProvider>(context);
    final sortedSummaries = getSortedSummaries(
      provider.summaries,
      searchCriteria,
    );

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pre Gate In Summary'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: AnimatedRotation(
                  turns: _isFiltersExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.tune, size: 24),
                ),
                onPressed: _toggleFilters,
                tooltip: _isFiltersExpanded ? 'Hide Filters' : 'Show Filters',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isUserDataLoading
            ? Center(
                child: Lottie.asset(
                  'assets/anims/loading.json',
                  height: 150,
                  width: 150,
                  repeat: true,
                ),
              )
            : Column(
                children: [
                  // Enhanced Filter Section
                  Container(
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
                        // Active Filters Display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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

                        // Expandable Filter Controls
                        SizeTransition(
                          sizeFactor: _filterAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: _buildExpandedFilters(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Results List
                  Expanded(
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
                        : _buildResultsList(provider, sortedSummaries),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildExpandedFilters() {
    return Column(
      children: [
        // Date Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: fromDateController,
                readOnly: true,
                onTap: () => _selectDateTime(context, true),
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
                onTap: () => _selectDateTime(context, false),
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

        // Search Row
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
                items:
                    <String>[
                      'All',
                      'ContainerNo',
                      'VehicleNo',
                      'SurveyNo',
                      'ISOCode',
                    ].map((val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                onChanged: (val) => setState(() => searchCriteria = val!),
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

        // Action Buttons
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
                onPressed: _applyFilters,
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
                onPressed: _clearFilters,
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

  void _applyFilters() {
    debugPrint('🔧 Applying filters with userId: $userId, buId: $buId');
    Provider.of<PreGateInSummaryProvider>(context, listen: false).fetchSummary(
      buId: buId!,
      fromDate: fromDateController.text,
      toDate: toDateController.text,
      slId: "0",
      searchCriteria: searchCriteria,
      searchText: searchTextController.text,
      userId: userId!,
    );
  }

  void _clearFilters() {
    setState(() {
      fromDate = DateTime.now().subtract(const Duration(days: 30));
      toDate = DateTime.now();
      fromDateController.text = DateFormat(
        'dd MMM yyyy HH:mm',
      ).format(fromDate);
      toDateController.text = DateFormat('dd MMM yyyy HH:mm').format(toDate);
      searchCriteria = 'All';
      searchTextController.clear();
    });
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

  Widget _buildResultsList(
    PreGateInSummaryProvider provider,
    List<PreGateInSummary> sortedSummaries,
  ) {
    return RefreshIndicator(
      onRefresh: () async => _applyFilters(),
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: sortedSummaries.length,
        itemBuilder: (context, index) {
          final item = sortedSummaries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showItemDetails(item),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon Container
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

                      // Content
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
                      // Right Side
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, AppTheme.primaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.payLoad.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                              onPressed: () => _navigateToEditPage(item),
                              tooltip: 'Edit',
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDetailBottomSheet(PreGateInSummary item) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      // adjust height
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
                // Handle
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

                // Container Info
                _buildDetailSection('Container Details', [
                  _buildDetailRow('Container No', item.containerNo),
                  _buildDetailRow(
                    'Size/Type',
                    '${item.size} ${item.containerType}',
                  ),
                  _buildDetailRow('ISO Code', item.isoCode),
                  _buildDetailRow('Category', item.category),
                  _buildDetailRow('Line Name', item.lineName),
                ]),

                const SizedBox(height: 20),

                // Transport Info
                _buildDetailSection('Transport Details', [
                  _buildDetailRow('Vehicle Number', item.vehicleNo),
                  _buildDetailRow('SLID', item.lineName),
                ]),

                const SizedBox(height: 20),

                // Survey Info
                _buildDetailSection('Survey Details', [
                  _buildDetailRow('Survey No', item.surveyNo),
                  _buildDetailRow('Survey Date', item.surveyDate),
                  _buildDetailRow('Survey Type', item.surveyType),
                  _buildDetailRow('Container Status', item.containerStatus),
                  _buildDetailRow('Condition', item.condition),
                ]),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text(
                      'Edit Container',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditPage(item);
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
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
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
}
