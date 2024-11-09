// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// // Define your Agora credentials here
// const String appId = "2ac013422f444292914c234d228b87bb"; // Your App ID from Agora Console
// const String token = "your-temporary-token"; // Your token from Agora Console
// const String channel = "videoCalling"; // Your channel name
//
// class MultiUserPage extends StatefulWidget {
//   const MultiUserPage({super.key});
//
//   @override
//   State<MultiUserPage> createState() => _MultiUserPageState();
// }
//
// class _MultiUserPageState extends State<MultiUserPage> {
//   late RtcEngine _engine; // Agora engine instance
//   bool _localUserJoined = false; // Track if local user has joined the channel
//   List<int> _remoteUsers = []; // Track remote user UIDs
//   @override
//   void initState() {
//     super.initState();
//     initAgora();
//   }
//
//   // Initialize Agora SDK and setup event handlers
//   Future<void> initAgora() async {
//     await [Permission.microphone, Permission.camera].request(); // Request permissions
//
//     _engine = await createAgoraRtcEngine(); // Create Agora RTC engine
//
//     // Initialize Agora engine with appId and channel profile
//     await _engine.initialize(
//       const RtcEngineContext(
//         appId: appId,
//         channelProfile: ChannelProfileType.channelProfileCommunication,
//       ),
//     );
//
//     // Register event handlers for various Agora events
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//           setState(() {
//             _localUserJoined = true; // Local user successfully joined
//           });
//         },
//         onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//           setState(() {
//             _remoteUsers.add(remoteUid); // Add remote user to list
//           });
//         },
//         onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
//           setState(() {
//             _remoteUsers.remove(remoteUid); // Remove remote user from list
//           });
//         },
//       ),
//     );
//
//     await _engine.enableVideo(); // Enable video for both local and remote users
//     await _engine.setLocalVideoMirrorMode(VideoMirrorModeType.videoMirrorModeDisabled); // Disable local video mirror mode
//     await _engine.startPreview(); // Start local video preview
//
//     // Join the channel with token, channel name, and options
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
//       uid: 0, // Random UID for local user
//     );
//   }
//
//   // Dispose method to leave channel and release resources
//   @override
//   void dispose() {
//     super.dispose();
//     _dispose();
//   }
//
//   Future<void> _dispose() async {
//     await _engine.leaveChannel(); // Leave the channel
//     await _engine.release(); // Release the resources
//   }
//
//   // Method to switch between front and rear camera
//   Future<void> switchCamera() async {
//     await _engine.switchCamera();
//   }
//
//   // Method to render local user's video preview
//   Widget _renderLocalPreview() {
//     if (_localUserJoined) {
//       return RtcLocalView.SurfaceView(); // Local video
//     } else {
//       return const Text(
//         'Joining Channel, Please wait.....',
//         textAlign: TextAlign.center,
//       ); // Waiting message
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Agora Multi-User Video Call"),
//       ),
//       body: Column(
//         children: [
//           // Render the local user's video preview
//           Container(
//             height: 200,
//             width: 150,
//             child: _renderLocalPreview(), // Local video preview widget
//           ),
//           // Render remote users' video streams
//           Expanded(
//             child: ListView.builder(
//               itemCount: _remoteUsers.length, // Number of remote users
//               itemBuilder: (context, index) {
//                 int remoteUid = _remoteUsers[index]; // Get remote UID
//                 return Container(
//                   height: 200,
//                   width: double.infinity,
//                   child: RtcRemoteView.SurfaceView(uid: remoteUid), // Remote video
//                 );
//               },
//             ),
//           ),
//           // Button to switch between front and rear camera
//           ElevatedButton(
//             onPressed: switchCamera, // Switch camera method
//             child: const Text("Switch Camera"),
//           ),
//         ],
//       ),
//     );
//   }
// }
