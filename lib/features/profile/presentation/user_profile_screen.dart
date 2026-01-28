import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/data_repository.dart';
import '../../auth/user_login.dart';
import '../../profile/presentation/change_password_screen.dart';
import '../../../core/api.dart';
import '../../../core/theme/theme_controller.dart';
import 'profile_details_screen.dart';
import 'bookmarks_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userName;
  final String? userId;

  const UserProfileScreen({super.key, required this.userName, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final DataRepository _repo = DataRepository();
  List<Map<String, dynamic>> _progress = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProgress();
  }

  Future<void> _loadProfile() async {
     if (widget.userId == null) return;
     try {
       // Assuming getAllUsers as admin gives info, but for user we might need personal endpoint.
       // For now check local user data or repo.
       final data = await _repo.getUserSession();
       if (data != null) {
          setState(() {
            _userData = data;
          });
       }
     } catch (e) {
       //print("DEBUG - UserProfileScreen/_loadProfile : Error - $e");
     }
  }

  Future<void> _loadProgress() async {
    try {
      final data = await _repo.getGroupedProgress();
      setState(() {
        _progress = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isGuest = widget.userId == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.person, size: 35, color: colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                              widget.userName, 
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)
                            ),
                            if (_userData?['email'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _userData!['email'],
                                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                            if (isGuest) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Guest Mode",
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                              ),
                            ],
                        ],
                      ),
                    ),
                  ],
                ),
            ),
          ),
          
          const SizedBox(height: 24),
          // Navigation Options
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                if (!isGuest) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
                      child: Icon(Icons.badge_outlined, color: colorScheme.primary),
                    ),
                    title: const Text("Your Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("View your personal details"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileDetailsScreen(userName: widget.userName, userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(Icons.bookmarks_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                  title: const Text("Bookmarks", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Questions you've saved"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BookmarksListScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.themeMode,
                      builder: (context, mode, child) {
                        String modeText;
                        IconData modeIcon;
                        switch(mode) {
                          case ThemeMode.dark:
                            modeText = "Dark Theme";
                            modeIcon = Icons.dark_mode;
                            break;
                          case ThemeMode.light:
                            modeText = "Light Theme";
                            modeIcon = Icons.light_mode;
                            break;
                          default:
                            modeText = "System Default";
                            modeIcon = Icons.brightness_auto;
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                            child: Icon(modeIcon, color: Theme.of(context).colorScheme.onTertiaryContainer),
                          ),
                          title: const Text("Theme Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(modeText),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showThemeSelectionDialog(context, mode),
                        );
                      },
                    ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.contact_support_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  title: const Text("Contact Us", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Get in touch for help"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact: support@cybomb.com")));
                  },
                ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Progress Section
          Row(
             children: [
                 const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 const Spacer(),
                 if (!isGuest) 
                    TextButton.icon(
                        onPressed: () { 
                           // Manual Sync Trigger
                           if (widget.userId != null) {
                               _repo.syncLocalToRemote(widget.userId!);
                               _repo.syncBookmarksToRemote(widget.userId!);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing...")));
                           }
                        }, 
                        icon: const Icon(Icons.sync), 
                        label: const Text("Sync")
                    )
             ],
          ),
          const SizedBox(height: 10),
          
          _isLoading 
             ? const Center(child: CircularProgressIndicator())
             : _progress.isEmpty 
                ? Container(
                    padding: const EdgeInsets.all(32),
                    width: double.infinity,
                    decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.surfaceContainerHighest, 
                       borderRadius: BorderRadius.circular(12)
                    ),
                    child: Column(
                        children: [
                           Icon(Icons.bar_chart, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                           const SizedBox(height: 8),
                           Text("No progress yet. Start learning!", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ]
                    ),
                )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _progress.length > 5 ? 5 : _progress.length, // Show latest 5
                    itemBuilder: (context, index) {
                        final p = _progress[index];
                        final topic = p['topic'] ?? 'Unknown Topic';
                        final modes = p['modes'] as Map<String, dynamic>? ?? {};
                        
                        final date = p['timestamp'] != null 
                           ? DateTime.parse(p['timestamp']).toLocal().toString().split(' ')[0]
                           : "";
                        
                        return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Topic header
                                  Row(
                                    children: [
                                      Icon(Icons.topic, color: Theme.of(context).colorScheme.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          topic, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (date.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Last activity: $date",
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  // Mode data
                                  ...modes.entries.map((entry) {
                                    final mode = entry.key;
                                    final modeData = entry.value as Map<String, dynamic>;
                                    final score = modeData['score']?.toString() ?? '-';
                                    final total = modeData['total']?.toString() ?? '0';
                                    final completed = modeData['completed'] ?? false;
                                    
                                    // Calculate percentage
                                    double percentage = 0;
                                    if (total != '0' && score != '-') {
                                      percentage = (int.tryParse(score) ?? 0) / (int.tryParse(total) ?? 1) * 100;
                                    }
                                    
                                    Color modeColor = mode == 'Learn' 
                                        ? colorScheme.primary 
                                        : (mode == 'Practice' ? colorScheme.secondary : colorScheme.error);
                                    IconData modeIcon = mode == 'Learn' ? Icons.school : (mode == 'Practice' ? Icons.fitness_center : Icons.quiz);
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(modeIcon, color: modeColor, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              mode,
                                              style: TextStyle(fontSize: 14, color: modeColor, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          if (mode == 'Learn')
                                            Icon(
                                              completed ? Icons.check_circle : Icons.circle_outlined,
                                               color: completed ? const Color(0xFF2EC4B6) : colorScheme.outlineVariant,
                                              size: 18,
                                            )
                                          else
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "$score/$total",
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "(${percentage.toStringAsFixed(0)}%)",
                                                  style: TextStyle(fontSize: 12, color: modeColor),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                        );
                    }
                ),
          const SizedBox(height: 32),
          if (isGuest)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text("Sign In / Register"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, widget.userId!),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Theme.of(context).colorScheme.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Theme"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text("System Default"),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) ThemeController.setTheme(mode);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Light Mode"),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) ThemeController.setTheme(mode);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Dark Mode"),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) ThemeController.setTheme(mode);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, String userId) {
    bool keepData = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Confirm Logout"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Are you sure you want to log out?"),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text("Keep my progress and bookmarks on this device"),
                value: keepData,
                onChanged: (val) => setDialogState(() => keepData = val ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!keepData) {
                  await _repo.wipeUserData(userId);
                }
                await _repo.clearSession();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }

}
