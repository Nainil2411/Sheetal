import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/Screen/Sheetal/category/edit_category.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/user_detail_common.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Category _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  Future<void> _deleteCategory() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });

        try {
          final success = await _firebaseService.deleteCategory(_category.id!);

          if (success) {
            if (mounted) {
              Navigator.pop(context, true);
            }
          }
        } catch (e) {
          log("Error deleting category: $e");
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }
  Future<void> _editCategory() async {
    final result = await Navigator.push<Category>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(category: _category),
      ),
    );

    if (result != null) {
      setState(() {
        _category = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.categorydetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editCategory,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteCategory,
          ),
        ],
      ),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ShadowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: AppStrings.categoryinfo,
                    style: AppTextStyles.amountMedium,
                  ),
                  InfoRow(label: AppStrings.name, value: _category.name),
                  InfoRow(
                      label: AppStrings.percentage,
                      value: '${_category.percentage.toInt()}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}