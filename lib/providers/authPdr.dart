import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_endpoints.dart';
import '../core/models/userMdl.dart';
import '../core/services/api_services.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  UserModel? user;
  String? errorMessage;
  int? preImgLmt;
  int? postImgLmt;
  int? finalImgLmt;

  bool get isLoggedIn => user != null;

  Future<void> fetchImageLimits(int buId) async {
    try {
      final response = await _apiService.postRequest(ApiEndpoints.getImgLimit, {
        "BUID": buId,
      }, authToken: ApiEndpoints.imgLimitAuthToken);

      // --- FIX START ---
      // The API might return a single map or a list with one map.
      Map<String, dynamic>? limitsData;
      if (response is List && response.isNotEmpty) {
        limitsData = response.first as Map<String, dynamic>;
      } else if (response is Map<String, dynamic>) {
        limitsData = response;
      }

      if (limitsData != null) {
        preImgLmt = limitsData['PreImgLMT'];
        postImgLmt = limitsData['PostImgLMT'];
        finalImgLmt = limitsData['FinalImgLMT'];

        // Add debug prints as requested
        debugPrint(' Fetched Image Limits ');
        debugPrint('Pre-Image Limit: $preImgLmt');
        debugPrint('Post-Image Limit: $postImgLmt');
        debugPrint('Final-Image Limit: $finalImgLmt');

        notifyListeners();
      } else {
        debugPrint("Image limits data is null or in an unexpected format.");
      }
      // --- FIX END ---
    } catch (e) {
      debugPrint("Failed to fetch image limits: $e");
    }
  }

  Future<void> login(
    String username,
    String password,
    BuildContext context,
  ) async {
    // 1. Log entry into login()
    debugPrint("🔑 AuthProvider.login() called with username: '$username'");

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 2. Fire off the network request
      final response = await _apiService.postRequest(
        ApiEndpoints.validateLogin,
        {"UserName": username, "Password": password},
      );
      debugPrint('-----------------------------------------------------------');
      // 3. Print out the raw response
      debugPrint("🌐 Login response JSON: $response");

      if (response["Status"] == 1) {
        // 4. Parse into your model
        user = UserModel.fromJson(response);
        debugPrint("✅ Parsed UserModel: ${user!.toJson()}");

        // 5. Persist it
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user", jsonEncode(user!.toJson()));
        debugPrint("💾 User saved to SharedPreferences under key 'user'");
        await fetchImageLimits(user!.buid);

        errorMessage = null;
      } else {
        errorMessage = response["Message"] ?? "Login Failed ❌";
        debugPrint("❌ Login failed: $errorMessage");
      }
    } catch (e) {
      errorMessage = "Error: $e";
      debugPrint("⚠️ Exception in login(): $e");
    } finally {
      isLoading = false;
      notifyListeners();
      debugPrint("🔄 AuthProvider.login() completed. isLoading = $isLoading");
      debugPrint('-----------------------------------------------------------');
    }
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user");
    if (userData != null) {
      final decoded = jsonDecode(userData);
      user = UserModel.fromJson(decoded);
      if (user != null) {
        await fetchImageLimits(user!.buid);
      }
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    // 1. Grab prefs and wipe everything
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 2. Reset in-memory user and notify UI
    user = null;
    preImgLmt = null;
    postImgLmt = null;
    finalImgLmt = null;
    notifyListeners();

    // 3. Drop all routes and show login
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }
}
