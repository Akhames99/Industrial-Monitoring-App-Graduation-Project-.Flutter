import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_exception.dart';

/// ================== API CONFIG ==================
class ApiConfig {
  static const String baseUrl = 'https://backend-api-db-ds3m.onrender.com';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// ================== ENDPOINTS ==================
class Endpoints {
  // Login Page
  static const String login = '/login';

  // Settings Page
  static const String logout = '/logout';
  static const String getUsers = '/users';
  static const String addTeamMember = '/admin/create-user';
  static const String changePassword = '/edit-password/{user_id}';
  static const String changeUsername = '/edit-username/{user_id}';
  static const String editRole = '/edit-role/{user_id}';
  static const String deleteUser = '/delete-user/{user_id}';

  // Home Page
  static const String motorTimeLine = '/motor/timeline';

  // Control Page
  static const String motorControl = '/motor/control';
  static const String motorStatus = '/motor/status';
  static const String setSpeed = '/belt/speed';
  static const String beltStatus = '/belt/speed-status';
  static const String startMachine = '/machine/start';
  static const String stopMachine = '/machine/stop';

  //Quality Page
  static const String getQualityData = '/inspections';
  static const String confirmInspection =
      '/inspections/{inspection_id}/confirm';
  static const String editInspection = '/inspections/{inspection_id}/edit';
  static const String deleteImage = '/inspections/{inspection_id}/delete_image';
  static const String reviewedInspections = '/inspections/reviewed';
  static const String pendingReviewInspections = '/inspections/pending-review';
  static const String getQualityDataBySession =
      '/inspections/session/{session_id}';
  static const String qualityDetail = '/quality/items/{id}';

  // Analytics Page
  static const String aiConfidence = '/analytics/ai-confidence';
  static const String hourlyDefects = '/analytics/hourly-defects';
}

/// ================== API CLIENT ==================
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static const String _tokenKey = 'auth_token';
  static const String _sessionStorageKey = 'x_session_id';

  // Bounds for the ai-confidence analytics timeframe query param.
  static const int minAiConfidenceTimeframeDays = 1;
  static const int maxAiConfidenceTimeframeDays = 30;
  static const int defaultAiConfidenceTimeframeDays = 7;

  late Dio _dio;
  String? _authToken;
  String? _sessionId;

  String? get sessionId => _sessionId;
  String? get authToken => _authToken;

  // Navigator key for global navigation (set by MyApp)
  static void Function()? onSessionExpired;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    final options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(options);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_authToken != null) {
      options.headers['Authorization'] = 'Bearer $_authToken';
    }
    // Only set x-session-id if we have an actual session ID — never fall back to the auth token
    if (_sessionId != null) {
      options.headers['x-session-id'] = _sessionId;
    }
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    // Because validateStatus accepts any status < 500, a 401 (expired/invalid
    // session) arrives here as a normal response, not a DioException — so
    // session-expiry has to be detected here rather than in _onError.
    if (response.statusCode == 401) {
      clearAuthToken();
      onSessionExpired?.call();
    }
    handler.next(response);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    // Kept as a safety net in case validateStatus is ever changed to treat
    // 401 as an error status (which would route it here instead).
    if (error.response?.statusCode == 401) {
      // Session expired — clear credentials and redirect to login
      clearAuthToken();
      onSessionExpired?.call();
    }
    handler.next(error);
  }

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    _sessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_sessionStorageKey);
    await prefs.remove('saved_user');
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    return _authToken;
  }

  Future<void> setSessionId(String sessionId) async {
    _sessionId = sessionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionStorageKey, sessionId);
  }

  Future<void> loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString(_sessionStorageKey);
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetches AI confidence analytics for the given [timeframeDays].
  ///
  /// [timeframeDays] is clamped to the API's supported range
  /// (1-30, default 7) before the request is sent.
  Future<Response> getAiConfidenceStats({
    int timeframeDays = defaultAiConfidenceTimeframeDays,
  }) async {
    final clampedDays = timeframeDays.clamp(
      minAiConfidenceTimeframeDays,
      maxAiConfidenceTimeframeDays,
    );
    return get(
      Endpoints.aiConfidence,
      queryParameters: {'timeframe_days': clampedDays},
    );
  }

  String withId(String endpoint, dynamic id) =>
      endpoint.replaceAll('{id}', id.toString());
  String withUserId(String endpoint, dynamic userId) =>
      endpoint.replaceAll('{user_id}', userId.toString());
}
