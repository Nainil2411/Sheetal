import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';

import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _percentageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final category = Category(
        name: _nameController.text.trim(),
        percentage: double.parse(_percentageController.text.replaceAll('%', '').trim()),
      );

      final categoryId = await _firebaseService.addCategory(category);

      if (categoryId != null) {
        if (mounted) {
          Navigator.pop(context, category..id = categoryId);
        }
      }
    } catch (e) {
      log("Error saving category: $e");
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
        title: const Text(AppStrings.addcatory),
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
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  String cleanValue = value.replaceAll('%', '').trim();
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
                  label: AppStrings.save,
                  borderRadius: 12,
                  onPressed:_saveCategory,
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
