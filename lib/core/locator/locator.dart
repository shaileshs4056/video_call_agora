import 'dart:io';

import 'package:flutter_demo_structure/core/api/api_module.dart';
import 'package:flutter_demo_structure/core/db/app_db.dart';
import 'package:flutter_demo_structure/data/model/response/user_profile_response.dart';
import 'package:flutter_demo_structure/data/repository_impl/auth_repo_impl.dart';
import 'package:flutter_demo_structure/router/app_router.dart';
import 'package:flutter_demo_structure/service/enc_service.dart';
import 'package:flutter_demo_structure/ui/auth/store/auth_store.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  /// setup hive
  final appDocumentDir = Platform.isAndroid
      ? await getApplicationDocumentsDirectory()
      : await getLibraryDirectory();

  Hive
    ..init(appDocumentDir.path)
    ..registerAdapter(UserDataAdapter());
  locator.registerSingletonAsync<AppDB>(() => AppDB.getInstance());

  /// setup navigator instance
  locator.registerSingleton(AppRouter());

  /// setup API modules with repos which requires [Dio] instance
  await ApiModule().provides();

  /// setup encryption service
  locator.registerLazySingleton(
    () => EncService(aesKey: "WQXy4CzZyUyJNOr5z5mvcR13dwxBGKnr"),
  );

  /// register repositories implementation
  locator.registerFactory<AuthRepoImpl>(
    () => AuthRepoImpl(authApi: locator()),
  );

  // register stores if only you requires singleton
  locator.registerLazySingleton<AuthStore>(() => AuthStore());
}
