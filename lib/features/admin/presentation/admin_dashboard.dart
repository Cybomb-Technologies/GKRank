import 'package:flutter/material.dart';
import '../../../core/api.dart';
import '../../../core/widgets/premium_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalCategories = 0;
  int _totalQuestions = 0;
  List<dynamic> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final userResponse = await _apiService.getAllUsers();
      final catResponse = await _apiService.getAllCategories();
      
      if (mounted) {
        setState(() {
          final users = userResponse.data as List;
          _totalUsers = users.length;
          _totalCategories = (catResponse.data as List).length;
          
          // Get 5 most recent users
          _recentUsers = users.reversed.take(5).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard Overview", style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total Users", 
                    _totalUsers.toString(), 
                    Icons.people_rounded, 
                    colorScheme.primary
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    "Categories", 
                    _totalCategories.toString(), 
                    Icons.category_rounded, 
                    colorScheme.secondary
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    "Platform Activity", 
                    "Active", 
                    Icons.bolt_rounded, 
                    colorScheme.tertiary
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Users List
                Expanded(
                  flex: 2,
                  child: PremiumCard(
                    title: "Recently Joined Users",
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentUsers.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final user = _recentUsers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(user['name']?[0]?.toUpperCase() ?? "?"),
                          ),
                          title: Text(user['name'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(user['email'] ?? ""),
                          trailing: Text(user['role'] ?? "user", style: TextStyle(color: colorScheme.outline, fontSize: 12)),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Quick Actions
                Expanded(
                  child: Column(
                    children: [
                       _buildActionTile(context, "Clear App Cache", Icons.cleaning_services_rounded, Colors.orange),
                       const SizedBox(height: 12),
                       _buildActionTile(context, "System Logs", Icons.terminal_rounded, Colors.blueGrey),
                       const SizedBox(height: 12),
                       _buildActionTile(context, "Backup Database", Icons.cloud_upload_rounded, Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return PremiumCard(
      title: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
