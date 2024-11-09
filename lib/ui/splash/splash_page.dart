import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_structure/core/db/app_db.dart';
import 'package:flutter_demo_structure/core/locator/locator.dart';
import 'package:flutter_demo_structure/router/app_router.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    initSetting();
    super.initState();
  }

  Future<void> initSetting() async {
    Future.delayed(const Duration(seconds: 2), () {
      final appDB = locator.get<AppDB>();
      if (!appDB.isLogin) {
        locator<AppRouter>().replaceAll([const LoginRoute()]);
      } else {
        locator<AppRouter>().replaceAll([const HomeRoute()]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FlutterLogo(),
    );
  }
}
