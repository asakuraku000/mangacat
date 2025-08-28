
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CategoryTabs extends StatelessWidget {
  final List<Map<String, String>> categories;
  final Function(String) onCategoryChanged;
  final String selectedGenre;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.onCategoryChanged,
    required this.selectedGenre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedGenre == category['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onCategoryChanged(category['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentOrange
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentOrange
                        : AppColors.surfaceColor,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    category['name']!,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.creamWhite
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
