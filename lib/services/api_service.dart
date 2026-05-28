// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'https://regatta.fhettinga.nl/api';

  /// Login — returns {'token', 'email'}
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw data['error'] as String? ?? 'Inloggen mislukt.';
    }
    return data;
  }

  /// Register — returns {'token', 'email'}
  Future<Map<String, dynamic>> register(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw data['error'] as String? ?? 'Registratie mislukt.';
    }
    return data;
  }

  /// Get user profile from server
  Future<Map<String, dynamic>> getProfile(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Update user profile (boat type, boat name, team name)
  Future<void> updateProfile(String token, Map<String, dynamic> fields) async {
    final res = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(fields),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw data['error'] as String? ?? 'Profiel opslaan mislukt.';
    }
  }

  /// Lookup race code — returns race/class info
  Future<Map<String, dynamic>> lookupCode(String token, String code) async {
    final res = await http.get(
      Uri.parse('$baseUrl/join/${code.toUpperCase().trim()}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw data['error'] as String? ?? 'Onbekende code.';
    }
    return data;
  }

  /// Upload GPX file. Optionally include wind_direction_deg.
  /// Throws 'already_on_server' on 409.
  Future<void> uploadTrack(
    File gpxFile,
    String token, {
    double? windDirectionDeg,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/tracks'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'gpx',
      gpxFile.path,
      filename: gpxFile.uri.pathSegments.last,
    ));
    if (windDirectionDeg != null) {
      request.fields['wind_direction_deg'] = windDirectionDeg.toString();
    }
    final streamed = await request.send();
    if (streamed.statusCode == 409) throw 'already_on_server';
    if (streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      throw data['error'] as String? ?? 'Upload mislukt (${streamed.statusCode}).';
    }
  }

  /// Link a track to a race/class via participation code
  Future<void> joinWithCode(String token, String code, int trackId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/join'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code.toUpperCase().trim(), 'track_id': trackId}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw data['error'] as String? ?? 'Koppelen mislukt.';
    }
  }

  /// List server tracks — returns [{id, filename, ...}, ...]
  Future<List<Map<String, dynamic>>> listTracks(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tracks'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }
}
