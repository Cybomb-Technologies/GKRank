// lib/features/admin/presentation/admin_main_screen.dart
import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'category/category_list_screen.dart';
import 'user/user_list_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final String userName;
  final String? userId;

  const AdminMainScreen({super.key, required this.userName, this.userId});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  // Define the screens for the admin panel
  late final List<Widget> _adminPages = [
    const AdminDashboard(),
    const CategoryListScreen(),
    const UserListScreen(),
    const Center(child: Text("Settings", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Future Menu Placeholder", style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR (Navigation Rail)
          NavigationRail(
            selectedIndex: _selectedIndex,
            extended: true, // Shows labels next to icons
            minExtendedWidth: 200,
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("Administrator", style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 20),
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.more_horiz),
                selectedIcon: Icon(Icons.more_horiz),
                label: Text('Future Menus'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // MAIN CONTENT AREA
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(_getAppBarTitle()),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => Navigator.of(context).pop(), // Return to login
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              body: Container(
                color: colorScheme.background,
                child: _adminPages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return "Dashboard";
      case 1: return "Category Management";
      case 2: return "User Management";
      case 3: return "System Settings";
      default: return "Admin Section";
    }
  }
}
