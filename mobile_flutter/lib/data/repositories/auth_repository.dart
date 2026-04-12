import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> sendOtp(String phone) async {
    final response = await _dio.post('/auth/otp/', data: {
      'phone_number': phone,
      'role': 'rider', // Defaults to Rider based on prompt, though this is a driver repo
    });
    
    if (response.data['status'] != 'success') {
      throw Exception(response.data['message'] ?? 'Failed to send OTP');
    }
  }

  Future<String> verifyOtp(String phone, String otp) async {
    final response = await _dio.post('/auth/login/', data: {
      'phone_number': phone,
      'otp': otp,
    });

    if (response.data['status'] == 'success') {
      final token = response.data['data']['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      return token;
    } else {
      throw Exception(response.data['message'] ?? 'Invalid OTP');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
