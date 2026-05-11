import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_exception.dart';

/// ================== API CONFIG ==================
class ApiConfig {
  static const String baseUrl = 'https://gp26-ckys.onrender.com';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// ================== ENDPOINTS ==================
class Endpoints {
  // Authentication
  static const String login = '/login';
  static const String logout = '/logout';

  // Home Page
  static const String startSession = '/start-session';
  static const String stopSession = '/stop-session';

  // Control Page
  static const String sessions = '/sessions';
  static const String activeSession = '/session-status';
  static const String machineStatus = '/machine/status';
  static const String startMachine = '/machine/start';
  static const String stopMachine = '/machine/stop';
  static const String setSpeed = '/machine/speed';

  // Quality Log
  static const String getQualityData = '/inspections';
  static const String getQualityDataBySession =
      '/inspections/session/{session_id}';
  static const String confirmInspection =
      '/inspections/{inspection_id}/confirm';
  static const String editInspection =
      '/inspections/{inspection_id}/Edit-Inspection';
  static const String qualityItems = '/quality/items';
  static const String qualityDetail = '/quality/items/{id}';
  static const String confirmDefection = '/quality/confirm';
  static const String relabelItem = '/quality/relabel';
  static const String dismissItem = '/quality/dismiss';
  static const String sendToDataset = '/quality/dataset';

  // Settings
  static const String userProfile = '/settings/profile';
  static const String updateProfile = '/settings/profile';
  static const String teamMembers = '/settings/team';
  static const String addTeamMember = '/create-user';
  static const String removeTeamMember = '/settings/team/{id}';
  static const String changePassword = '/edit-password/{user_id}';
  static const String changeUsername = '/edit-username/{user_id}';
  static const String editRole = '/edit-role/{user_id}';
  static const String securitySettings = '/settings/security';
}

/// ================== API CLIENT ==================
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static const String _tokenKey = 'auth_token';

  late Dio _dio;
  String? _authToken;

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

  /// ================== INTERCEPTORS ==================
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_authToken != null) {
      options.headers['Authorization'] = 'Bearer $_authToken';
    }
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    if (error.response?.statusCode == 401) {
      // TODO: handle refresh token or logout
    }
    handler.next(error);
  }

  /// ================== AUTH ==================
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    return _authToken;
  }

  /// ================== REQUEST METHODS ==================
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

  String withId(String endpoint, dynamic id) {
    return endpoint.replaceAll('{id}', id.toString());
  }

  String withUserId(String endpoint, dynamic userId) {
    return endpoint.replaceAll('{user_id}', userId.toString());
  }
}
