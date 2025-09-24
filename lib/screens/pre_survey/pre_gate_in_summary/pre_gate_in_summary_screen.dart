import 'dart:convert';

import 'package:esquare/core/models/pre_gate_in_summaryMdl.dart';
import 'package:esquare/core/theme/app_theme.dart';
import 'package:esquare/providers/pre_gate_in_summarayPdr.dart';
import 'package:esquare/screens/pre_survey/pre_gate_in_summary/widgets/filter_section.dart';
import 'package:esquare/screens/pre_survey/pre_gate_in_summary/widgets/results_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
                  FilterSection(
                    fromDate: fromDate,
                    toDate: toDate,
                    fromDateController: fromDateController,
                    toDateController: toDateController,
                    searchCriteria: searchCriteria,
                    searchTextController: searchTextController,
                    isFiltersExpanded: _isFiltersExpanded,
                    filterAnimation: _filterAnimation,
                    sortedSummaries: sortedSummaries,
                    onSelectDateTime: _selectDateTime,
                    onSearchCriteriaChanged: (val) =>
                        setState(() => searchCriteria = val!),
                    onApplyFilters: _applyFilters,
                    onClearFilters: _clearFilters,
                  ),
                  Expanded(
                    child: ResultsList(
                      provider: provider,
                      sortedSummaries: sortedSummaries,
                      scrollController: _scrollController,
                      onApplyFilters: _applyFilters,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
