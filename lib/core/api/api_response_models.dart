import 'package:json_annotation/json_annotation.dart';

part 'api_response_models.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  @JsonKey(defaultValue: false)
  final bool success;
  @JsonKey(defaultValue: '')
  final String message;
  final T? data;
  final List<String>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}

// ============ HOME PAGE RESPONSES ============

@JsonSerializable()
class SystemStatusResponse {
  @JsonKey(name: 'current_state')
  final String currentState;

  @JsonKey(name: 'last_12_hours')
  final List<StateSegmentResponse> segments;

  @JsonKey(name: 'uptime_percentage')
  final double uptimePercentage;

  SystemStatusResponse({
    required this.currentState,
    required this.segments,
    required this.uptimePercentage,
  });

  factory SystemStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$SystemStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SystemStatusResponseToJson(this);
}

@JsonSerializable()
class StateSegmentResponse {
  final String state; // 'running', 'error', 'idle'
  @JsonKey(name: 'start_hour')
  final int startHour;
  @JsonKey(name: 'end_hour')
  final int endHour;

  StateSegmentResponse({
    required this.state,
    required this.startHour,
    required this.endHour,
  });

  factory StateSegmentResponse.fromJson(Map<String, dynamic> json) =>
      _$StateSegmentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StateSegmentResponseToJson(this);
}

@JsonSerializable()
class ProductionYieldResponse {
  @JsonKey(name: 'good_products')
  final int goodProducts;

  @JsonKey(name: 'defective_products')
  final int defectiveProducts;

  @JsonKey(name: 'total_products')
  final int totalProducts;

  @JsonKey(name: 'yield_percentage')
  final double yieldPercentage;

  @JsonKey(name: 'period')
  final String period; // 'today', 'week', 'month', 'year'

  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  ProductionYieldResponse({
    required this.goodProducts,
    required this.defectiveProducts,
    required this.totalProducts,
    required this.yieldPercentage,
    required this.period,
    required this.timestamp,
  });

  factory ProductionYieldResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductionYieldResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProductionYieldResponseToJson(this);
}

@JsonSerializable()
class DefectionResponse {
  @JsonKey(name: 'total_defects')
  final int totalDefects;

  final List<DefectCategoryResponse> categories;

  @JsonKey(name: 'period')
  final String period;

  @JsonKey(name: 'timestamp')
  final DateTime timestamp;

  DefectionResponse({
    required this.totalDefects,
    required this.categories,
    required this.period,
    required this.timestamp,
  });

  factory DefectionResponse.fromJson(Map<String, dynamic> json) =>
      _$DefectionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DefectionResponseToJson(this);
}

@JsonSerializable()
class DefectCategoryResponse {
  final String name;
  final int count;
  final double percentage;
  final String color;

  DefectCategoryResponse({
    required this.name,
    required this.count,
    required this.percentage,
    required this.color,
  });

  factory DefectCategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$DefectCategoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DefectCategoryResponseToJson(this);
}

@JsonSerializable()
class AlertResponse {
  final String id;
  final String title;
  final String description;
  final String severity; // 'warning', 'critical', 'info'
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_acknowledged')
  final bool isAcknowledged;

  AlertResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.createdAt,
    required this.isAcknowledged,
  });

  factory AlertResponse.fromJson(Map<String, dynamic> json) =>
      _$AlertResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AlertResponseToJson(this);
}

// ============ CONTROL PAGE RESPONSES ============

@JsonSerializable()
class ActiveSessionResponse {
  @JsonKey(name: 'is_running')
  final bool isActive;
  @JsonKey(name: 'start_time')
  final DateTime? startTime;

  ActiveSessionResponse({required this.isActive, this.startTime});

  factory ActiveSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$ActiveSessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveSessionResponseToJson(this);
}

@JsonSerializable()
class SessionResponse {
  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @JsonKey(name: 'end_time')
  final DateTime? stopTime;
  @JsonKey(name: 'user_id')
  final int? userId;

  SessionResponse({
    required this.id,
    required this.startTime,
    this.stopTime,
    this.userId,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionResponseToJson(this);
}

@JsonSerializable()
class MachineStatusResponse {
  @JsonKey(name: 'is_running')
  final bool isRunning;

  @JsonKey(name: 'current_speed')
  final int currentSpeed;

  @JsonKey(name: 'target_speed')
  final int targetSpeed;

  @JsonKey(name: 'start_time')
  final DateTime? startTime;

  @JsonKey(name: 'stop_time')
  final DateTime? stopTime;

  @JsonKey(name: 'uptime_seconds')
  final int uptimeSeconds;

  MachineStatusResponse({
    required this.isRunning,
    required this.currentSpeed,
    required this.targetSpeed,
    this.startTime,
    this.stopTime,
    required this.uptimeSeconds,
  });

  factory MachineStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$MachineStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MachineStatusResponseToJson(this);
}

// ============ QUALITY LOG RESPONSES ============

@JsonSerializable()
class QualityItemResponse {
  @JsonKey(name: 'id', fromJson: _idFromJson)
  final String id;
  final String title;
  final String type; // 'cracks', 'scratch', 'label', 'dents', 'misalignment'
  final String status; // 'pending', 'reviewed', or 'rotten', etc.
  @JsonKey(name: 'confidence_score')
  final double confidenceScore;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'action_taken')
  final String? actionTaken;
  @JsonKey(name: 'is_confirmed')
  final bool isConfirmed;
  @JsonKey(name: 'defect_category')
  final String? defectCategory;

  QualityItemResponse({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.confidenceScore,
    this.imageUrl,
    required this.createdAt,
    this.actionTaken,
    required this.isConfirmed,
    this.defectCategory,
  });

  static String _idFromJson(dynamic id) => id?.toString() ?? '';

  factory QualityItemResponse.fromJson(Map<String, dynamic> json) {
    // Determine title/type from status if missing
    String status = json['status'] ?? 'pending';
    String title = json['title'] ?? status;
    String type = json['type'] ?? 'cracks';

    // Handle confidence/confidence_score
    double confidence = (json['confidence'] ?? json['confidence_score'] ?? 0)
        .toDouble();

    // Handle image_path/image_url
    String? imageUrl = json['image_path'] ?? json['image_url'];

    // Handle created_at
    DateTime createdAt =
        DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();

    return QualityItemResponse(
      id: _idFromJson(json['id']),
      title: title,
      type: type,
      status: status,
      confidenceScore: confidence,
      imageUrl: imageUrl,
      createdAt: createdAt,
      actionTaken: json['action_taken'],
      isConfirmed: json['is_confirmed'] ?? false,
      defectCategory: json['defect_category'],
    );
  }

  Map<String, dynamic> toJson() => _$QualityItemResponseToJson(this);
}

@JsonSerializable()
class QualityItemsListResponse {
  final List<QualityItemResponse> items;
  final int total;
  @JsonKey(name: 'pending_count')
  final int pendingCount;
  @JsonKey(name: 'reviewed_count')
  final int reviewedCount;

