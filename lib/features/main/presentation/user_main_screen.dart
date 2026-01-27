import 'package:flutter/material.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../auth/user_login.dart';
import '../../home/presentation/user_home_screen.dart';
import '../../profile/presentation/user_profile_screen.dart';
import '../../../core/data_repository.dart';

class UserMainScreen extends StatefulWidget {
  final String userName;
  final String? userId;

  const UserMainScreen({super.key, required this.userName, this.userId});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final DataRepository _repo = DataRepository();

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _syncOnStartup();
    }
  }

  void _syncOnStartup() async {
    // Refresh all data from server if online
    await _repo.fetchRemoteToLocal(widget.userId!);
    await _repo.fetchBookmarksToLocal(widget.userId!);
    await _repo.fetchLevelStatesToLocal(widget.userId!);
    if (mounted) setState(() {}); // Refresh UI with new data
  }

  late final List<Widget> _pages = [
    UserHomeScreen(userName: widget.userName, userId: widget.userId),
    UserProfileScreen(userName: widget.userName, userId: widget.userId),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showLogoutDialog(BuildContext context, String userId) {
    bool keepData = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Confirm Logout"),
          content: SingleChildScrollView(
            child: Column(
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isGuest = widget.userId == null;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          _onItemTapped(0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "GK",
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.normal,
              fontSize: 24,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) async {
                  if (value == 'logout') {
                    if (isGuest) {
                       // Just clear guest session
                       await _repo.clearSession();
                       if (mounted) {
                         Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                          (route) => false,
                        );
                       }
                    } else {
                       _showLogoutDialog(context, widget.userId!);
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(isGuest ? Icons.login : Icons.logout, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(isGuest ? "Login" : "Logout"),
                        ],
                      ),
                    ),
                  ];
                },
                child: Icon(Icons.more_vert, color: colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            if (ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context))
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                labelType: NavigationRailLabelType.all,
                backgroundColor: colorScheme.surface,
                indicatorColor: colorScheme.primaryContainer,
                selectedIconTheme: IconThemeData(color: colorScheme.primary),
                unselectedIconTheme: IconThemeData(color: colorScheme.outline),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                children: _pages,
              ),
            ),
          ],
        ),
        bottomNavigationBar: ResponsiveLayout.isMobile(context)
            ? Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
