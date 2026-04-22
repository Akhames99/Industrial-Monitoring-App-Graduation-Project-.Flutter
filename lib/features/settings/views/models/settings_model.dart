// User Profile Model
class UserProfile {
  final String id;
  final String fullName;
  final String role;
  final String email;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.email,
    required this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? role,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Team Member Model
class TeamMember {
  final String id;
  final String name;
  final String role;
  final String username;
  final String avatar;
  final DateTime joinedDate;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.username,
    required this.avatar,
    required this.joinedDate,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      joinedDate: DateTime.parse(
        json['joinedDate'] ?? json['joined_date'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'username': username,
      'avatar': avatar,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }
}

// Security Settings Model
class SecuritySettings {
  final String userId;
  final bool twoFactorEnabled;
  final List<String> authorizedDevices;
  final DateTime lastPasswordChange;
  final DateTime lastLogin;

  SecuritySettings({
    required this.userId,
    this.twoFactorEnabled = false,
    this.authorizedDevices = const [],
    required this.lastPasswordChange,
    required this.lastLogin,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      userId: json['user_id']?.toString() ?? '',
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      authorizedDevices: List<String>.from(json['authorized_devices'] ?? []),
      lastPasswordChange: DateTime.parse(
        json['last_password_change'] ?? DateTime.now().toString(),
      ),
      lastLogin: DateTime.parse(json['last_login'] ?? DateTime.now().toString()),
    );
  }

  SecuritySettings copyWith({
    String? userId,
    bool? twoFactorEnabled,
    List<String>? authorizedDevices,
    DateTime? lastPasswordChange,
    DateTime? lastLogin,
  }) {
    return SecuritySettings(
      userId: userId ?? this.userId,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      authorizedDevices: authorizedDevices ?? this.authorizedDevices,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

// Settings Service
class SettingsService {
  static const String baseUrl = 'https://your-api.com/api';

  // Fetch user profile
  Future<UserProfile> fetchUserProfile() async {
    try {
      // TODO: Replace with actual API call
      return UserProfile(
        id: '1',
        fullName: 'Mohammad Ali',
        role: 'Production Manager',
        email: 'mohammad.A@nexus.com',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      );
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      // TODO: Replace with actual API call
      return true;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Fetch team members
  Future<List<TeamMember>> fetchTeamMembers() async {
    try {
      // TODO: Replace with actual API call
      return [
        TeamMember(
          id: '1',
          name: 'Mohammad A.',
          username: 'mohammad_a',
          role: 'Prod Manager',
          avatar: 'M',
          joinedDate: DateTime.now().subtract(const Duration(days: 365)),
        ),
        TeamMember(
          id: '2',
          name: 'Sarah M.',
          username: 'sarah_m',
          role: 'Operator',
          avatar: 'S',
          joinedDate: DateTime.now().subtract(const Duration(days: 200)),
        ),
        TeamMember(
          id: '3',
          name: 'Ahmed B.',
          username: 'ahmed_b',
          role: 'AI Specialist',
          avatar: 'M',
          joinedDate: DateTime.now().subtract(const Duration(days: 150)),
        ),
        TeamMember(
          id: '4',
          name: 'Omar E.',
          username: 'omar_e',
          role: 'Support',
          avatar: 'S',
          joinedDate: DateTime.now().subtract(const Duration(days: 100)),
        ),
      ];
    } catch (e) {
      throw Exception('Failed to fetch team members: $e');
    }
  }

  // Add team member
  Future<bool> addTeamMember(TeamMember member) async {
    try {
      // TODO: Replace with actual API call
      return true;
    } catch (e) {
      throw Exception('Failed to add team member: $e');
    }
  }

  // Remove team member
  Future<bool> removeTeamMember(String memberId) async {
    try {
      // TODO: Replace with actual API call
      return true;
    } catch (e) {
      throw Exception('Failed to remove team member: $e');
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      // TODO: Replace with actual API call
      return true;
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Fetch security settings
  Future<SecuritySettings> fetchSecuritySettings() async {
    try {
      // TODO: Replace with actual API call
      return SecuritySettings(
        userId: '1',
        twoFactorEnabled: false,
        authorizedDevices: [],
        lastPasswordChange: DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
      );
    } catch (e) {
      throw Exception('Failed to fetch security settings: $e');
    }
  }
}

// Mock data
class SettingsMockData {
  static final userProfile = UserProfile(
    id: '1',
    fullName: 'Mohammad Ali',
    role: 'Production Manager',
    email: 'mohammad.A@nexus.com',
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );

  static final teamMembers = [
    TeamMember(
      id: '1',
      name: 'Mohammad A.',
      username: 'mohammad_a',
      role: 'Prod Manager',
      avatar: 'M',
      joinedDate: DateTime.now().subtract(const Duration(days: 365)),
    ),
    TeamMember(
      id: '2',
      name: 'Sarah M.',
      username: 'sarah_m',
      role: 'Operator',
      avatar: 'S',
      joinedDate: DateTime.now().subtract(const Duration(days: 200)),
    ),
    TeamMember(
      id: '3',
      name: 'Ahmed B.',
      username: 'ahmed_b',
      role: 'AI Specialist',
      avatar: 'M',
      joinedDate: DateTime.now().subtract(const Duration(days: 150)),
    ),
    TeamMember(
      id: '4',
      name: 'Omar E.',
      username: 'omar_e',
      role: 'Support',
      avatar: 'S',
      joinedDate: DateTime.now().subtract(const Duration(days: 100)),
    ),
  ];

  static final securitySettings = SecuritySettings(
    userId: '1',
    twoFactorEnabled: false,
    authorizedDevices: [],
    lastPasswordChange: DateTime.now().subtract(const Duration(days: 30)),
    lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
  );
}
