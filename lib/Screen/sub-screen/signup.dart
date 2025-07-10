import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetal/Screen/sub-screen/tab_screen.dart';
import 'package:sheetal/common/app_images.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _phonenoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _passwordError = '';
  String _firstNameError = '';
  String _lastNameError = '';
  String? _phoneError;
  String _emailError = '';

  final FirebaseService _firebaseService = FirebaseService();

  bool _validatePassword(String password) {
    String errorMessage = '';

    if (password.length < 6) {
      errorMessage += AppStrings.passwordlonger;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errorMessage += AppStrings.passworduppercase;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errorMessage += AppStrings.passwordlowercase;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errorMessage += AppStrings.passworddigit;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errorMessage += AppStrings.passwordspecial;
    }

    _passwordError = errorMessage;
    return errorMessage.isEmpty;
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic> userData = {
          'firstName': _firstnameController.text.trim(),
          'lastName': _lastnameController.text.trim(),
          'phoneNumber': _phonenoController.text.trim(),
          'email': _emailController.text.trim(),
        };

        await _firebaseService.registerUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          userData,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      } catch (e) {
        log('Error : $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: CustomColors.textPrimary,
            height: 450,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppImages.logo,
                  height: 250,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 250),
            child: Center(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CustomColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTextFormField(
                            showTitle: true,
                            title: AppStrings.email,
                            hintText: AppStrings.email,
                            errorText: _emailError,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                setState(() {
                                  _emailError = AppStrings.emailRequired;
                                });
                                return AppStrings.emailRequired;
                              }
                              final bool emailValid = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                  .hasMatch(value);
                              if (!emailValid) {
                                setState(() {
                                  _emailError = AppStrings.invalidEmail;
                                });
                                return AppStrings.invalidEmail;
                              }
                              setState(() {
                                _emailError = '';
                              });
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextFormField(
                                  showTitle: true,
                                  title: AppStrings.firstNameHint,
                                  hintText: AppStrings.firstNameHint,
                                  errorText: _firstNameError,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  controller: _firstnameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      setState(() {
                                        _firstNameError =
                                            AppStrings.nameRequired;
                                      });
                                      return AppStrings.nameRequired;
                                    }
                                    setState(() {
                                      _firstNameError = '';
                                    });
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: CustomTextFormField(
                                  showTitle: true,
                                  title: AppStrings.lastNameHint,
                                  hintText: AppStrings.lastNameHint,
                                  errorText: _lastNameError,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  controller: _lastnameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      setState(() {
                                        _lastNameError =
                                            AppStrings.nameRequired;
                                      });
                                      return AppStrings.nameRequired;
                                    }
                                    setState(() {
                                      _lastNameError = '';
                                    });
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          CustomTextFormField(
                              showTitle: true,
                              title: AppStrings.phoneHint,
                              controller: _phonenoController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              hintText: AppStrings.phoneHint,
                              showBorders: true,
                              borderColor: _phoneError != null
                                  ? CustomColors.error
                                  : CustomColors.textSecondary.withOpacity(0.5),
                              errorText: _phoneError,
                              onChanged: (value) {
                                setState(() {
                                  _phoneError = null;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  setState(() {
                                    _phoneError = AppStrings.phoneRequired;
                                  });
                                  return AppStrings.phoneRequired;
                                }
                                return null;
                              }),
                          SizedBox(height: 15),
                          CustomTextFormField(
                            showTitle: true,
                            title: AppStrings.password,
                            keyboardType: TextInputType.visiblePassword,
                            hintText: AppStrings.password,
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: CustomColors.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            obscureText: _obscurePassword,
                            controller: _passwordController,
                            onChanged: (value) {
                              setState(() {
                                _validatePassword(value);
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                setState(() {
                                  _passwordError = AppStrings.passwordRequired;
                                });
                                return AppStrings.passwordRequired;
                              }
                              if (!_validatePassword(value)) {
                                return AppStrings.passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 55,
                            width: double.infinity,
                            child: CustomElevatedButton(
                              label: AppStrings.signup,
                              isLoading: _isLoading,
                              onPressed: () {
                                _handleRegister();
                              },
                              backgroundColor: CustomColors.textPrimary,
                              textColor: CustomColors.background,
                              borderRadius: 12,
                            ),
                          ),
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppStrings.alreadyHaveAccount,
                                  style: AppTextStyles.subtitleSmall),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  AppStrings.login,
                                  style: AppTextStyles.buttonTextblack,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            ModalBarrier(
              dismissible: false,
            ),
        ],
      ),
    );
  }
}