  QualityItemsListResponse({
    required this.items,
    required this.total,
    required this.pendingCount,
    required this.reviewedCount,
  });

  factory QualityItemsListResponse.fromJson(Map<String, dynamic> json) =>
      _$QualityItemsListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$QualityItemsListResponseToJson(this);
}

// ============ SETTINGS RESPONSES ============

@JsonSerializable()
class UserProfileResponse {
  @JsonKey(name: 'user_id', fromJson: _idFromJson)
  final String id;

  static String _idFromJson(dynamic id) => id?.toString() ?? '';
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String role;
  final String username;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  UserProfileResponse({
    required this.id,
    this.fullName,
    required this.role,
    required this.username,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$UserProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileResponseToJson(this);

  UserProfileResponse copyWith({
    String? id,
    String? fullName,
    String? role,
    String? username,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileResponse(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class TeamMemberResponse {
  final String? id;
  final String? name;
  final String? role;
  final String? username;
  final String? avatar;
  @JsonKey(name: 'joined_date')
  final DateTime? joinedDate;

  TeamMemberResponse({
    this.id,
    this.name,
    this.role,
    this.username,
    this.avatar,
    this.joinedDate,
  });

  factory TeamMemberResponse.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMemberResponseToJson(this);
}

@JsonSerializable()
class TeamMembersListResponse {
  final List<TeamMemberResponse> members;
  final int total;

  TeamMembersListResponse({required this.members, required this.total});

  factory TeamMembersListResponse.fromJson(Map<String, dynamic> json) =>
      _$TeamMembersListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMembersListResponseToJson(this);
}

// ============ REQUEST MODELS ============

@JsonSerializable()
class StartMachineRequest {
  @JsonKey(name: 'target_speed')
  final int targetSpeed;

  StartMachineRequest({required this.targetSpeed});

  factory StartMachineRequest.fromJson(Map<String, dynamic> json) =>
      _$StartMachineRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartMachineRequestToJson(this);
}

@JsonSerializable()
class SetSpeedRequest {
  @JsonKey(name: 'target_speed')
  final int targetSpeed;

  SetSpeedRequest({required this.targetSpeed});

  factory SetSpeedRequest.fromJson(Map<String, dynamic> json) =>
      _$SetSpeedRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetSpeedRequestToJson(this);
}

@JsonSerializable()
class UpdateProfileRequest {
  @JsonKey(name: 'full_name')
  final String fullName;
  final String role;
  final String username;

  UpdateProfileRequest({
    required this.fullName,
    required this.role,
    required this.username,
  });

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}

@JsonSerializable()
class ChangePasswordRequest {
  @JsonKey(name: 'current_password')
  final String currentPassword;
  @JsonKey(name: 'new_password')
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}

@JsonSerializable()
class AddTeamMemberRequest {
  final String role;
  final String username;
  final String password;

  AddTeamMemberRequest({
    required this.role,
    required this.username,
    required this.password,
  });

  factory AddTeamMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$AddTeamMemberRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddTeamMemberRequestToJson(this);
}

@JsonSerializable()
class RelabelItemRequest {
  @JsonKey(name: 'new_label')
  final String newLabel;

  RelabelItemRequest({required this.newLabel});

  factory RelabelItemRequest.fromJson(Map<String, dynamic> json) =>
      _$RelabelItemRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RelabelItemRequestToJson(this);
}

// ============ AUTH/LOGIN RESPONSES ============

@JsonSerializable()
class LoginResponse {
  final String token;
  final UserProfileResponse user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // 1. If it's already structured as expected: {token: ..., user: {...}}
    if (json.containsKey('user') && json['user'] is Map) {
      return _$LoginResponseFromJson(json);
    }

    // 2. If it's a flat object: {user_id: ..., username: ..., role: ..., token/access_token: ...}
    // We try to extract user profile first
    final user = UserProfileResponse.fromJson(json);

    // We try to find the token in several common keys
    final token = json['token'] ?? json['access_token'] ?? json['jwt'] ?? '';

    return LoginResponse(token: token as String, user: user);
  }

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  LoginResponse copyWith({String? token, UserProfileResponse? user}) {
    return LoginResponse(token: token ?? this.token, user: user ?? this.user);
  }
}

@JsonSerializable()
class LogoutResponse {
  final bool success;

  LogoutResponse({required this.success});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutResponseToJson(this);
}

// ============ AUTH/LOGIN REQUESTS ============

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}
