import 'package:app/core/utils/route/app_routes.dart';
import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/login/cubit/login_cubit.dart';
import 'package:app/features/settings/repositories/settings_repository.dart';
import 'package:app/features/settings/views/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int selectedTab = 0; // 0: General, 1: Team, 2: Security
  List<TeamMember> teamMembers = [];
  late SecuritySettings securitySettings;
  bool isLoading = true;

  // Text controllers for General tab
  late TextEditingController fullNameController;
  late TextEditingController roleController;
  late TextEditingController usernameController;

  // Text controllers for Security tab
  late TextEditingController newPasswordController;
  bool isChangingPassword = false;
  bool isUpdatingUsername = false;
  bool isUpdatingRole = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    fullNameController = TextEditingController();
    roleController = TextEditingController();
    usernameController = TextEditingController();
    newPasswordController = TextEditingController();
  }

  void _loadData() async {
    try {
      // Read user from LoginCubit state
      final loginState = context.read<LoginCubit>().state;
      if (loginState is LoginSuccess) {
        final user = loginState.loginResponse.user;
        fullNameController.text = user.fullName ?? '';
        roleController.text = user.role;
        usernameController.text = user.username;
      }

      // Fetch data from real API using Repository
      final repo = SettingsRepository();
      try {
        final securityData = await repo.getSecuritySettings();
        securitySettings = SecuritySettings.fromJson(securityData);

        final membersResponse = await repo.getTeamMembers();
        teamMembers = membersResponse.members
            .map(
              (m) => TeamMember(
                id: m.id ?? UniqueKey().toString(),
                name: m.name ?? m.username ?? 'Unknown Member',
                username: m.username ?? 'unknown',
                role: m.role ?? 'Team Member',
                avatar:
                    m.avatar ??
                    (m.name != null && m.name!.isNotEmpty
                        ? m.name![0]
                        : (m.username != null && m.username!.isNotEmpty
                              ? m.username![0]
                              : '?')),
                joinedDate: m.joinedDate ?? DateTime.now(),
              ),
            )
            .toList();
      } catch (e) {
        debugPrint('Error loading settings from API: $e');
        // Fallback or keep current if appropriate
        if (e.toString().contains('404')) {
          teamMembers = [];
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateUsername() async {
    final newUsername = usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username cannot be empty')));
      return;
    }

    final loginState = context.read<LoginCubit>().state;
    if (loginState is! LoginSuccess) return;

    final user = loginState.loginResponse.user;
    if (newUsername == user.username) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes detected')));
      return;
    }

    setState(() => isUpdatingUsername = true);
    try {
      final repo = SettingsRepository();
      await repo.changeUsername(userId: user.id, newUsername: newUsername);

      if (!mounted) return;
      context.read<LoginCubit>().updateUserInfo(username: newUsername);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Username updated successfully'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update username: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) setState(() => isUpdatingUsername = false);
    }
  }

  Future<void> _updateRole() async {
    final newRole = roleController.text.trim();
    if (newRole.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Role cannot be empty')));
      return;
    }

    final loginState = context.read<LoginCubit>().state;
    if (loginState is! LoginSuccess) return;

    final user = loginState.loginResponse.user;
    if (newRole == user.role) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes detected')));
      return;
    }

    setState(() => isUpdatingRole = true);
    try {
      final repo = SettingsRepository();
      await repo.changeRole(userId: user.id, newRole: newRole);

      if (!mounted) return;
      context.read<LoginCubit>().updateUserInfo(role: newRole);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Role updated successfully'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) setState(() => isUpdatingRole = false);
    }
  }

  Future<void> _changePassword() async {
    if (newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    // Get user ID from login state
    final loginState = context.read<LoginCubit>().state;
    if (loginState is! LoginSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please login again.'),
        ),
      );
      return;
    }

    final userId = loginState.loginResponse.user.id;

    setState(() => isChangingPassword = true);

    try {
      final repo = SettingsRepository();
      await repo.changePassword(
        userId: userId,
        newPassword: newPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully'),
          backgroundColor: Colors.green[600],
        ),
      );
      newPasswordController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change password: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) setState(() => isChangingPassword = false);
    }
  }

  void _handleLogout() {
    debugPrint('Logout button tapped. Initiating logout sequence...');
    context.read<LoginCubit>().logout();
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddMemberDialog(
        onMemberAdded: () {
          setState(() {
            isLoading = true;
          });
          _loadData();
        },
      ),
    );
  }

  void _showMemberOptions(TeamMember member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveConfirmation(member);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveConfirmation(TeamMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                teamMembers.removeWhere((m) => m.id == member.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} removed'),
                  backgroundColor: Colors.green[600],
                ),
              );
            },
            child: Text('Remove', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    roleController.dispose();
    usernameController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LogoutSuccess || state is LoginInitial) {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        } else if (state is LoginError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 44.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28.0),
                _buildTabButtons(),
                const SizedBox(height: 24.0),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(LucideIcons.settings, color: AppColors.blue, size: 28),
        const SizedBox(width: 12),
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabButton('General', 0),
          const SizedBox(width: 12),
          _buildTabButton('Team', 1),
          const SizedBox(width: 12),
          _buildTabButton('Security', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int tabIndex) {
    final isActive = selectedTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = tabIndex),
      child: Container(
        height: 37.0,
        width: 113.0,
        decoration: BoxDecoration(
          color: isActive ? AppColors.blue : Colors.white,
          border: Border.all(
            color: isActive ? AppColors.blue : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTabIcon(tabIndex),
                size: 18,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTabIcon(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.people_outline;
      case 2:
        return Icons.shield_outlined;
      default:
        return Icons.settings_outlined;
    }
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 0:
        return _buildGeneralTab();
      case 1:
        return _buildTeamTab();
      case 2:
        return _buildSecurityTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextFieldWithAction(
                  'Username',
                  usernameController,
                  'Update Username',
                  _updateUsername,
                  isUpdatingUsername,
                ),
                const SizedBox(height: 20),
                _buildTextFieldWithAction(
                  'Role',
                  roleController,
                  'Update Role',
                  _updateRole,
                  isUpdatingRole,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Logout Button
          Material(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _handleLogout,
              splashColor: Colors.red[100],
              highlightColor: Colors.red[100]!.withOpacity(0.5),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.logOut, color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Team Members',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage access and roles',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            GestureDetector(
              onTap: _showAddMemberDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Add Member',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: teamMembers.length,
            itemBuilder: (context, index) {
              final member = teamMembers[index];
              return _buildTeamMemberCard(member);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMemberCard(TeamMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.avatar,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.role,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[400]),
            onPressed: () => _showMemberOptions(member),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'New Password',
              newPasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: isChangingPassword ? null : _changePassword,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 150.0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isChangingPassword
                          ? [Colors.grey[400]!, Colors.grey[500]!]
                          : [Colors.blue[600]!, Colors.purple[600]!],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isChangingPassword
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Change Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldWithAction(
    String label,
    TextEditingController controller,
    String actionLabel,
    VoidCallback onAction,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(label, controller),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: isLoading ? null : onAction,
            child: Container(
              width: 130.0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLoading
                      ? [Colors.grey[400]!, Colors.grey[500]!]
                      : [Colors.blue[600]!, Colors.purple[600]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      actionLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// Add Member Dialog
class AddMemberDialog extends StatefulWidget {
  final VoidCallback onMemberAdded;
  const AddMemberDialog({Key? key, required this.onMemberAdded})
    : super(key: key);

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  late TextEditingController usernameController;
  late TextEditingController roleController;
  late TextEditingController passwordController;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    roleController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    roleController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Team Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: 'User Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roleController,
              decoration: InputDecoration(
                hintText: 'Role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isAdding ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isAdding
              ? null
              : () async {
                  final username = usernameController.text.trim().toLowerCase();
                  final role = roleController.text.trim().toLowerCase();
                  final password = passwordController.text.trim();

                  if (username.isEmpty || role.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  setState(() => isAdding = true);

                  try {
                    final repo = SettingsRepository();
                    await repo.addTeamMember(
                      username: username,
                      password: password,
                      role: role,
                    );

                    if (!mounted) return;
                    widget.onMemberAdded();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Member added successfully'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add member: $e'),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => isAdding = false);
                  }
                },
          child: isAdding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
