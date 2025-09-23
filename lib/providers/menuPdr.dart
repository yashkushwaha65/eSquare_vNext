import 'package:flutter/material.dart';

import '../api_endpoints.dart';
import '../core/services/api_services.dart';

class MenuProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _menus = [];

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<dynamic> get menus => _menus;

  Future<void> loadMenu(int userId, int buId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.postRequest(ApiEndpoints.getMenuName, {
        "UserID": userId,
        "BUID": buId,
      }, authToken: ApiEndpoints.menuAuthToken);

      if (response is List) {
        _menus = response;
      } else if (response is Map<String, dynamic>) {
        _menus = [response];
      } else {
        _menus = [];
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
