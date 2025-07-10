import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/category/add_category.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/Screen/Sheetal/category/category_detail.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  Stream<List<Category>>? _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = _firebaseService.getCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.categories),
      ),
      body: StreamBuilder<List<Category>>(
        stream: _categoriesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Utility.circleloading();
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppStrings.genericError + snapshot.error.toString()));
          }
          final allCategories = snapshot.data ?? [];
          final searchText = _searchController.text.toLowerCase();
          final filteredCategories = allCategories.where((category) {
            return category.name.toLowerCase().contains(searchText);
          }).toList();

          return GenericListView<Category>(
            items: filteredCategories,
            isLoading: false,
            emptyMessage: AppStrings.nocategories,
            searchController: _searchController,
            onSearch: (_) => setState(() {}),
            searchText: searchText,
            getTitle: (category) => category.name,
            getSubtitle: (category) => '${category.percentage.toInt()}%',
            getInitials: (category) => category.name.isNotEmpty
                ? category.name.substring(0, min(2, category.name.length)).toUpperCase()
                : '',
            onItemTap: (category) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(category: category),
                ),
              );
              if (result == true) {
              }
            },
          );
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCategoryScreen(),
            ),
          );
        },
      ),
    );
  }
}
