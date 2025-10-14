// lib/core/services/api_services.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class ApiService {
  Future<dynamic> postRequest(
    String url,
    Map<String, dynamic> payload, {
    String? authToken,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "accept": "application/json",
        if (authToken != null) "authToken": authToken,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    } else {
      throw Exception("Failed request: ${response.body}");
    }
  }

  Future<dynamic> postFormUrlEncodedRequest(
    String url,
    Map<String, String> body, {
    String? authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'accept': 'application/json',
          if (authToken != null) 'authToken': authToken,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed request: ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to connect: $e");
    }
  }

  Future<dynamic> uploadFile(
    String url,
    File file, {
    String? authToken,
    required Map<String, String> fields,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    if (authToken != null) request.headers["authToken"] = authToken;

    // --- FIX START ---
    // Appending a timestamp to the filename ensures that each new photo uploaded
    // during an edit has a unique name, preventing the "file exists" error from the server.
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename:
            '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    // --- FIX END ---

    request.fields.addAll(fields);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Upload failed: ${response.body}");
    }
  }
}
