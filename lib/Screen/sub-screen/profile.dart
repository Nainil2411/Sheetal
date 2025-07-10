import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetal/Screen/sub-screen/login.dart';
import 'package:sheetal/common/app_images.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class ProfileScreen extends StatefulWidget {
  final bool isInTabView;
  final String? userEmail;

  const ProfileScreen({super.key, this.isInTabView = false, this.userEmail});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  String userEmail = "Loading...";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  void _showLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void _hideLoading() {
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getUserEmail() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        userEmail = currentUser.email ?? "No email found";
      });
    }
  }

  Future<void> _logout() async {
    _showLoading();

    try {
      await _firebaseService.logoutUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      if (mounted) {
        _hideLoading();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    } catch (e) {
      print(AppStrings.genericError + e.toString());
      if (mounted) {
        _hideLoading();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: CustomColors.textPrimary,
              title: Text(
                AppStrings.myProfile,
                style: AppTextStyles.headline1white,
              ),
            ),
            body: Container(
              color: CustomColors.textPrimary,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CustomColors.background,
                      ),
                      child: Image.asset(AppImages.logo, fit: BoxFit.fill),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: CustomColors.background,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                  Icons.email, AppStrings.email, userEmail),
                              const SizedBox(height: 170),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: CustomElevatedButton(
                                  label: AppStrings.logout,
                                  backgroundColor: CustomColors.error,
                                  borderRadius: 12,
                                  onPressed: () async {
                                    final bool confirmLogout = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                const Text(AppStrings.logout),
                                            content: const Text(
                                                AppStrings.areyousure),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text(
                                                    AppStrings.cancel,
                                                    style: AppTextStyles
                                                        .buttonTextblack),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        CustomColors
                                                            .textPrimary),
                                                child: const Text(
                                                    AppStrings.logout,
                                                    style: AppTextStyles
                                                        .errorText),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;
                                    if (confirmLogout) {
                                      _logout();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading) Utility.circleloading()
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CustomColors.textPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: CustomColors.background),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.cardSubtitle),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
