import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/frostcore_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>>? _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    setState(() {
      _userProfileFuture = FrostCoreAPI.getUserProfile(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text('Failed to load profile.'));
          }

          final user = snapshot.data!;
          final name = user['nickname']?.isNotEmpty == true
              ? user['nickname']
              : user['username'] ?? 'User';
          final email = user['email'] ?? '';
          final role = user['role'] ?? 'member';
          final profilePic = (user['profilePic']?.isNotEmpty ?? false)
              ? user['profilePic']
              : 'https://ui-avatars.com/api/?name=$name';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(profilePic),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(role.toUpperCase()),
                          backgroundColor: Colors.blue.shade100,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  onTap: () {
                    // Navigator.pushNamed(context, '/editProfile');
                  },
                ),
                _buildOptionTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    // Navigator.pushNamed(context, '/settings');
                  },
                ),
                _buildOptionTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    // handle logout
                  },
                  iconColor: Colors.red,
                  textColor: Colors.red,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blue),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
