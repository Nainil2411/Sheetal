import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Dashboard/dashboard.dart';
import 'package:sheetal/Screen/Sheetal/Homepage/homepage.dart';
import 'package:sheetal/Screen/sub-screen/profile.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_color.dart';

class MainScreen extends StatefulWidget {
  final String? userEmail;

  const MainScreen({super.key, this.userEmail});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(isInTabView: true),
      const SheetalScreen(isInTabView: true),
      ProfileScreen(isInTabView: true, userEmail: widget.userEmail),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CustomColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () => _onItemTapped(0),
                child: _buildNavItem(Icons.dashboard, AppStrings.dashboard, _selectedIndex == 0, 0),
              ),
              InkWell(
                onTap: () => _onItemTapped(1),
                child: _buildNavItem(Icons.business, AppStrings.sheetal, _selectedIndex == 1, 1),
              ),
              InkWell(
                onTap: () => _onItemTapped(2),
                child: _buildNavItem(Icons.account_circle_rounded, AppStrings.Profile, _selectedIndex == 2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 30,
          color: isSelected ? CustomColors.textPrimary : CustomColors.textSecondary,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? CustomColors.textPrimary : CustomColors.textSecondary,
          ),
        ),
      ],
    );
  }
}