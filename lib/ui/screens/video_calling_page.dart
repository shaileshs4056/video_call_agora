//
//
// import 'dart:async';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:auto_route/auto_route.dart';
// import 'package:flutter/material.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
//
// import 'package:flutter_demo_structure/values/colors.dart';
// import 'package:flutter_demo_structure/values/extensions/widget_ext.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// // Fill in the app ID obtained from the Agora Console
// const appId = "2ac013422f444292914c234d228b87bb";
// // Fill in the temporary token generated from Agora Console
// const token =
//     "007eJxTYFA1PLH7RVGA4PdXaut4Cl3WnFzpXvx1ifWnSY+NeK/+kJunwGCUmGxgaGxiZJRmYmJiZGlkaWiSbGRskmJkZJFkYZ6UNM1IP70hkJFhVVYmIyMDBIL4PAxlmSmp+c6JOTmZeekMDAB/cSJ3";
// // Fill in the channel name you used to generate the token
// const channel = "videoCalling";
//
// // Application class
// @RoutePage()
// class VideoCallingPage extends StatefulWidget {
//   const VideoCallingPage({Key? key}) : super(key: key);
//   @override
//   _VideoCallingPageState createState() => _VideoCallingPageState();
// }
// // Application state class
// class _VideoCallingPageState extends State<VideoCallingPage> {
//   int? _remoteUid; // The UID of the remote user
//   bool _localUserJoined =
//       false; // Indicates whether the local user has joined the channel
//   late RtcEngine _engine; // The RtcEngine instances
//
//   @override
//   void initState() {
//     super.initState();
//     initAgora();
//   }
//
//   Future<void> initAgora() async {
//     await [Permission.microphone, Permission.camera].request();
//
//     _engine = await createAgoraRtcEngine();
//
//     await _engine.initialize(
//       const RtcEngineContext(
//         appId: appId,
//         channelProfile: ChannelProfileType.channelProfileCommunication,
//       ),
//     );
//
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//           debugPrint('local user ${connection.localUid} joined');
//           setState(() {
//             _localUserJoined = true;
//           });
//         },
//         onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//           debugPrint("remote user $remoteUid joined");
//           setState(() {
//             _remoteUid = remoteUid;
//           });
//         },
//         onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
//           debugPrint("remote user $remoteUid left channel");
//           setState(() {
//             _remoteUid = null;
//           });
//         },
//       ),
//     );
//
//     await _engine.enableVideo();
//
//     // Apply mirror mode to local video
//     await _engine.setLocalVideoMirrorMode(VideoMirrorModeType.videoMirrorModeDisabled);
//
//     // Start local video preview
//     await _engine.startPreview();
//
//     // Join the channel with a token, channel name, and options
//     await _engine.joinChannel(
//       token: token,
//       channelId: channel,
//       options: const ChannelMediaOptions(
//         autoSubscribeVideo: true,
//         autoSubscribeAudio: true,
//         publishCameraTrack: true,
//         publishMicrophoneTrack: true,
//         clientRoleType: ClientRoleType.clientRoleBroadcaster,
//       ),
//       uid: 0,
//     );
//   }
//
//   void toggleScreenSize() {
//     setState(() {
//       // Toggle between half-half screen and initial size on tap
//       if (localUserHeight == 150.h) {
//         // Change to half-half screen on tap
//         localUserHeight = 0.45.sh;
//         localUserWidth = 1.sw;
//         receiverUserHeight = 0.45.sh;
//         receiverUserWidth = 1.sw;
//       } else {
//         // Reset to original size on second tap
//         localUserHeight = 150.h;
//         localUserWidth = 100.w;
//         receiverUserHeight = 1.sh;
//         receiverUserWidth = 1.sw;
//       }
//       isNotHalfScreen = !isNotHalfScreen;
//       // Debugging print statement
//     });
//   }
//
//   ///switchCamera method
//   Future<void> switchCamera() async {
//     await _engine.switchCamera();
//   }
//
//
//   @override
//   void dispose() {
//     super.dispose();
//     _dispose();
//   }
//
//   Future<void> _dispose() async {
//     // Leave the channel
//     await _engine.leaveChannel();
//     // Release resources
//     await _engine.release();
//   }
//
//   double localUserHeight = 150.h;
//   double localUserWidth = 100.w;
//   double receiverUserHeight = 1.sh;
//   double receiverUserWidth = 1.sw;
//   bool isNotHalfScreen = true;
//   // Build the UI to display local and remote videos
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         backgroundColor: AppColor.black,
//         appBar: AppBar(
//           title: const Text('Agora Video Call'),
//         ),
//         body: Column(
//           children: [
//             isNotHalfScreen? Flexible(
//               child: Stack(
//                 fit: StackFit.loose,
//                 children: [
//
//                   Positioned(
//                     bottom: 10,
//                     // top: localUserHeight == 150.h?0:0.5.sh,
//                     left: 0,
//                     child: _remoteVideo()
//                   ),
//
//                   Align(
//                     alignment: Alignment.topRight,
//                     child:
//                       _buildControlButton(
//                         onPressed: () {
//                           switchCamera();
//                         },
//                         icon: Icons.flip_camera_android,
//                         color: Colors.white,
//                       ),
//                   ).wrapPaddingOnly(right: 10.w),
//                   GestureDetector(
//                       onTap: () {
//                         toggleScreenSize();
//                       },
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(0.0), // Set the desired border radius
//                       child: Align(
//                         alignment: Alignment.topLeft,
//                         child: SizedBox(
//                           width: localUserWidth,
//                           height: localUserHeight,
//                           child: Center(
//                             child: _localUserJoined
//                                 ? AgoraVideoView(
//                               controller: VideoViewController(
//                                 rtcEngine: _engine,
//                                 canvas: const VideoCanvas(uid: 0),
//                               ),
//                             )
//                                 : const CircularProgressIndicator(),
//                           ),
//
//                           // Align(
//                           //   alignment: Alignment.bottomCenter,
//                           //   child: Row(
//                           //     mainAxisAlignment: MainAxisAlignment.center,
//                           //     children: [
//                           //       _buildControlButton(
//                           //         onPressed: () {},
//                           //         icon: Icons.mic_off,
//                           //         color: Colors.white,
//                           //       ),
//                           //       SizedBox(width: 20),
//                           //       _buildControlButton(
//                           //         onPressed: () {},
//                           //         icon: Icons.call_end,
//                           //         color: Colors.red,
//                           //       ),
//                           //       SizedBox(width: 20),
//                           //       _buildControlButton(
//                           //         onPressed: () {},
//                           //         icon: Icons.flip_camera_android,
//                           //         color: Colors.white,
//                           //       ),
//                           //     ],
//                           //   ),
//                           // ).wrapPaddingOnly(bottom: 20.h)
//                         ),
//                       ),
//                     ),).wrapPaddingAll(10.h),
//                     Align(
//                       alignment: Alignment.bottomCenter,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildControlButton(
//                             onPressed: () {},
//                             icon: Icons.mic_off,
//                             color: Colors.white,
//                           ),
//                           SizedBox(width: 20),
//                           _buildControlButton(
//                             onPressed: () {},
//                             icon: Icons.call_end,
//                             color: Colors.red,
//                           ),
//                           SizedBox(width: 20),
//                           _buildControlButton(
//                             onPressed: () {},
//                             icon: Icons.flip_camera_android,
//                             color: Colors.white,
//                           ),
//                         ],
//                       ),
//                     )
//                 ],
//               ),
//             ):
//                 Expanded(child: buildHalfScreenVideoView())
//
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget buildHalfScreenVideoView() {
//     return Column(
//       children: [
//         // Top half for Local User Video
//         Expanded(
//           child: GestureDetector(
//             onTap: () {
//               toggleScreenSize();
//             },
//             child: ClipRRect(
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(16.0),
//                 topRight: Radius.circular(16.0),
//               ),
//               child: Center(
//                 child: _localUserJoined
//                     ? AgoraVideoView(
//                   controller: VideoViewController(
//                     rtcEngine: _engine,
//                     canvas: const VideoCanvas(uid: 0),
//                   ),
//                 )
//                     : const CircularProgressIndicator(),
//               ),
//             ),
//           ),
//         ),
//
//         // Bottom half for Remote User Video
//         Expanded(
//           child: ClipRRect(
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(16.0),
//               bottomRight: Radius.circular(16.0),
//             ),
//             child: Center(
//               child: _remoteUid != null
//                   ? AgoraVideoView(
//                 controller: VideoViewController.remote(
//                   rtcEngine: _engine,
//                   canvas: VideoCanvas(uid: _remoteUid),
//                   connection: RtcConnection(channelId: channel),
//                 ),
//               )
//                   : const CircularProgressIndicator(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildControlButton(
//       {required IconData icon,
//         required Color color,
//         required VoidCallback? onPressed}) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Container(
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.black.withOpacity(0.5),
//         ),
//         child: Icon(
//           icon,
//           color: color,
//           size: 32,
//         ),
//       ),
//     );
//   }
//
//   // Widget to display remote video
//   Widget _remoteVideo() {
//     if (_remoteUid != null) {
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(30.r),
//         child: SizedBox(
//           height: receiverUserHeight,
//           width: receiverUserWidth,
//           child: AgoraVideoView(
//             controller: VideoViewController.remote(
//               rtcEngine: _engine,
//               canvas: VideoCanvas(uid: _remoteUid),
//               connection: RtcConnection(channelId: channel),
//             ),
//           ),
//         ),
//       );
//     } else {
//       return const Text(
//         'Please wait for remote user to join',
//         textAlign: TextAlign.center,
//       );
//     }
//   }
// }
