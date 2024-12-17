import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_demo_structure/core/locator/locator.dart';
import 'package:flutter_demo_structure/ui/auth/login/ui/login_page.dart';
import 'package:flutter_demo_structure/ui/auth/sign_up/sign_up_page.dart';
import 'package:flutter_demo_structure/ui/home/home_page.dart';
import 'package:flutter_demo_structure/ui/screens/one_to_one_calling_page.dart';
import 'package:flutter_demo_structure/ui/splash/splash_page.dart';
import '../ui/screens/calling_page.dart';
import '../ui/screens/index_page.dart';
import '../ui/screens/starting_page.dart';
part 'app_router.gr.dart';

@AutoRouterConfig(
  replaceInRouteName: 'Page,Route',
)
// extend the generated private router
class AppRouter extends _$AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  final List<AutoRoute> routes = [
    AutoRoute(page: IndexRoute.page,initial: true),
    AutoRoute(page: CallRoute.page),
    AutoRoute(page: VideoCallingRoute.page)
    // AutoRoute(page: VideoCal.page)
  ];
}

final appRouter = locator<AppRouter>();
