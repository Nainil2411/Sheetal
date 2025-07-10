import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';

class EditCategoryScreen extends StatefulWidget {
  final Category category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _percentageController;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _percentageController = TextEditingController(text: widget.category.percentage.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCategory = Category(
        id: widget.category.id,
        name: _nameController.text.trim(),
        percentage: double.parse(_percentageController.text.replaceAll('%', '').trim()),
      );
      final success = await _firebaseService.updateCategory(updatedCategory);
      if (success) {
        if (mounted) {
          Navigator.pop(context, updatedCategory);
        }
      }
    } catch (e) {
      log('Error updating category: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.editcategory),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextFormField(
                controller: _nameController,
                showTitle: true,
                title: AppStrings.categoryname,
                hintText: AppStrings.categorynameRequired,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.categorynameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _percentageController,
                hintText: AppStrings.percentage,
                title: AppStrings.percentage,
                showTitle: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  String cleanValue =
                  value.replaceAll('%', '').trim();
                  if (cleanValue.isNotEmpty) {
                    setState(() {
                      _percentageController.text = '$cleanValue%';
                      _percentageController.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: _percentageController.text.length - 1));
                    });
                  } else {
                    setState(() {
                      _percentageController.text = '';
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.percentageRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 55,
                width: double.infinity,
                child: CustomElevatedButton(
                  label: AppStrings.update,
                  borderRadius: 12,
                  onPressed:_updateCategory,
                  isLoading: _isLoading,
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
