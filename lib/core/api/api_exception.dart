import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalException;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalException,
  });

  factory ApiException.fromDioException(DioException dioException) {
    String message = 'An unexpected connection error occurred';
    int? statusCode = dioException.response?.statusCode;

    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout';
        break;
      case DioExceptionType.badCertificate:
        message = 'Bad certificate';
        break;
      case DioExceptionType.badResponse:
        statusCode = dioException.response?.statusCode;
        if (dioException.response?.data is Map) {
          final data = dioException.response!.data as Map;
          // Try to get message or detail from FAST API style errors
          message = data['message'] ??
              (data['detail'] is String
                  ? data['detail']
                  : (data['detail'] is List ? _parseDetails(data['detail']) : null)) ??
              'Bad response: ${dioException.response?.statusCode}';
        } else {
          message = 'Bad response: ${dioException.response?.statusCode}';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error: Check your internet connection';
        break;
      case DioExceptionType.unknown:
        message = dioException.message ?? 'Unknown error';
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      originalException: dioException,
    );
  }

  static String _parseDetails(dynamic detail) {
    if (detail is List) {
      return detail.map((e) {
        if (e is Map) {
          final msg = e['msg'] ?? 'Error';
          final loc = e['loc'] is List ? (e['loc'] as List).last : null;
          return loc != null ? '$loc: $msg' : msg;
        }
        return e.toString();
      }).join(', ');
    }
    return detail.toString();
  }

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
