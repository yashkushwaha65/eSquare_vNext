import 'package:esquare/core/models/post_gate_in_summaryMdl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api_endpoints.dart';
import '../core/services/api_services.dart';

class PostRepairSummaryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool isLoading = false;
  List<PostRepairSummary> summaries = [];

  Future<void> fetchRepairSummary({
    required int buId,
    required String fromDate,
    required String toDate,
    String slId = "0",
    String searchCriteria = "All",
    String searchText = "",
    required int userId,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {
        "BUID": buId.toString(),
        "FromDate": DateFormat(
          'dd MMM yyyy HH:mm',
        ).format(DateFormat('dd-MM-yyyy HH:mm').parse(fromDate)),
        "ToDate": DateFormat(
          'dd MMM yyyy HH:mm',
        ).format(DateFormat('dd-MM-yyyy HH:mm').parse(toDate)),
        "SLID": slId,
        "SearchCriteria": searchCriteria,
        "SearchText": searchText,
        "UserID": userId.toString(),
      };

      debugPrint('📤 PostRepairSummary (Form-UrlEncoded) API Payload:\n$body');

      final response = await _apiService.postFormUrlEncodedRequest(
        ApiEndpoints.postRepairSummary,
        body,
        authToken: ApiEndpoints.surveyAuthToken,
      );

      debugPrint('✅ PostRepairSummary API Response:\n$response');

      if (response is List) {
        summaries = response
            .map((e) => PostRepairSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        summaries = [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching repair summary: $e');
      summaries = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
