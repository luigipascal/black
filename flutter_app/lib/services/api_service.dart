import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrl = kDebugMode 
      ? 'http://localhost:3001/api'
      : 'https://your-production-server.com/api';
  
  static const String _wsUrl = kDebugMode
      ? 'ws://localhost:3001'
      : 'wss://your-production-server.com';
  
  static ApiService? _instance;
  String? _authToken;
  
  ApiService._internal();
  
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }
  
  // Initialize with stored token
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }
  
  // Get headers with authentication
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  // Store auth token
  Future<void> _storeToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Clear auth token
  Future<void> _clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Handle API errors
  void _handleError(http.Response response) {
    final Map<String, dynamic> errorData;
    try {
      errorData = json.decode(response.body);
    } catch (e) {
      throw ApiException('Network error: ${response.statusCode}');
    }
    
    final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
    
    switch (response.statusCode) {
      case 400:
        throw ApiException('Bad request: $errorMessage');
      case 401:
        _clearToken();
        throw UnauthorizedException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 409:
        throw ConflictException(errorMessage);
      case 429:
        throw RateLimitException(errorMessage);
      case 500:
        throw ServerException(errorMessage);
      default:
        throw ApiException('HTTP ${response.statusCode}: $errorMessage');
    }
  }
  
  // Generic HTTP methods
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _handleError(response);
        return {};
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e');
    }
  }
  
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        _handleError(response);
        return {};
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e');
    }
  }
  
  Future<Map<String, dynamic>> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        _handleError(response);
        return {};
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e');
    }
  }
  
  Future<bool> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        _handleError(response);
        return false;
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e');
    }
  }
  
  // Authentication endpoints
  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _post('/auth/register', {
      'email': email,
      'username': username,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
    
    final token = response['token'] as String;
    await _storeToken(token);
    
    return AuthResponse.fromJson(response);
  }
  
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    
    final token = response['token'] as String;
    await _storeToken(token);
    
    return AuthResponse.fromJson(response);
  }
  
  Future<UserProfile> getProfile() async {
    final response = await _get('/auth/profile');
    return UserProfile.fromJson(response['user']);
  }
  
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    Map<String, dynamic>? preferences,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (preferences != null) data['preferences'] = preferences;
    
    await _put('/auth/profile', data);
  }
  
  Future<void> updateReadingProgress({
    int? currentPage,
    int? revelationLevel,
    List<String>? charactersDiscovered,
    List<Map<String, dynamic>>? bookmarks,
  }) async {
    final data = <String, dynamic>{};
    if (currentPage != null) data['currentPage'] = currentPage;
    if (revelationLevel != null) data['revelationLevel'] = revelationLevel;
    if (charactersDiscovered != null) data['charactersDiscovered'] = charactersDiscovered;
    if (bookmarks != null) data['bookmarks'] = bookmarks;
    
    await _put('/auth/reading-progress', data);
  }
  
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _put('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
  
  Future<void> refreshToken() async {
    final response = await _post('/auth/refresh', {});
    final token = response['token'] as String;
    await _storeToken(token);
  }
  
  Future<void> logout() async {
    try {
      await _post('/auth/logout', {});
    } catch (e) {
      // Logout can fail, but we still want to clear local token
    } finally {
      await _clearToken();
    }
  }
  
  // Collaboration endpoints
  Future<List<CollaborationRoom>> getRooms() async {
    final response = await _get('/collaboration/rooms');
    return (response['rooms'] as List)
        .map((room) => CollaborationRoom.fromJson(room))
        .toList();
  }
  
  Future<CollaborationRoom> createRoom({
    required String name,
    String? description,
    required String roomType,
    int? maxParticipants,
  }) async {
    final response = await _post('/collaboration/rooms', {
      'name': name,
      'description': description,
      'roomType': roomType,
      'maxParticipants': maxParticipants,
    });
    
    return CollaborationRoom.fromJson(response['room']);
  }
  
  Future<CollaborationRoom> joinRoom(String roomCode) async {
    final response = await _post('/collaboration/rooms/join', {
      'roomCode': roomCode,
    });
    
    return CollaborationRoom.fromJson(response['room']);
  }
  
  Future<void> leaveRoom(int roomId) async {
    await _post('/collaboration/rooms/$roomId/leave', {});
  }
  
  // Analytics endpoints
  Future<void> trackEvent({
    required String eventType,
    Map<String, dynamic>? eventData,
    int? pageIndex,
    String? characterInitials,
    int? revelationLevel,
    int? durationSeconds,
  }) async {
    await _post('/analytics/events', {
      'eventType': eventType,
      'eventData': eventData,
      'pageIndex': pageIndex,
      'characterInitials': characterInitials,
      'revelationLevel': revelationLevel,
      'durationSeconds': durationSeconds,
    });
  }
  
  Future<Map<String, dynamic>> getAnalytics() async {
    return await _get('/analytics/user');
  }
  
  // Check authentication status
  bool get isAuthenticated => _authToken != null;
  
  String? get authToken => _authToken;
  
  String get websocketUrl => _wsUrl;
}

// Data models
class AuthResponse {
  final String message;
  final String token;
  final UserProfile user;
  
  AuthResponse({
    required this.message,
    required this.token,
    required this.user,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'],
      token: json['token'],
      user: UserProfile.fromJson(json['user']),
    );
  }
}

class UserProfile {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String role;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> readingProgress;
  final DateTime createdAt;
  
  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.role,
    required this.preferences,
    required this.readingProgress,
    required this.createdAt,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      avatarUrl: json['avatarUrl'],
      role: json['role'],
      preferences: json['preferences'] ?? {},
      readingProgress: json['readingProgress'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class CollaborationRoom {
  final int id;
  final String name;
  final String? description;
  final String roomCode;
  final String roomType;
  final int maxParticipants;
  final List<RoomParticipant> participants;
  
  CollaborationRoom({
    required this.id,
    required this.name,
    this.description,
    required this.roomCode,
    required this.roomType,
    required this.maxParticipants,
    required this.participants,
  });
  
  factory CollaborationRoom.fromJson(Map<String, dynamic> json) {
    return CollaborationRoom(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      roomCode: json['roomCode'],
      roomType: json['roomType'],
      maxParticipants: json['maxParticipants'],
      participants: (json['participants'] as List?)
          ?.map((p) => RoomParticipant.fromJson(p))
          .toList() ?? [],
    );
  }
}

class RoomParticipant {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String role;
  
  RoomParticipant({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
  });
  
  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      id: json['id'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: json['role'],
    );
  }
}

// Exception classes
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class ConflictException extends ApiException {
  ConflictException(String message) : super(message);
}

class RateLimitException extends ApiException {
  RateLimitException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}