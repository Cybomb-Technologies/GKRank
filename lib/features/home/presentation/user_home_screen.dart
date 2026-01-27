import 'package:flutter/material.dart';
import '../../../core/api.dart';
import '../../../core/widgets/fade_in_animation.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'user_topics_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final String userName;
  final String? userId;

  const UserHomeScreen({super.key, required this.userName, this.userId});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _categories = [];
  List<dynamic> _subCategories = [];
  bool _isLoading = true;
  bool _isSingleCategory = false;
  String _singleCategoryName = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllCategories();
      final categories = response.data as List<dynamic>;

      setState(() {
        _categories = categories;
        _isSingleCategory = false; // Deprecated flag, keeping false
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInAnimation(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              "Hello, ${widget.userName}!",
                              style: textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 200),
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              _isSingleCategory
                                  ? "Explore topics in $_singleCategoryName"
                                  : "Pick a category to explore topics",
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width < 600 
                            ? (MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 3)
                            : (MediaQuery.of(context).size.width < 1200 ? 3 : 4),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _categories[index];
                          return FadeInAnimation(
                            delay: Duration(milliseconds: 400 + (index * 100)),
                            child: PremiumCard(
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.all(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserTopicsScreen(
                                      categoryName: item['name'],
                                    ),
                                  ),
                                );
                              },
                              title: '',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.category_rounded,
                                      color: colorScheme.primary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    item['name'] ?? 'Unnamed',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelLarge,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _categories.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
