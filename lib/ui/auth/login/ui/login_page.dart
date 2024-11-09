import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:dart_ipify/dart_ipify.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_structure/core/db/app_db.dart';
import 'package:flutter_demo_structure/core/locator/locator.dart';
import 'package:flutter_demo_structure/data/model/request/login_request_model.dart';
import 'package:flutter_demo_structure/generated/assets.dart';
import 'package:flutter_demo_structure/generated/l10n.dart';
import 'package:flutter_demo_structure/router/app_router.dart';
import 'package:flutter_demo_structure/ui/auth/login/widget/sign_up_widget.dart';
import 'package:flutter_demo_structure/ui/auth/store/auth_store.dart';
import 'package:flutter_demo_structure/values/export.dart';
import 'package:flutter_demo_structure/widget/app_text_filed.dart';
import 'package:flutter_demo_structure/widget/button_widget_inverse.dart';
import 'package:flutter_demo_structure/widget/loading_widget.dart';
import 'package:flutter_demo_structure/widget/show_message.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobx/mobx.dart';

import '../../../../core/api/base_response/base_response.dart';
import '../../../../data/model/response/user_profile_response.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late FocusNode emailNode;
  late FocusNode passwordNode;
  late ValueNotifier<bool> showLoading;

  List<ReactionDisposer>? _disposers;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    emailNode = FocusNode();
    passwordNode = FocusNode();
    showLoading = ValueNotifier<bool>(false);

    addDisposer();
  }

  @override
  void dispose() {
    removeDisposer();
    emailController.dispose();
    passwordController.dispose();
    emailNode.dispose();
    passwordNode.dispose();
    showLoading.dispose();
    super.dispose();
  }

  void addDisposer() {
    _disposers ??= [
      // success reaction
      reaction((_) => authStore.loginResponse,
          (BaseResponse<UserData?>? response) {
        showLoading.value = false;
        if (response?.code == "1") {
          showMessage(response?.message ?? "");
          appRouter.replaceAll([const HomeRoute()]);
          appDB.isLogin = true;
        }
      }),
      // error reaction
      reaction((_) => authStore.errorMessage, (String? errorMessage) {
        showLoading.value = false;
        if (errorMessage != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }),
    ];
  }

  void removeDisposer() {
    if (_disposers == null) return;
    for (final element in _disposers!) {
      element.reaction.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ValueListenableBuilder(
        valueListenable: showLoading,
        builder: (_, bool isLoading, Widget? child) {
          return LoadingWidget(
            status: isLoading,
            child: child!,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                30.0.verticalSpace,
                getHeaderContent(),
                getSignInForm(),
                30.0.verticalSpace,
                SignUpWidget(
                  fromLogin: true,
                  onTap: () => locator<AppRouter>()
                      .push(const SignUpRoute())
                      .then((value) => _formKey.currentState?.reset()),
                ),
                40.0.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getHeaderContent() {
    return Column(
      children: [
        FlutterLogo(
          size: 0.15.sh,
        ),
        10.0.verticalSpace,
        Text(
          S.current.welcomeBack.toUpperCase(),
          style: textBold.copyWith(
            color: AppColor.primaryColor,
            fontSize: 28.spMin,
          ),
        ),
      ],
    );
  }

  Widget getSignInForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          25.0.verticalSpace,
          AppTextField(
            controller: emailController,
            label: S.current.email,
            hint: S.current.email,
            keyboardType: TextInputType.emailAddress,
            validators: emailValidator,
            focusNode: emailNode,
            prefixIcon: IconButton(
              onPressed: null,
              icon: Image.asset(
                Assets.imageBag,
                color: AppColor.primaryColor,
                height: 26.0,
                width: 26.0,
              ),
            ),
          ),
          10.0.verticalSpace,
          AppTextField(
            label: S.current.password,
            hint: S.current.password,
            obscureText: true,
            validators: passwordValidator,
            controller: passwordController,
            focusNode: passwordNode,
            keyboardType: TextInputType.visiblePassword,
            keyboardAction: TextInputAction.done,
            maxLength: 15,
            suffixIcon: Align(
              alignment: Alignment.centerRight,
              heightFactor: 1.0,
              widthFactor: 1.0,
              child: GestureDetector(
                onTap: () => Future.delayed(Duration.zero, () {
                  passwordNode.unfocus();
                }),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    S.current.forgot,
                    style: textMedium.copyWith(
                      color: AppColor.brownColor,
                      fontSize: 14.0.spMin,
                    ),
                  ),
                ),
              ),
            ),
            prefixIcon: IconButton(
              onPressed: null,
              icon: Image.asset(
                Assets.imageBag,
                color: AppColor.primaryColor,
                height: 26.0,
                width: 26.0,
              ),
            ),
          ),
          16.0.verticalSpace,
          AppButtonInverse(
            S.current.logIn.toUpperCase(),
            () {
              if (_formKey.currentState?.validate() ?? false) {
                loginAndNavigateToHome();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> loginAndNavigateToHome() async {
    FocusScope.of(context).requestFocus(FocusNode());
    try {
      showLoading.value = true;
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      //This is just a sample request body, you need to use and edit it as per your API requirement.
      var ipAddress = await Ipify.ipv4();
      final logInRequest = LoginRequestModel(
          loginType: "S",
          deviceToken: appDB.fcmToken,
          countryCode: "+91",
          phone: "65765765767",
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          ip: ipAddress);
      if (Platform.isAndroid) {
        var androidInfo = await deviceInfo.androidInfo;
        logInRequest.uuid = androidInfo.id;
        logInRequest.deviceModel = androidInfo.device;
        logInRequest.deviceType = "A";
      } else if (Platform.isIOS) {
        var iOSInfo = await deviceInfo.iosInfo;
        logInRequest.uuid = iOSInfo.identifierForVendor;
        logInRequest.deviceModel = iOSInfo.name;
        logInRequest.osVersion = iOSInfo.systemVersion;
        logInRequest.deviceType = "I";
      }
      authStore.login(logInRequest);
    } catch (e, st) {
      showLoading.value = false;
      showMessage(S.of(context).pleaseCheckYourInternetConnection);
      debugPrintStack(stackTrace: st);
    }
  }
}
