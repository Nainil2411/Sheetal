import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/sub-screen/splash.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/firebase_options.dart';
import 'package:sheetal/utils/utility.dart';
import 'common/app_string.dart';
import 'common/custom_color.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ConnectivityService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<bool> isOffline = ConnectivityService().isOffline;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    isOffline.addListener(_handleOfflineState);
  }

  void _handleOfflineState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isCurrentlyOffline = isOffline.value;

      if (isCurrentlyOffline) {
        _showNoInternetDialog();
      } else {
        _dismissDialogIfAny();
      }
    });
  }

  @override
  void dispose() {
    isOffline.removeListener(_handleOfflineState);
    super.dispose();
  }

  void _showNoInternetDialog() {
    if (!_dialogShown && navigatorKey.currentContext != null) {
      _dialogShown = true;
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: Icon(
              Icons.signal_wifi_off,
              color: CustomColors.error,
              size: 50.0,
            ),
            title: Text(AppStrings.nointernet, style: AppTextStyles.labelLarge),
            content: Text(AppStrings.checkinternet,
                style: AppTextStyles.buttonTextblack),
          );
        },
      );
    }
  }

  void _dismissDialogIfAny() {
    if (_dialogShown && navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!, rootNavigator: true)
          .maybePop();
      _dialogShown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: CustomColors.background,
      ),
      title: AppStrings.appName,
      home: const SplashScreen(),
      builder: (context, child) {
        return GestureDetector(
          child: child,
          onTap: () => Utility.keyboardDismiss(context),
        );
      },
    );
  }
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOffline = ValueNotifier(false);

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    _checkInitialConnection();
  }

  void dispose() {
    _subscription.cancel();
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection =
        results.any((result) => result != ConnectivityResult.none);
    log('Connectivity changed: $results');
    isOffline.value = !hasConnection;
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }
}
