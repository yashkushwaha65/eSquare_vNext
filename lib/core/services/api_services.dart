import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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

    request.files.add(await http.MultipartFile.fromPath('file', file.path));
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
