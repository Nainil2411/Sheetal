import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetal/Screen/sub-screen/tab_screen.dart';
import 'package:sheetal/common/app_images.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String message = '';

  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _handleLogin() async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        message = '';
      });

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        await _firebaseService.loginUser(email, password);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', email);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            message = AppStrings.userNotFound;
          } else if (e.code == 'wrong-password') {
            message = AppStrings.wrongPassword;
          } else {
            message = AppStrings.genericError + e.message!;
          }
        });
      } catch (e) {
        setState(() {
          message = AppStrings.genericError + e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 450,
            color: CustomColors.textPrimary,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppImages.logo,
                  height: 300,
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                margin: EdgeInsets.only(top: 70),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CustomColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextFormField(
                        showTitle: true,
                        title: AppStrings.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        hintText: AppStrings.emailHint,
                        errorText: '',
                        controller: _emailController,
                        borderColor:
                            CustomColors.textSecondary.withOpacity(0.3),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.emailRequired;
                          }
                          final bool emailValid = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(value);
                          if (!emailValid) {
                            return AppStrings.invalidEmail;
                          }

                          return null;
                        },
                      ),
                      SizedBox(height: 25),
                      CustomTextFormField(
                        showTitle: true,
                        title: AppStrings.password,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        hintText: AppStrings.passwordHint,
                        errorText: '',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: CustomColors.textSecondary.withOpacity(0.8),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        obscureText: _obscurePassword,
                        controller: _passwordController,
                        borderColor:
                            CustomColors.textSecondary.withOpacity(0.3),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.passwordRequired;
                          }

                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      // Display error message if any
                      if (message.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 55,
                        width: double.infinity,
                        child: CustomElevatedButton(
                          isLoading: _isLoading,
                          label: AppStrings.login,
                          onPressed: () {
                            _handleLogin();
                          },
                          backgroundColor: CustomColors.textPrimary,
                          textColor: CustomColors.background,
                          borderRadius: 14,
                        ),
                      ),
                      // const SizedBox(height: 30),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     Text(
                      //       AppStrings.dontHaveAccount,
                      //       style: AppTextStyles.subtitleSmall,
                      //     ),
                      //     TextButton(
                      //       onPressed: () {
                      //         Navigator.push(
                      //           context,
                      //           MaterialPageRoute(
                      //             builder: (context) => Register(),
                      //           ),
                      //         );
                      //       },
                      //       child: Text(
                      //         AppStrings.signup,
                      //         style: AppTextStyles.buttonTextblack,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
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
