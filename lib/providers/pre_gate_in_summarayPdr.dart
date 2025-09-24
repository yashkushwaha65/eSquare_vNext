// lib/providers/pre_gate_in_summarayPdr.dart

import 'package:esquare/core/models/survey_attachment_mdl.dart';
import 'package:flutter/material.dart';

import '../api_endpoints.dart';
import '../core/models/pre_gate_in_summaryMdl.dart';
import '../core/services/api_services.dart';

class PreGateInSummaryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool isLoading = false;
  List<PreGateInSummary> summaries = [];

  Future<void> fetchSummary({
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
        "BUID": buId,
        "FromDate": fromDate,
        "ToDate": toDate,
        "SLID": slId,
        "SearchCriteria": searchCriteria,
        "SearchText": searchText,
        "UserID": userId,
      };

      debugPrint('📤 PreGateInSummary API Payload:\n$body');

      final response = await _apiService.postRequest(
        ApiEndpoints.preGateInSummary,
        body,
        authToken: ApiEndpoints.surveyAuthToken,
      );

      debugPrint('✅ PreGateInSummary API Response:\n$response');

      if (response is List) {
        summaries = response
            .map((e) => PreGateInSummary.fromJson(e as Map<String, dynamic>))
            .toList();
        await _fetchAttachmentsForSummaries(buId);
      } else {
        summaries = [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching summary: $e');
      summaries = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAttachmentsForSummaries(int buId) async {
    for (var i = 0; i < summaries.length; i++) {
      final summary = summaries[i];
      try {
        final attachmentsResponse = await _apiService.postRequest(
          ApiEndpoints.viewSurveyAttachments,
          {"SurveyID": summary.surveyID, "BUID": buId},
        );

        if (attachmentsResponse is List) {
          final attachments = attachmentsResponse
              .map((e) => SurveyAttachment.fromJson(e as Map<String, dynamic>))
              .toList();
          summaries[i] = summary.copyWith(attachments: attachments);
        }
      } catch (e) {
        debugPrint(
          '❌ Error fetching attachments for SurveyID ${summary.surveyID}: $e',
        );
      }
    }
  }
}
