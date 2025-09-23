import 'dart:convert';

import 'package:esquare/core/theme/app_theme.dart';
import 'package:esquare/providers/post_gate_in_summaryPdr.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostRepairSummaryPage extends StatefulWidget {
  const PostRepairSummaryPage({super.key});

  @override
  State<PostRepairSummaryPage> createState() => _PostRepairSummaryPageState();
}

class _PostRepairSummaryPageState extends State<PostRepairSummaryPage>
    with TickerProviderStateMixin {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();
  late final TextEditingController fromDateController;
  late final TextEditingController toDateController;
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
        Provider.of<PostRepairSummaryProvider>(
          context,
          listen: false,
        ).fetchRepairSummary(
          buId: buId!,
          fromDate: fromDateController.text,
          toDate: toDateController.text,
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

  void _navigateToEditPage(dynamic item) {
    // TODO: Navigate to edit page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening edit page for ${item.containerNo}'),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showItemDetails(dynamic item) {
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

    return filters;
  }

  Widget _buildActiveFilterChip(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(icon, size: 16, color: AppTheme.secondaryColor),
        label: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
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
        side: BorderSide(color: AppTheme.secondaryColor, width: 1),
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PostRepairSummaryProvider>(context);
    final summaries = provider.summaries;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Post Repair Summary'),
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
                                      color: AppTheme.secondaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.filter_list,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
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
                                      color: AppTheme.secondaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${summaries.length} Results',
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

                  // Summary Cards
                  if (!provider.isLoading && summaries.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: AppTheme.backgroundColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Containers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.black54),
                                    ),
                                    Text(
                                      summaries.length.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              color: AppTheme.backgroundColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Estimate Amount',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.black54),
                                    ),
                                    Text(
                                      '₹${summaries.fold(0.0, (sum, item) => sum + item.estimateAmount).toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                        : summaries.isEmpty
                        ? _buildEmptyState()
                        : _buildResultsList(provider, summaries),
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
                    color: AppTheme.secondaryColor,
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
                    color: AppTheme.secondaryColor,
                  ),
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
                  foregroundColor: AppTheme.secondaryColor,
                  side: BorderSide(color: AppTheme.secondaryColor, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _applyFilters() {
    if (userId == null || buId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data not loaded. Please wait.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    debugPrint('🔧 Applying filters with userId: $userId, buId: $buId');
    Provider.of<PostRepairSummaryProvider>(
      context,
      listen: false,
    ).fetchRepairSummary(
      buId: buId!,
      fromDate: fromDateController.text,
      toDate: toDateController.text,
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
    PostRepairSummaryProvider provider,
    List<dynamic> summaries,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        if (userId == null || buId == null) {
          await _loadUserDataAndFetch();
          return;
        }
        _applyFilters();
      },
      color: AppTheme.secondaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final item = summaries[index];
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
                            colors: [
                              AppTheme.secondaryColor,
                              AppTheme.primaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.build,
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
                              item.containerNo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${item.containerType}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF616161),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.inDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
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
                                colors: [
                                  AppTheme.secondaryColor,
                                  AppTheme.primaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '₹${item.estimateAmount.toStringAsFixed(0)}',
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
                                color: AppTheme.secondaryColor,
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

  Widget _buildDetailBottomSheet(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.build, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.containerNo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Repair Details',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF757575)),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildDetailSection('Repair Information', [
                    _buildDetailRow('Container No', item.containerNo),
                    _buildDetailRow('Container Type', item.containerType),
                    _buildDetailRow('In Date', item.inDate),
                    _buildDetailRow('Repair Date', item.repairDate),
                    _buildDetailRow(
                      'Estimate Amount',
                      '₹${item.estimateAmount.toStringAsFixed(2)}',
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text(
                        'Edit Repair',
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

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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
              style: TextStyle(
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
