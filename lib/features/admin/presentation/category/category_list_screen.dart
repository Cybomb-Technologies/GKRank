import 'package:flutter/material.dart';
import '../../../../core/api.dart';
import '../../../../core/widgets/premium_card.dart';
import 'category_details_screen.dart';
import 'create_category_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _categories = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _apiService.getAllCategories();
      setState(() {
        _categories = response.data;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshCategories() async {
    setState(() => _isRefreshing = true);
    await _fetchCategories();
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: colorScheme.outline.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            "No Categories Yet",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your first category to get started",
            style: TextStyle(color: colorScheme.outline),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreate(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Create Category"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = _getCategoryColor(index);

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailsScreen(category: category),
          ),
        ).then((_) => _fetchCategories());
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(index),
                color: cardColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),

            // Category Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'] ?? 'Unnamed Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage sub-categories and topics",
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Indicator
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outline.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.error,
      colorScheme.primary.withOpacity(0.8),
      colorScheme.secondary.withOpacity(0.8),
      colorScheme.tertiary.withOpacity(0.8),
      const Color(0xFF2EC4B6), // Brand Teal
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(int index) {
    final icons = [
      Icons.science_rounded,
      Icons.calculate_rounded,
      Icons.language_rounded,
      Icons.history_edu_rounded,
      Icons.psychology_rounded,
      Icons.architecture_rounded,
      Icons.music_note_rounded,
      Icons.computer_rounded,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Category Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _refreshCategories,
            tooltip: "Refresh",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text("New Category"),
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text("Loading categories...", style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshCategories,
        child: _categories.isEmpty
            ? _buildEmptyState()
            : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Summary Card
            PremiumCard(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Categories",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _categories.length.toString(),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.category_rounded,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              "Available Categories",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Category List
            ...List.generate(_categories.length, (index) {
              final category = _categories[index];
              return _buildCategoryCard(category, index);
            }),
            
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCategoryScreen(),
      ),
    );
    _fetchCategories();
  }
}
