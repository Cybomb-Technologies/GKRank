import 'package:flutter/material.dart';
import '../../../../core/api.dart';
import '../../../../core/widgets/premium_card.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    final colorScheme = Theme.of(context).colorScheme;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a category name"),
          backgroundColor: colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _apiService.createCategory(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Category '$name' created successfully"),
            backgroundColor: colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Category"),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            PremiumCard(
              color: colorScheme.primary.withOpacity(0.05),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_to_photos_rounded,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "New Category",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          "Start organizing your educational content",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form
            Text(
              "Category Details",
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.outline,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            
            PremiumCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Category Name",
                      hintText: "e.g., Mathematics, Physics",
                      prefixIcon: const Icon(Icons.category_rounded),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This name will be visible to all users in the main directory.",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _saveCategory,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text("Create"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
