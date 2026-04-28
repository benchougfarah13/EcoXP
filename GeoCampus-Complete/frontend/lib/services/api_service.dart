import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Fetch Player Profile
  static Future<Map<String, dynamic>> getProfile(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/profile/$username/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Fetch Leaderboard
  static Future<List<dynamic>> getLeaderboard() async {
    final response = await http.get(Uri.parse('$baseUrl/leaderboard/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  // Validate QR Event Check-in
  static Future<Map<String, dynamic>> validateEvent(String username, String qrSecret) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/validate/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'qr_secret': qrSecret,
      }),
    );
    return json.decode(response.body);
  }

  // Handle Scan Request with Image Upload
  static Future<Map<String, dynamic>> scanPlant(String username, String imagePath, double lat, double lng) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/game/scan/'));
    request.fields['username'] = username;
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    return json.decode(responseData);
  }
}
