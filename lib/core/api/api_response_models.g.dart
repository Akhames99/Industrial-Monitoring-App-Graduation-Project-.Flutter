// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResponse<T> _$ApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiResponse<T>(
  success: json['success'] as bool? ?? false,
  message: json['message'] as String? ?? '',
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  errors: (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$ApiResponseToJson<T>(
  ApiResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'errors': instance.errors,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

SystemStatusResponse _$SystemStatusResponseFromJson(
  Map<String, dynamic> json,
) => SystemStatusResponse(
  currentState: json['current_state'] as String,
  segments: (json['last_12_hours'] as List<dynamic>)
      .map((e) => StateSegmentResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  uptimePercentage: (json['uptime_percentage'] as num).toDouble(),
);

Map<String, dynamic> _$SystemStatusResponseToJson(
  SystemStatusResponse instance,
) => <String, dynamic>{
  'current_state': instance.currentState,
  'last_12_hours': instance.segments,
  'uptime_percentage': instance.uptimePercentage,
};

StateSegmentResponse _$StateSegmentResponseFromJson(
  Map<String, dynamic> json,
) => StateSegmentResponse(
  state: json['state'] as String,
  startHour: (json['start_hour'] as num).toInt(),
  endHour: (json['end_hour'] as num).toInt(),
);

Map<String, dynamic> _$StateSegmentResponseToJson(
  StateSegmentResponse instance,
) => <String, dynamic>{
  'state': instance.state,
  'start_hour': instance.startHour,
  'end_hour': instance.endHour,
};

ProductionYieldResponse _$ProductionYieldResponseFromJson(
  Map<String, dynamic> json,
) => ProductionYieldResponse(
  goodProducts: (json['good_products'] as num).toInt(),
  defectiveProducts: (json['defective_products'] as num).toInt(),
  totalProducts: (json['total_products'] as num).toInt(),
  yieldPercentage: (json['yield_percentage'] as num).toDouble(),
  period: json['period'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$ProductionYieldResponseToJson(
  ProductionYieldResponse instance,
) => <String, dynamic>{
  'good_products': instance.goodProducts,
  'defective_products': instance.defectiveProducts,
  'total_products': instance.totalProducts,
  'yield_percentage': instance.yieldPercentage,
  'period': instance.period,
  'timestamp': instance.timestamp.toIso8601String(),
};

DefectionResponse _$DefectionResponseFromJson(Map<String, dynamic> json) =>
    DefectionResponse(
      totalDefects: (json['total_defects'] as num).toInt(),
      categories: (json['categories'] as List<dynamic>)
          .map(
            (e) => DefectCategoryResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      period: json['period'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$DefectionResponseToJson(DefectionResponse instance) =>
    <String, dynamic>{
      'total_defects': instance.totalDefects,
      'categories': instance.categories,
      'period': instance.period,
      'timestamp': instance.timestamp.toIso8601String(),
    };

DefectCategoryResponse _$DefectCategoryResponseFromJson(
  Map<String, dynamic> json,
) => DefectCategoryResponse(
  name: json['name'] as String,
  count: (json['count'] as num).toInt(),
  percentage: (json['percentage'] as num).toDouble(),
  color: json['color'] as String,
);

Map<String, dynamic> _$DefectCategoryResponseToJson(
  DefectCategoryResponse instance,
) => <String, dynamic>{
  'name': instance.name,
  'count': instance.count,
  'percentage': instance.percentage,
  'color': instance.color,
};

AlertResponse _$AlertResponseFromJson(Map<String, dynamic> json) =>
    AlertResponse(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isAcknowledged: json['is_acknowledged'] as bool,
    );

Map<String, dynamic> _$AlertResponseToJson(AlertResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'severity': instance.severity,
      'created_at': instance.createdAt.toIso8601String(),
      'is_acknowledged': instance.isAcknowledged,
    };

MachineStatusResponse _$MachineStatusResponseFromJson(
  Map<String, dynamic> json,
) => MachineStatusResponse(
  isRunning: json['is_running'] as bool,
  currentSpeed: (json['current_speed'] as num).toInt(),
  targetSpeed: (json['target_speed'] as num).toInt(),
  startTime: json['start_time'] == null
      ? null
      : DateTime.parse(json['start_time'] as String),
  stopTime: json['stop_time'] == null
      ? null
      : DateTime.parse(json['stop_time'] as String),
  uptimeSeconds: (json['uptime_seconds'] as num).toInt(),
);

Map<String, dynamic> _$MachineStatusResponseToJson(
  MachineStatusResponse instance,
) => <String, dynamic>{
  'is_running': instance.isRunning,
  'current_speed': instance.currentSpeed,
  'target_speed': instance.targetSpeed,
  'start_time': instance.startTime?.toIso8601String(),
  'stop_time': instance.stopTime?.toIso8601String(),
  'uptime_seconds': instance.uptimeSeconds,
};

QualityItemResponse _$QualityItemResponseFromJson(Map<String, dynamic> json) =>
    QualityItemResponse(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      actionTaken: json['action_taken'] as String?,
    );

Map<String, dynamic> _$QualityItemResponseToJson(
  QualityItemResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'type': instance.type,
  'status': instance.status,
  'confidence_score': instance.confidenceScore,
  'image_url': instance.imageUrl,
  'created_at': instance.createdAt.toIso8601String(),
  'action_taken': instance.actionTaken,
};

QualityItemsListResponse _$QualityItemsListResponseFromJson(
  Map<String, dynamic> json,
) => QualityItemsListResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => QualityItemResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  pendingCount: (json['pending_count'] as num).toInt(),
  reviewedCount: (json['reviewed_count'] as num).toInt(),
);

Map<String, dynamic> _$QualityItemsListResponseToJson(
  QualityItemsListResponse instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'pending_count': instance.pendingCount,
  'reviewed_count': instance.reviewedCount,
};

UserProfileResponse _$UserProfileResponseFromJson(Map<String, dynamic> json) =>
    UserProfileResponse(
      id: UserProfileResponse._idFromJson(json['user_id']),
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      username: json['username'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserProfileResponseToJson(
  UserProfileResponse instance,
) => <String, dynamic>{
  'user_id': instance.id,
  'full_name': instance.fullName,
  'role': instance.role,
  'username': instance.username,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

TeamMemberResponse _$TeamMemberResponseFromJson(Map<String, dynamic> json) =>
    TeamMemberResponse(
      id: json['id'] as String?,
      name: json['name'] as String?,
      role: json['role'] as String?,
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      joinedDate: json['joined_date'] == null
          ? null
          : DateTime.parse(json['joined_date'] as String),
    );

Map<String, dynamic> _$TeamMemberResponseToJson(TeamMemberResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'role': instance.role,
      'username': instance.username,
      'avatar': instance.avatar,
      'joined_date': instance.joinedDate?.toIso8601String(),
    };

TeamMembersListResponse _$TeamMembersListResponseFromJson(
  Map<String, dynamic> json,
) => TeamMembersListResponse(
  members: (json['members'] as List<dynamic>)
      .map((e) => TeamMemberResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$TeamMembersListResponseToJson(
  TeamMembersListResponse instance,
) => <String, dynamic>{'members': instance.members, 'total': instance.total};

StartMachineRequest _$StartMachineRequestFromJson(Map<String, dynamic> json) =>
    StartMachineRequest(targetSpeed: (json['target_speed'] as num).toInt());

Map<String, dynamic> _$StartMachineRequestToJson(
  StartMachineRequest instance,
) => <String, dynamic>{'target_speed': instance.targetSpeed};

SetSpeedRequest _$SetSpeedRequestFromJson(Map<String, dynamic> json) =>
    SetSpeedRequest(targetSpeed: (json['target_speed'] as num).toInt());

Map<String, dynamic> _$SetSpeedRequestToJson(SetSpeedRequest instance) =>
    <String, dynamic>{'target_speed': instance.targetSpeed};

UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequest(
  fullName: json['full_name'] as String,
  role: json['role'] as String,
  username: json['username'] as String,
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  UpdateProfileRequest instance,
) => <String, dynamic>{
  'full_name': instance.fullName,
  'role': instance.role,
  'username': instance.username,
};

ChangePasswordRequest _$ChangePasswordRequestFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequest(
  currentPassword: json['current_password'] as String,
  newPassword: json['new_password'] as String,
);

Map<String, dynamic> _$ChangePasswordRequestToJson(
  ChangePasswordRequest instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'new_password': instance.newPassword,
};

AddTeamMemberRequest _$AddTeamMemberRequestFromJson(
  Map<String, dynamic> json,
) => AddTeamMemberRequest(
  role: json['role'] as String,
  username: json['username'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$AddTeamMemberRequestToJson(
  AddTeamMemberRequest instance,
) => <String, dynamic>{
  'role': instance.role,
  'username': instance.username,
  'password': instance.password,
};

RelabelItemRequest _$RelabelItemRequestFromJson(Map<String, dynamic> json) =>
    RelabelItemRequest(newLabel: json['new_label'] as String);

Map<String, dynamic> _$RelabelItemRequestToJson(RelabelItemRequest instance) =>
    <String, dynamic>{'new_label': instance.newLabel};

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      token: json['token'] as String,
      user: UserProfileResponse.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{'token': instance.token, 'user': instance.user};

LogoutResponse _$LogoutResponseFromJson(Map<String, dynamic> json) =>
    LogoutResponse(success: json['success'] as bool);

Map<String, dynamic> _$LogoutResponseToJson(LogoutResponse instance) =>
    <String, dynamic>{'success': instance.success};

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  username: json['username'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };
