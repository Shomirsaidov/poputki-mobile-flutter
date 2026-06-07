import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    _token = prefs.getString('token');
    
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<bool> login(String phone) async {
    final res = await checkPhoneOrLogin(phone);
    return res != null && res['status'] == 'success';
  }

  Future<Map<String, dynamic>?> checkPhoneOrLogin(String phone, {String? password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Checking phone or logging in: $phone, password: $password');
      final Map<String, dynamic> requestData = {'phone': phone};
      if (password != null) {
        requestData['password'] = password;
      }

      final response = await _apiClient.post('/auth/login', data: requestData);
      print('Check/Login response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // If it was a successful login (Case 3 with password matching)
        if (data['token'] != null && data['user'] != null) {
          _token = data['token'];
          _user = User.fromJson(data['user']);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('user', jsonEncode(_user!.toJson()));

          _isLoading = false;
          notifyListeners();
          return {'status': 'success', 'user': _user};
        }

        // If it's a response with exists/hasPassword flags
        _isLoading = false;
        notifyListeners();
        return {
          'status': data['exists'] == false 
              ? 'needs_registration' 
              : (data['hasPassword'] == false ? 'needs_password_setup' : 'password_required'),
          'user': data['user']
        };
      }
    } catch (e) {
      print('Check/Login error: $e');
      if (e is DioException) {
        print('Dio error data: ${e.response?.data}');
        print('Dio error headers: ${e.response?.headers}');
        if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
          _errorMessage = 'Отсутствует подключение к интернету. Проверьте сеть.';
        } else {
          String? serverMsg;
          if (e.response?.data is Map) {
            serverMsg = e.response?.data['error']?.toString() ?? e.response?.data['message']?.toString();
          }
          _errorMessage = serverMsg ?? 'Ошибка входа. Попробуйте снова.';
        }
      } else {
        _errorMessage = 'Произошла непредвиденная ошибка';
      }
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> registerMobile({
    required String phone,
    required String password,
    required String name,
    required int age,
    required String sex,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Attempting mobile registration for: $name, age: $age, sex: $sex');
      final response = await _apiClient.post('/auth/register-mobile', data: {
        'phone': phone,
        'password': password,
        'name': name,
        'age': age,
        'sex': sex,
      });
      print('Mobile registration response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['token'];
        _user = User.fromJson(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Mobile registration error: $e');
      if (e is DioException) {
        String? serverMsg;
        if (e.response?.data is Map) {
          serverMsg = e.response?.data['error']?.toString();
        }
        _errorMessage = serverMsg ?? 'Ошибка регистрации. Попробуйте снова.';
      } else {
        _errorMessage = 'Произошла непредвиденная ошибка';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({required String name, required int age}) async {
    if (_user == null) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      print('Attempting registration for: $name, age: $age');
      final response = await _apiClient.post('/auth/register', data: {
        'id': _user!.id,
        'name': name,
        'age': age,
        'phone': _user!.phone,
      });
      print('Registration response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Registration error: $e');
      if (e is DioException) {
        print('Dio error data: ${e.response?.data}');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
