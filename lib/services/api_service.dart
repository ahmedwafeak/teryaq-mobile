import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Live Vercel Production API Gateway
  static String baseUrl = 'https://teryaq-backend-six.vercel.app/api';

  static void setBaseUrl(String newUrl) {
    if (newUrl.isNotEmpty) {
      baseUrl = newUrl.endsWith('/') ? newUrl.substring(0, newUrl.length - 1) : newUrl;
    }
  }

  /// Google Account Authentication
  static Future<Map<String, dynamic>> googleAuth(String email, String displayName, String googleId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'displayName': displayName,
              'googleId': googleId,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'تعذر الاتصال ببروتوكول Google: $e'};
    }
  }

  /// Lookup Pharmacy Barcode
  static Future<Map<String, dynamic>> lookupBarcode(String barcodeCode) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/medication/barcode/$barcodeCode'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل فحص الباركود: $e'};
    }
  }

  /// Get Patient Medications Schedule
  static Future<Map<String, dynamic>> getUserMedications(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/medication/user/$userId'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'تعذر جلب الأدوية: $e'};
    }
  }

  /// Add New Medication via Barcode to Account
  static Future<Map<String, dynamic>> addMedication({
    required String userId,
    required String barcode,
    required String name,
    required String dosage,
    required String time,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/medication/add'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'barcode': barcode,
              'name': name,
              'dosage': dosage,
              'time': time,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل إضافة الدواء: $e'};
    }
  }

  /// Verify invite code & bind device
  static Future<Map<String, dynamic>> verifyInvite(String code, String deviceUuid) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-invite'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'inviteCode': code, 'deviceUuid': deviceUuid}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'تعذر الاتصال بالخادم: $e'};
    }
  }

  /// Notify backend that alarm started ringing
  static Future<Map<String, dynamic>> triggerAlarm(String doseId, String patientName, String medName, String caregiverPhone) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/alarm/trigger'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'doseId': doseId,
              'patientName': patientName,
              'medicationName': medName,
              'caregiverPhone': caregiverPhone,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تفعيل المنبه بالخادم: $e'};
    }
  }

  /// Submit AI Photo verification
  static Future<Map<String, dynamic>> submitVerification(String doseId, double confidence, String detectedText) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/alarm/verify-dose'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'doseId': doseId,
              'confidenceScore': confidence,
              'detectedText': detectedText,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل إرسال نتائج التحقق: $e'};
    }
  }
}
