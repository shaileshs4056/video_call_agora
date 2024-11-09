import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_structure/core/db/app_db.dart';
import 'package:flutter_demo_structure/generated/l10n.dart';
import 'package:flutter_demo_structure/util/media_picker.dart';
import 'package:flutter_demo_structure/util/permission_utils.dart';
import 'package:flutter_demo_structure/values/export.dart';
import 'package:flutter_demo_structure/widget/media_picker_bottomsheet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../router/app_router.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late ValueNotifier showLoading;
  ButtonStyle style =
      TextButton.styleFrom(minimumSize: const Size(double.maxFinite, 20));
  int? count;
  List<XFile?>? pickedFilesListStore = [];
  List<PlatformFile>? pickedDocuments;
  FilesType? type;

  @override
  void initState() {
    super.initState();
    showLoading = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    showLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.current.home,
          style: textBold.copyWith(fontSize: 30.spMin),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            25.0.verticalSpace,
            25.0.verticalSpace,
            Column(
              children: [
                if (count != null)
                  Text(
                    "${S.current.pickedFileCount} $count",
                    style: textBold,
                  ),
                10.0.verticalSpace,
                if (pickedFilesListStore != null)
                  Wrap(
                    children: pickedFilesListStore!
                        .map(
                          (e) => e != null
                              ? Image.file(
                                  File(e.path),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                )
                              : const SizedBox.shrink(),
                        )
                        .toList(),
                  ),
                if (pickedDocuments != null && type == FilesType.audio ||
                    type == FilesType.documents)
                  Wrap(
                    children: pickedDocuments!
                        .map(
                          (e) => Image.file(
                            File(e.path!),
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                        .toList(),
                  )
              ],
            ),
            25.0.verticalSpace,
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            requestCameraPermissions().then((value) async {
                          if (value) {
                            pickFile(FilesType.image);
                          }
                        }),
                        style: style,
                        child: Text(S.current.pickImage),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            requestCameraPermissions().then((value) async {
                          if (value) {
                            pickFile(FilesType.video);
                          }
                        }),
                        style: style,
                        child: Text(S.current.pickVideo),
                      ),
                    ),
                  ],
                ),
                10.0.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            requestCameraPermissions().then((value) async {
                          if (value) {
                            pickFile(FilesType.documents);
                          }
                        }),
                        style: style,
                        child: Text(S.current.pickDocuments),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            requestCameraPermissions().then((value) async {
                          if (value) {
                            pickFile(FilesType.audio);
                          }
                        }),
                        style: style,
                        child: Text(S.current.pickAudio),
                      ),
                    ),
                  ],
                ),
                20.0.verticalSpace,
              ],
            ),
            25.0.verticalSpace,
            buildTakePhotoPermission(context),
            25.0.verticalSpace,
            TextButton(
              onPressed: () {
                appDB.logout();
                appRouter.replaceAll([const LoginRoute()]);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColor.accentColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                 "heyy",
                  style: textBold.copyWith(color: AppColor.primaryColor),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<bool> requestCameraPermissions() async {
    Map<Permission, PermissionStatus> permissions = {};
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      permissions = await [
        Permission.camera,
        Permission.videos,
        if (androidInfo.version.sdkInt > 32)
          Permission.photos
        else
          Permission.storage,
      ].request();
    } else {
      permissions = await [
        Permission.camera,
        Permission.storage,
        Permission.videos,
      ].request();
    }

    final PermissionStatus? cameraStatus = permissions[Permission.camera];
    final PermissionStatus? storageStatus = permissions[Permission.storage];
    final PermissionStatus? videoStatus = permissions[Permission.videos];

    debugPrint(
      "permission status : camera $cameraStatus storage $storageStatus video $videoStatus ",
    );

    if ((cameraStatus?.isGranted == true || cameraStatus?.isLimited == true) &&
        (videoStatus?.isGranted == true ||
            videoStatus?.isLimited == true ||
            storageStatus?.isGranted == true ||
            storageStatus?.isLimited == true)) {
      debugPrint('Camera Permission: GRANTED');
      return true;
    }
    return false;
  }

  Widget buildTakePhotoPermission(BuildContext context) {
    return Column(
      children: [
        TextButton(
          child: Text(
            S.current.photoPermission,
          ),
          onPressed: () async {
            await PhotosPermission().request(
              onPermanentlyDenied: () =>
                  ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    S.current.permissionDeniedAlwaysUserNeedToAllowManually,
                  ),
                ),
              ),
              onGranted: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.current.userAllowedToAccessPhotos),
                ),
              ),
              onPermissionDenied: () =>
                  ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.current.userDeniedToAccessPhotos),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Future<void> pickFile(FilesType type) async {
    setState(() {
      pickedFilesListStore = null;
      pickedDocuments = null;
      this.type = null;
    });
    switch (type) {
      case FilesType.image:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => MediaPickerSheet(
            pickFileType: PickedFileType.image,
            onSelectFile: (file, pickedFileType) {
              if (file != null) {
                if (mounted) {
                  setState(() {
                    count = count != null ? count! + 1 : 1;
                    pickedFilesListStore?.add(file);
                  });
                }
              }
            },
          ),
        );
        break;
      case FilesType.video:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => MediaPickerSheet(
            pickFileType: PickedFileType.video,
            onSelectFile: (file, pickedFileType) {
              debugPrint('Selected media type $pickedFileType');
              debugPrint('Selected file path ${file?.path}');
              if (file != null) {
                if (mounted) {
                  setState(() {
                    count = count != null ? count! + 1 : 1;
                    pickedFilesListStore?.add(file);
                  });
                }
              }
            },
          ),
        );
        break;
      case FilesType.documents:
        pickedDocuments =
            await DocumentPicker.pickDocument(fileType: FileType.any);
        break;
      case FilesType.audio:
        pickedDocuments = await DocumentPicker.pickDocument(
          fileType: FileType.audio,
          allowMultiple: true,
        );
        break;
    }
    if (pickedFilesListStore != null) {
      if (mounted) setState(() => count = pickedFilesListStore!.length);
    }
    if (pickedDocuments != null) {
      if (mounted) setState(() => count = pickedDocuments!.length);
    }
  }
}

/// this enum only for identify pick type in real case we can directly call media picker
enum FilesType { image, video, documents, audio }
