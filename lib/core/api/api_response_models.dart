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

  @JsonKey(name: 'invalid_products', defaultValue: 0)
  final int invalidProducts;

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
    this.invalidProducts = 0,
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

class SessionResponse {
  final String sessionId;
  final int id;
  final DateTime startTime;
  final DateTime? stopTime;
  final int? userId;

  SessionResponse({
    required this.sessionId,
    required this.id,
    required this.startTime,
    this.stopTime,
    this.userId,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      sessionId: json['session_id']?.toString() ?? '',
      id: json['session_id'].hashCode,
      startTime: DateTime.parse(json['created_at']),
      stopTime: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      userId: json['user_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'created_at': startTime.toIso8601String(),
    'expires_at': stopTime?.toIso8601String(),
    'user_id': userId,
  };
}

class MotorStatusResponse {
  final String status;
  final String motorStatus;
  final double currentAmps;
  final String plcLogicalState;
  final String? message;

  MotorStatusResponse({
    required this.status,
    required this.motorStatus,
    required this.currentAmps,
    required this.plcLogicalState,
    this.message,
  });

  factory MotorStatusResponse.fromJson(Map<String, dynamic> json) {
    return MotorStatusResponse(
      status: json['status']?.toString() ?? '',
      motorStatus: json['motor_status']?.toString() ?? 'UNKNOWN',
      currentAmps: (json['current_amps'] as num?)?.toDouble() ?? 0.0,
      plcLogicalState: json['plc_logical_state']?.toString() ?? 'UNKNOWN',
      message: json['message']?.toString(),
    );
  }
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

class MotorTimelineEntryResponse {
  final String state;
  final DateTime startTime;
  final DateTime endTime;

  MotorTimelineEntryResponse({
    required this.state,
    required this.startTime,
    required this.endTime,
  });

  factory MotorTimelineEntryResponse.fromJson(Map<String, dynamic> json) {
    return MotorTimelineEntryResponse(
      state: json['state']?.toString() ?? 'OFFLINE',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
    );
  }
}

class MotorTimelineResponse {
  final String date;
  final List<MotorTimelineEntryResponse> timeline;

  MotorTimelineResponse({required this.date, required this.timeline});

  factory MotorTimelineResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> items = json['timeline'] ?? [];
    return MotorTimelineResponse(
      date: json['date']?.toString() ?? '',
      timeline: items
          .map(
            (e) =>
                MotorTimelineEntryResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

// ============ QUALITY LOG RESPONSES ============

@JsonSerializable()
class QualityItemResponse {
  @JsonKey(name: 'id', fromJson: _idFromJson)
  final String id;
  final String title;
  final String type;
  final String status;
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
  @JsonKey(defaultValue: false)
  final bool isUploading; // ← add this

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
    this.isUploading = false, // ← add this
  });

  static String _idFromJson(dynamic id) => id?.toString() ?? '';

  factory QualityItemResponse.fromJson(Map<String, dynamic> json) {
    String status = json['status'] ?? 'pending';
    final statusLower = status.toLowerCase();

    // Only guess a defect type when the item is genuinely in the "defected"
    // bucket. "good" has no defect, and "invalid" means the inspection was
    // discarded — neither should be labeled with an invented defect type.
    String type;
    if (statusLower == 'good') {
      type = 'good';
    } else if (statusLower == 'invalid') {
      type = 'invalid';
    } else {
      type = json['defect_type'] ?? json['type'] ?? 'unknown_defect';
    }

    String title = statusLower == 'good'
        ? 'Good'
        : statusLower == 'invalid'
        ? 'Invalid'
        : (json['title'] ?? type);

    // Handle confidence/confidence_score
    double confidence = (json['confidence'] ?? json['confidence_score'] ?? 0)
        .toDouble();

    // Handle image_path/image_url/cv_image_url and common API variants.
    final rawImageUrl =
        json['cv_image_url'] ??
        json['image_path'] ??
        json['image_url'] ??
        json['imageUrl'] ??
        json['cvImageUrl'] ??
        json['cloudinary_url'] ??
        json['cloudinaryUrl'] ??
        json['url'];
    final bool isUploading = rawImageUrl == 'uploading_in_background';

    String? imageUrl = rawImageUrl;
    if (imageUrl == null || imageUrl.isEmpty || isUploading) {
      imageUrl = null;
    }

    // Handle created_at/inspected_at
    DateTime createdAt =
        DateTime.tryParse(json['inspected_at'] ?? json['created_at'] ?? '') ??
        DateTime.now();

    final bool isConfirmed = json['is_confirmed'] ?? false;

    return QualityItemResponse(
      id: _idFromJson(json['inspection_id'] ?? json['id']),
      title: title,
      type: type,
      status: status,
      confidenceScore: confidence,
      imageUrl: imageUrl,
      createdAt: createdAt,
      actionTaken: json['action_taken'],
      isConfirmed: isConfirmed,
      defectCategory: json['defect_type'] ?? json['defect_category'],
      isUploading: isUploading,
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
  @JsonKey(name: 'role')
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
  @JsonKey(fromJson: _stringFromJson)
  final String? id;
  @JsonKey(fromJson: _stringFromJson)
  final String? name;
  @JsonKey(fromJson: _stringFromJson)
  final String? role;
  @JsonKey(fromJson: _stringFromJson)
  final String? username;
  final String? avatar;
  @JsonKey(name: 'joined_date')
  final DateTime? joinedDate;

  static String? _stringFromJson(dynamic value) => value?.toString();

  TeamMemberResponse({
    this.id,
    this.name,
    this.role,
    this.username,
    this.avatar,
    this.joinedDate,
  });

  factory TeamMemberResponse.fromJson(Map<String, dynamic> json) {
    // Support both 'id' and 'user_id'
    if (json.containsKey('user_id') && json['id'] == null) {
      json['id'] = json['user_id'];
    }
    // Support 'access_role' for 'role'
    if (json.containsKey('access_role') && json['role'] == null) {
      json['role'] = json['access_role'];
    }

    if (json.containsKey('user_role') && json['role'] == null) {
      json['role'] = json['user_role'];
    }
    // Support 'full_name' for 'name'
    if (json.containsKey('full_name') && json['name'] == null) {
      json['name'] = json['full_name'];
    }
    return _$TeamMemberResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TeamMemberResponseToJson(this);
}

@JsonSerializable()
class TeamMembersListResponse {
  final List<TeamMemberResponse> members;
  final int total;

  TeamMembersListResponse({required this.members, required this.total});

  factory TeamMembersListResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('users') && json['members'] == null) {
      json['members'] = json['users'];
    }
    if (json.containsKey('data') && json['members'] == null) {
      json['members'] = json['data'];
    }
    // Set total if missing
    if (json['total'] == null && json['members'] is List) {
      json['total'] = (json['members'] as List).length;
    }
    return _$TeamMembersListResponseFromJson(json);
  }

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

// ============ AUTH/LOGIN RESPONSES ============

@JsonSerializable()
class LoginResponse {
  final String token;
  @JsonKey(name: 'session_id')
  final String sessionId;
  final UserProfileResponse user;

  LoginResponse({
    required this.token,
    required this.sessionId,
    required this.user,
  });

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
    final sessionId = json['session_id'] ?? '';

    return LoginResponse(
      token: token as String,
      sessionId: sessionId as String,
      user: user,
    );
  }

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  LoginResponse copyWith({
    String? token,
    String? sessionId,
    UserProfileResponse? user,
  }) {
    return LoginResponse(
      token: token ?? this.token,
      sessionId: sessionId ?? this.sessionId,
      user: user ?? this.user,
    );
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
