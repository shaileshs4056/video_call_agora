//
//
// import 'dart:async';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:floating/floating.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_mobx/flutter_mobx.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import '../auth/store/auth_store.dart';
//
// // Agora details
// const appId = "2ac013422f444292914c234d228b87bb";
// const token = "007eJxTYNDmvbaiK4YnKDv9Uns90/fFb+9c+Pz7Z8/8T4nckauDWiYoMBglJhsYGpsYGaWZmJgYWRpZGpokGxmbpBgZWSRZmCclzXrhn94QyMjg7PyCmZEBAkF8HoayzJTUfOfEnJzMvHQGBgDdTyQS";
// const channel = "videoCalling";
//
// class VideoCallingPage extends StatefulWidget {
//   const VideoCallingPage({Key? key}) : super(key: key);
//
//   @override
//   _VideoCallingPageState createState() => _VideoCallingPageState();
// }
//
// class _VideoCallingPageState extends State<VideoCallingPage> with WidgetsBindingObserver {
//   late RtcEngine _engine; // Agora engine instance
//   bool _localUserJoined = false; // Indicates local user joined
//   int? _remoteUid; // Remote user's UID
//   bool isVideoDisabled = false;
//   bool muted = false;
//   bool onSpeaker = false;
//   int currentPageIndex = 0;
//   bool onVideoOff=false;
//   int muteVideoRemoteId = 0;
//   bool _remoteVideoMuted = false; // Tracks remote user's video status
//   // bool _localVideoMuted = false;
//   bool isLocalVideoDisabled = false;
//   Map<int, bool> remoteVideoStates = {};// Tracks local user's video status
//   bool _isSplitScreen = false;
//   final Floating floating = Floating();
//   bool isPipEnabled = false; // Tracks if PiP is active
//   StreamSubscription<ConnectivityResult>? _subscription;
//   @override
//   void initState() {
//     super.initState();
//     _initAgora();
//     WidgetsBinding.instance.addObserver(this);
//     startMonitoring();
//     authStore.startMonitoring();
//   }
//
//   ///start monitoring internet connection
//
//   void startMonitoring() {
//     _subscription = Connectivity().onConnectivityChanged.listen((result) {
//       if (result == ConnectivityResult.none) {
//         // No internet connection
//         Fluttertoast.showToast(
//           msg: "Network disconnected! Check your internet connection.",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//       } else {
//         // Internet connection restored
//         Fluttertoast.showToast(
//           msg: "Network reconnected!",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//         );
//       }
//     });
//   }
//
//   ///stop monitoring
//   /// Method to stop monitoring connectivity.
//   void stopConnectivityMonitoring() {
//   }
//
//   void togglePipMode() {
//     setState(() {
//       isPipEnabled = !isPipEnabled;
//     });
//   }
//
//   Future<void> _initAgora() async {
//     // Request microphone and camera permissions
//     await [Permission.microphone, Permission.camera].request();
//
//     // Initialize Agora engine
//     _engine = await createAgoraRtcEngine();
//     await _engine.initialize(
//       const RtcEngineContext(
//         appId: appId,
//         channelProfile: ChannelProfileType.channelProfileCommunication,
//       ),
//     );
//
//     // Register event handlers
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//           debugPrint("Local user joined: ${connection.localUid}");
//           setState(() {
//             _localUserJoined = true;
//           });
//         },
//         onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//           debugPrint("Remote user joined: $remoteUid");
//           setState(() {
//             _remoteUid = remoteUid;
//           });
//         },
//         onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
//           debugPrint("Remote user left: $remoteUid");
//           setState(() {
//             _remoteUid = null;
//           });
//         },
//         onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
//           debugPrint("Remote user $remoteUid has ${muted ? 'disabled' : 'enabled'} their video.");
//           setState(() {
//             remoteVideoStates[remoteUid] = muted; // Update the remote user's video state
//           });
//         },
//       ),
//     );
//
//     // Enable video and join channel
//     await _engine.enableVideo();
//     await _engine.startPreview();
//     await _engine.joinChannel(
//       token: token,
//       channelId: channel,
//       uid: 0,
//       options: const ChannelMediaOptions(
//         autoSubscribeAudio: true,
//         autoSubscribeVideo: true,
//         publishCameraTrack: true,
//         publishMicrophoneTrack: true,
//         clientRoleType: ClientRoleType.clientRoleBroadcaster,
//       ),
//     );
//   }
//
//   /// Info panel to show logs
//
//   void _onCallEnd(BuildContext context) async {
//     await _engine.leaveChannel();
//     await _engine.release();
//   }
//
//   void _onToggleMute() {
//     setState(() {
//       muted = !muted;
//     });
//     _engine.muteLocalAudioStream(muted);
//     if (muted == true) {
//       // toastMessageTxt("Audio is muted of user id is ${_users[0]}");
//     }
//   }
//
//   void _onSpeakerButton() {
//     setState(() {
//       if (onSpeaker == true) {
//         _engine.disableAudio();
//       } else {
//         _engine.enableAudio();
//       }
//     });
//   }
//
//   void _onSwitchCamera() {
//     _engine.switchCamera();
//   }
//
//
//   Future<void> _onDisableVideoButton() async {
//     setState(() {
//       isVideoDisabled = !isVideoDisabled; // Toggle local video state
//     });
//
//     // Notify the Agora SDK about local video mute/unmute
//     await _engine.muteLocalVideoStream(isVideoDisabled);
//
//     if (isVideoDisabled) {
//       print("Local user has disabled their video.");
//     } else {
//       print("Local user has enabled their video.");
//     }
//   }
//
//   Widget _toolbar() {
//     // if (widget.role == ClientRoleType.clientRoleAudience) return Container();
//     return Container(
//       alignment: Alignment.bottomCenter,
//       padding: const EdgeInsets.symmetric(vertical: 48),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           Flexible(
//             child: RawMaterialButton(
//               onPressed: _onSwitchCamera,
//               child: Icon(
//                 Icons.switch_camera,
//                 color: Colors.blueAccent,
//                 size: 18.0,
//               ),
//               shape: CircleBorder(),
//               elevation: 2.0,
//               fillColor: Colors.white,
//               padding: const EdgeInsets.all(12.0),
//             ),
//           ),
//           Flexible(
//             child: RawMaterialButton(
//               onPressed: () {
//                 _onToggleMute();
//               },
//               child: Icon(
//                 muted ? Icons.mic_off : Icons.mic,
//                 color: muted ? Colors.white : Colors.blueAccent,
//                 size: 18.0,
//               ),
//               shape: CircleBorder(),
//               elevation: 2.0,
//               fillColor: muted ? Colors.blueAccent : Colors.white,
//               padding: const EdgeInsets.all(12.0),
//             ),
//           ),
//           Flexible(
//             child: RawMaterialButton(
//               onPressed: () {
//                 _onCallEnd(context);
//                 Navigator.pop(context);
//               },
//               child: Icon(
//                 Icons.call_end,
//                 color: Colors.white,
//                 size: 30.0,
//               ),
//               shape: CircleBorder(),
//               elevation: 2.0,
//               fillColor: Colors.redAccent,
//               padding: const EdgeInsets.all(15.0),
//             ),
//           ),
//           Flexible(
//             child: RawMaterialButton(
//               onPressed: _toggleLocalVideo,
//               child: Icon(
//                 isLocalVideoDisabled ? Icons.videocam_off : Icons.videocam,
//                 color: isLocalVideoDisabled ? Colors.red : Colors.blueAccent,
//               ),
//               shape: CircleBorder(),
//               elevation: 2.0,
//               fillColor: Colors.white,
//               padding: const EdgeInsets.all(12.0),
//             ),
//           ),
//           Flexible(
//             child: RawMaterialButton(
//               onPressed: () {
//                 setState(() {
//                   onSpeaker = !onSpeaker;
//                 });
//                 _onSpeakerButton();
//               },
//               child: Icon(
//                 onSpeaker ? Icons.volume_off : Icons.volume_up,
//                 color: Colors.blueAccent,
//                 size: 18.0,
//               ),
//               shape: CircleBorder(),
//               elevation: 2.0,
//               fillColor: Colors.white,
//               padding: const EdgeInsets.all(12.0),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _disposeAgora();
//   }
//
//   Future<void> _disposeAgora() async {
//     await _engine.leaveChannel();
//     await _engine.release();
//   }
//
//   // Function to toggle local video
//   Future<void> _toggleLocalVideo() async {
//     setState(() {
//       isLocalVideoDisabled = !isLocalVideoDisabled; // Toggle local video state
//     });
//
//     // Notify the Agora SDK about the local video state
//     await _engine.muteLocalVideoStream(isLocalVideoDisabled);
//
//     if (isLocalVideoDisabled) {
//       print("Local user has disabled their video.");
//     } else {
//       print("Local user has enabled their video.");
//     }
//   }
//
//   Widget _localVideoView() {
//     if (_localUserJoined) {
//       return isLocalVideoDisabled
//           ? _placeholderView()
//           : AgoraVideoView(
//         controller: VideoViewController(
//           rtcEngine: _engine,
//           canvas: const VideoCanvas(uid: 0),
//         ),
//       );
//     } else {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//   }
//
//   Widget _placeholderView() {
//     return Container(
//       color: Colors.black,
//       child: Center(
//           child: Icon(Icons.person,color: Colors.white,size: 30,)
//       ),
//     );
//   }
//
//
//   // Remote Video View
//   Widget _remoteVideoView(int remoteUid) {
//     if (remoteVideoStates.containsKey(remoteUid)) {
//       bool isRemoteVideoDisabled = remoteVideoStates[remoteUid] ?? false;
//
//       return isRemoteVideoDisabled
//           ? Container(
//         color: Colors.black,
//         child: const Center(
//           child: Icon(Icons.person, color: Colors.white, size: 50),
//         ),
//       )
//           : AgoraVideoView(
//         controller: VideoViewController.remote(
//           rtcEngine: _engine,
//           canvas: VideoCanvas(uid: remoteUid),
//           connection: RtcConnection(channelId: channel),
//         ),
//       );
//     } else {
//       return const Center(
//         child: Text(
//           "Waiting for remote user to join...",
//           style: TextStyle(color: Colors.white),
//           textAlign: TextAlign.center,
//         ),
//       );
//     }
//   }
//
//
//   Future<void> enablePip() async {
//     try {
//       final status = await floating.enable(const ImmediatePiP());
//       debugPrint("PiP status: $status");
//     } catch (e) {
//       debugPrint("Error enabling PiP: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//         onWillPop: () async {
//           await enablePip();
//           return false;
//         },
//         child: SafeArea(
//           child: Scaffold(
//             backgroundColor: Colors.black,
//             appBar: AppBar(
//               title: const Text('One-to-One Video Call'),
//             ),
//             body: Stack(
//               children: [
//                 // Remote user view (background or bottom half in split screen)
//                 if (_remoteUid != null)
//                   Positioned.fill(
//                     child: GestureDetector(
//                       onTap: () {
//                         // Toggle split-screen mode
//                         setState(() {
//                           _isSplitScreen = !_isSplitScreen;
//                         });
//                       },
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 300),
//                         margin: _remoteUid != null
//                             ? (_isSplitScreen ?EdgeInsets.only(top: MediaQuery.of(context).size.height/2):EdgeInsets.zero ):EdgeInsets.zero,
//                         child: Container(
//
//                           color: Colors.grey[800],
//                           child: isVideoDisabled && muteVideoRemoteId == _remoteUid ?Container(
//                             color: Colors.black,
//                             child: Center(
//                               child: Icon(Icons.person,color: Colors.white,size: 20,),
//                             ),
//                           ):_remoteVideoView(_remoteUid ?? 0),
//                         ),
//                       ),
//                     ),
//                   ),
//
//                 // Local user view (foreground or full screen if no remote user)
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: GestureDetector(
//                     onTap: () {
//                       // Toggle split-screen mode
//                       if (_remoteUid != null) {
//                         setState(() {
//                           _isSplitScreen = !_isSplitScreen;
//                         });
//                       }
//                     },
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       width: _remoteUid != null
//                           ? (_isSplitScreen ? MediaQuery.of(context).size.width : 120.0)
//                           : MediaQuery.of(context).size.width,
//                       height: _remoteUid != null
//                           ? (_isSplitScreen
//                           ? MediaQuery.of(context).size.height*0.5
//                           : 150.0)
//                           : MediaQuery.of(context).size.height,
//                       child: Container(
//                         color: Colors.grey[800],
//                         child: muteVideoRemoteId==0 && isVideoDisabled?Container(
//                           color: Colors.black,
//                           child:Center(child: Icon(Icons.person,color: Colors.white,size: 30,)),
//                         ):_localVideoView(),
//                       ),
//                     ),
//                   ),
//                 ),
//                 _toolbar(),
//                 Observer(
//                   builder: (_) => Align(
//                     alignment: Alignment.bottomCenter,
//                     child: Container(
//                       padding: const EdgeInsets.all(8.0),
//                       color: Colors.black.withOpacity(0.5),
//                       child: Text(
//                         "Network Status: ${authStore.networkStatus}",
//                         style: const TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ));
//   }
// }
//
//
//
//
//
//
//
//
// ///group video call
//
//
// //
// // Group call page
// //
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:math';
// // import 'dart:typed_data';
// //
// // import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// // import 'package:auto_route/annotations.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// //
// // import '../../values/colors.dart';
// //
// // const String appID = '2ac013422f444292914c234d228b87bb'; // Your Agora App ID
// // const String token = "007eJxTYNDmvbaiK4YnKDv9Uns90/fFb+9c+Pz7Z8/8T4nckauDWiYoMBglJhsYGpsYGaWZmJgYWRpZGpokGxmbpBgZWSRZmCclzXrhn94QyMjg7PyCmZEBAkF8HoayzJTUfOfEnJzMvHQGBgDdTyQS"; // Your Agora Token
// //
// // @RoutePage()
// // class CallPage extends StatefulWidget {
// //   /// non-modifiable channel name of the page
// //   final String? channelName;
// //
// //   String? name;
// //
// //   /// non-modifiable client role of the page
// //   final ClientRoleType? role;
// //
// //   /// Creates a call page with given channel name.
// //   CallPage({Key? key, this.channelName, this.name, this.role})
// //       : super(key: key);
// //
// //   @override
// //   _CallPageState createState() => _CallPageState();
// // }
// //
// // class _CallPageState extends State<CallPage>
// //     with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
// //   final _users = <int>[];
// //   final _infoStrings = <String>[];
// //   int? _selectedUserId;
// //   bool isVideoDisabled = false;
// //   bool muted = false;
// //   bool onSpeaker = false;
// //   late RtcEngine _engine;
// //   late final PageController pageController;
// //   int currentPageIndex = 0;
// //   int muteVideoRemoteId = 0;
// //   final Map<int, bool> userVideoStates = {}; // Store video states for all users.
// //   bool isLocalVideoDisabled = false;
// //   int myUid = 0; // Replace with actual user ID.
// //   late int _streamId;
// //
// //
// //   @override
// //   void dispose() {
// //     // clear users
// //     _users.clear();
// //     _dispose();
// //     pageController.dispose();
// //     super.dispose();
// //   }
// //
// //   Future<void> _dispose() async {
// //     // destroy sdk
// //     await _engine.leaveChannel();
// //     await _engine.release();
// //   }
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // initialize agora sdk
// //     initialize();
// //     pageController = PageController(
// //       initialPage: 0,
// //     );
// //   }
// //
// //   Future<void> initialize() async {
// //     if (appID.isEmpty) {
// //       setState(() {
// //         _infoStrings.add(
// //           'APP_ID missing, please provide your APP_ID in settings.dart',
// //         );
// //         _infoStrings.add('Agora Engine is not starting');
// //       });
// //       return;
// //     }
// //
// //     await _initAgoraRtcEngine();
// //     _addAgoraEventHandlers();
// //     VideoEncoderConfiguration configuration = VideoEncoderConfiguration(
// //         dimensions: VideoDimensions(width: 1920, height: 1080));
// //     await _engine.setVideoEncoderConfiguration(configuration);
// //     await _engine.joinChannel(
// //         token: token,
// //         channelId: widget.channelName!,
// //         uid: 0,
// //         options: ChannelMediaOptions());
// //   }
// //
// //   /// Create agora sdk instance and initialize
// //   Future<void> _initAgoraRtcEngine() async {
// //     _engine = createAgoraRtcEngine();
// //     await _engine.initialize(
// //       RtcEngineContext(
// //         appId: appID,
// //         channelProfile: ChannelProfileType.channelProfileCommunication,
// //       ),
// //     );
// //     await _engine.enableVideo();
// //     await _engine
// //         .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
// //     await _engine.setClientRole(role: widget.role!);
// //   }
// //
// //   Future<void> _createDataStream() async {
// //     try {
// //       _streamId = await _engine.createDataStream(DataStreamConfig(syncWithAudio: false,ordered: false));
// //       print("Data stream created with ID: $_streamId");
// //     } catch (e) {
// //       print("Error creating data stream: $e");
// //     }
// //   }
// //
// //
// //   /// Add agora event handlers
// //   void _addAgoraEventHandlers() {
// //     _engine.registerEventHandler(RtcEngineEventHandler(
// //       onError: (err, msg) {
// //             (code) {
// //           setState(() {
// //             final info = 'onError: $code';
// //             _infoStrings.add(info);
// //           });
// //         };
// //       },
// //       onJoinChannelSuccess: (connection, elapsed) {
// //         setState(() {
// //           final info =
// //               'onJoinChannel: ${connection.channelId}, uid: ${connection.localUid}';
// //           _infoStrings.add(info);
// //         });
// //       },
// //       onLeaveChannel: (connection, stats) {
// //         setState(() {
// //           _infoStrings.add('onLeaveChannel');
// //           _users.clear();
// //         });
// //       },
// //       onUserJoined: (connection, remoteUid, elapsed) {
// //         setState(() {
// //           final info = 'userJoined: $remoteUid';
// //           _infoStrings.add(info);
// //           _users.add(remoteUid);
// //           userVideoStates[remoteUid] = false; // Default video state is 'on' when a user joins.
// //         });
// //       },
// //       onUserOffline: (connection, remoteUid, reason) {
// //         setState(() {
// //           final info = 'userOffline: $remoteUid';
// //           _infoStrings.add(info);
// //           _users.remove(remoteUid);
// //           userVideoStates.remove(remoteUid); // Remove the user when they go offline.
// //         });
// //       },
// //       onFirstRemoteVideoFrame: (connection, remoteUid, width, height, elapsed) {
// //         setState(() {
// //           final info = 'firstRemoteVideo: $remoteUid ${width}x $height';
// //           _infoStrings.add(info);
// //         });
// //       },
// //       onUserMuteVideo: (connection, remoteUid, muted) {
// //         setState(() {
// //           userVideoStates[remoteUid] = muted;
// //         });
// //       },
// //       onStreamMessage: (RtcConnection connection, int remoteUid, int streamId, Uint8List data, int length, int sentTs) {
// //         try {
// //           // Decode the received data into a string
// //           String message = String.fromCharCodes(data);
// //
// //           // Parse the JSON message
// //           final decodedMessage = jsonDecode(message);
// //
// //           if (decodedMessage["uid"] != null && decodedMessage["videoMuted"] != null) {
// //             setState(() {
// //               userVideoStates[decodedMessage["uid"]] = decodedMessage["videoMuted"];
// //             });
// //           }
// //         } catch (e) {
// //           print("Error handling stream message: $e");
// //         }
// //       },
// //       onStreamMessageError: (RtcConnection connection, int remoteUid, int streamId, ErrorCodeType error, int missed, int cached) {
// //         print("Stream message error: $error");
// //       },
// //     ));
// //   }
// //
// //   void toggleLocalVideo() {
// //     setState(() {
// //       userVideoStates[0] = !(userVideoStates[0] ?? false); // Toggle local video state.
// //     });
// //
// //     // Mute or unmute the local video stream
// //     _engine.muteLocalVideoStream(userVideoStates[0] ?? false);
// //
// //     // Broadcast the local video state to remote users
// //     if (_streamId != null) {
// //       try {
// //         // Create the message data
// //         String message = jsonEncode({
// //           "uid": 0, // Local user ID
// //           "videoMuted": userVideoStates[0], // Video muted state
// //         });
// //
// //         // Convert the message to Uint8List
// //         Uint8List messageData = Uint8List.fromList(message.codeUnits);
// //
// //         // Calculate the length of the message
// //         int length = messageData.length;
// //
// //         // Send the message with the calculated length
// //         _engine.sendStreamMessage(
// //           streamId: _streamId,
// //           data: messageData,
// //           length: length, // Specify the length here
// //         );
// //       } catch (e) {
// //         print("Error sending stream message: $e");
// //       }
// //     }
// //   }
// //
// //
// //   // Helper function to get list of native views
// //   List<Widget> _getRenderViewsForPageOne() {
// //     final List<Widget> list = [];
// //
// //     // Add local user view
// //     list.add(
// //       GestureDetector(
// //         onDoubleTap: () {
// //           setState(() {
// //             _selectedUserId = 0; // Select local user
// //           });
// //         },
// //         child: (userVideoStates[0] ?? false) // Check if local video is muted
// //             ? Container(
// //           color: Colors.black,
// //           child: Center(
// //             child: Icon(Icons.person, color: Colors.white, size: 50.0),
// //           ),
// //         )
// //             : AgoraVideoView(
// //           controller: VideoViewController(
// //             rtcEngine: _engine,
// //             canvas: VideoCanvas(uid: 0), // Local user's video canvas
// //           ),
// //         ),
// //       ),
// //     );
// //
// //     // Add remote user views
// //     for (var uid in _users.take(min(_users.length, 5))) {
// //       list.add(
// //         GestureDetector(
// //           onDoubleTap: () {
// //             setState(() {
// //               _selectedUserId = uid; // Select remote user
// //             });
// //           },
// //           child: (userVideoStates[uid] ?? false) // Check if remote video is muted
// //               ? Container(
// //             color: Colors.black,
// //             child: Center(
// //               child: Icon(Icons.person, color: Colors.white, size: 50.0),
// //             ),
// //           )
// //               : AgoraVideoView(
// //             key: Key(uid.toString()), // Unique key for each remote view
// //             controller: VideoViewController.remote(
// //               rtcEngine: _engine,
// //               canvas: VideoCanvas(uid: uid), // Remote user's video canvas
// //               connection: RtcConnection(channelId: "videoCalling"),
// //             ),
// //           ),
// //         ),
// //       );
// //     }
// //
// //     return list;
// //   }
// //
// //
// //   List<Widget> _getRenderViewsForPageTwo() {
// //     final List<Widget> list = [];
// //     // Remote views for each user in _users list
// //     if (_users.length > 5)
// //       _users.sublist(5, _users.length).forEach((int uid) {
// //         list.add(
// //           Container(
// //             color: AppColor.green,
// //             child: AgoraVideoView(
// //               key: Key(uid.toString()),
// //               controller: VideoViewController.remote(
// //                 rtcEngine: _engine,
// //                 canvas: VideoCanvas(uid: uid),
// //                 connection: RtcConnection(channelId: "videoCalling"),
// //               ),
// //             ),
// //           ),
// //         );
// //       });
// //
// //     return list;
// //   }
// //
// //   Future<void> _onDisableVideoButton() async {
// //     if (isVideoDisabled == true) {
// //       _engine.disableVideo();
// //     } else {
// //       _engine.enableVideo();
// //     }
// //   }
// //
// //   /// Video view wrapper
// //   Widget _videoView(view) {
// //     return Expanded(child: Container(child: view));
// //   }
// //
// //   /// Video view row wrapper
// //   Widget _expandedVideoRow(List<Widget> views) {
// //     final wrappedViews = views.map<Widget>(_videoView).toList();
// //     return Expanded(
// //       child: Row(
// //         children: wrappedViews,
// //       ),
// //     );
// //   }
// //
// //   /// Video layout wrapper
// //   Widget _viewRows() {
// //     final views = _getRenderViewsForPageOne();
// //     print("views length ${views.length}");
// //     switch (views.length) {
// //       case 1:
// //         return Container(
// //             child: Column(
// //               children: <Widget>[_videoView(views[0])],
// //             ));
// //       case 2:
// //         return Container(
// //             child: Column(
// //               children: <Widget>[
// //                 _expandedVideoRow([views[0]]),
// //                 _expandedVideoRow([views[1]])
// //               ],
// //             ));
// //       case 3:
// //         return Container(
// //             child: Column(
// //               children: <Widget>[
// //                 _expandedVideoRow(views.sublist(0, 2)),
// //                 _expandedVideoRow(views.sublist(2, 3))
// //               ],
// //             ));
// //       case 4:
// //         return Container(
// //           child: Column(
// //             children: <Widget>[
// //               _expandedVideoRow(views.sublist(0, 2)),
// //               _expandedVideoRow(views.sublist(2, 4))
// //             ],
// //           ),
// //         );
// //       case 5:
// //         return Container(
// //           child: Column(
// //             children: <Widget>[
// //               _expandedVideoRow(views.sublist(0, 2)),
// //               _expandedVideoRow(views.sublist(2, 4)),
// //               _expandedVideoRow(views.sublist(4, 5)),
// //             ],
// //           ),
// //         );
// //       case 6:
// //         return Container(
// //           child: Column(
// //             children: <Widget>[
// //               _expandedVideoRow(views.sublist(0, 2)),
// //               _expandedVideoRow(views.sublist(2, 4)),
// //               _expandedVideoRow(views.sublist(4, 6)),
// //             ],
// //           ),
// //         );
// //       default:
// //     }
// //     return Container();
// //   }
// //
// //   Widget _viewSecondRows() {
// //     final views = _getRenderViewsForPageTwo();
// //     switch (views.length) {
// //       case 1:
// //         return Container(
// //             child: Column(
// //               children: <Widget>[_videoView(views[0])],
// //             ));
// //       case 2:
// //         return Container(
// //             child: Column(
// //               children: <Widget>[
// //                 _expandedVideoRow([views[0]]),
// //                 _expandedVideoRow([views[1]])
// //               ],
// //             ));
// //       case 3:
// //         return Container(
// //             child: Column(
// //               children: <Widget>[
// //                 _expandedVideoRow(views.sublist(0, 2)),
// //                 _expandedVideoRow(views.sublist(2, 3))
// //               ],
// //             ));
// //
// //       case 7:
// //         return Container(
// //           child: Column(
// //             children: <Widget>[
// //               _expandedVideoRow(views.sublist(0, 2)),
// //               _expandedVideoRow(views.sublist(2, 4)),
// //               _expandedVideoRow(views.sublist(4, 6)),
// //               _expandedVideoRow(views.sublist(6, 7))
// //             ],
// //           ),
// //         );
// //       case 8:
// //         return Container(
// //           child: Column(
// //             children: <Widget>[
// //               _expandedVideoRow(views.sublist(0, 2)),
// //               _expandedVideoRow(views.sublist(2, 4)),
// //               _expandedVideoRow(views.sublist(4, 6)),
// //               _expandedVideoRow(views.sublist(6, 8))
// //             ],
// //           ),
// //         );
// //       case 9:
// //         return Container(
// //           child: Column(
// //             children: <Widget>[
// //               _expandedVideoRow(views.sublist(0, 2)),
// //               _expandedVideoRow(views.sublist(2, 4)),
// //               _expandedVideoRow(views.sublist(4, 6)),
// //               _expandedVideoRow(views.sublist(6, 8)),
// //               _expandedVideoRow(views.sublist(8, 9))
// //             ],
// //           ),
// //         );
// //
// //       default:
// //     }
// //     return Container();
// //   }
// //
// //   Widget viewBlackContainer() {
// //     return Expanded(
// //       child: Container(
// //         color: Colors.black,
// //       ),
// //     );
// //   }
// //
// //   /// Video layout wrapper
// //
// //   /// Toolbar layout
// //   Widget _toolbar() {
// //     print("users length is ${_users.length}");
// //     // if (widget.role == ClientRoleType.clientRoleAudience) return Container();
// //     return Container(
// //       alignment: Alignment.bottomCenter,
// //       padding: const EdgeInsets.symmetric(vertical: 48),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: <Widget>[
// //           Flexible(
// //             child: RawMaterialButton(
// //               onPressed: () {
// //                 _onToggleMute();
// //               },
// //               child: Icon(
// //                 muted ? Icons.mic_off : Icons.mic,
// //                 color: muted ? Colors.white : Colors.blueAccent,
// //                 size: 20.0,
// //               ),
// //               shape: CircleBorder(),
// //               elevation: 2.0,
// //               fillColor: muted ? Colors.blueAccent : Colors.white,
// //               padding: const EdgeInsets.all(12.0),
// //             ),
// //           ),
// //           Flexible(
// //             child: RawMaterialButton(
// //               onPressed: () {
// //                 _onCallEnd(context);
// //                 Navigator.pop(context);
// //               },
// //               child: Icon(
// //                 Icons.call_end,
// //                 color: Colors.white,
// //                 size: 35.0,
// //               ),
// //               shape: CircleBorder(),
// //               elevation: 2.0,
// //               fillColor: Colors.redAccent,
// //               padding: const EdgeInsets.all(15.0),
// //             ),
// //           ),
// //           Flexible(
// //             child: RawMaterialButton(
// //               onPressed: _onSwitchCamera,
// //               child: Icon(
// //                 Icons.switch_camera,
// //                 color: Colors.blueAccent,
// //                 size: 20.0,
// //               ),
// //               shape: CircleBorder(),
// //               elevation: 2.0,
// //               fillColor: Colors.white,
// //               padding: const EdgeInsets.all(12.0),
// //             ),
// //           ),
// //           Flexible(
// //             child: RawMaterialButton(
// //               onPressed: toggleLocalVideo, // Call toggleLocalVideo method
// //               child: Icon(
// //                 userVideoStates[0] == true
// //                     ? Icons.videocam_off
// //                     : Icons.videocam,
// //                 color: userVideoStates[0] == true
// //                     ? Colors.red
// //                     : Colors.blueAccent,
// //               ),
// //               shape: const CircleBorder(),
// //               elevation: 2.0,
// //               fillColor: Colors.white,
// //               padding: const EdgeInsets.all(12.0),
// //             ),),
// //           Flexible(
// //             child: RawMaterialButton(
// //               onPressed: () {
// //                 setState(() {
// //                   onSpeaker = !onSpeaker;
// //                 });
// //                 _onSpeakerButton();
// //               },
// //               child: Icon(
// //                 onSpeaker ? Icons.volume_off : Icons.volume_up,
// //                 color: Colors.blueAccent,
// //                 size: 25.0,
// //               ),
// //               shape: CircleBorder(),
// //               elevation: 2.0,
// //               fillColor: Colors.white,
// //               padding: const EdgeInsets.all(12.0),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   /// Info panel to show logs
// //
// //   void _onCallEnd(BuildContext context) async {
// //     await _engine.leaveChannel();
// //     await _engine.release();
// //   }
// //
// //   void _onToggleMute() {
// //     setState(() {
// //       muted = !muted;
// //     });
// //     _engine.muteLocalAudioStream(muted);
// //     if (muted == true) {
// //       // toastMessageTxt("Audio is muted of user id is ${_users[0]}");
// //     }
// //   }
// //
// //   void _onSpeakerButton() {
// //     setState(() {
// //       if (onSpeaker == true) {
// //         _engine.disableAudio();
// //       } else {
// //         _engine.enableAudio();
// //       }
// //     });
// //   }
// //
// //   void _onSwitchCamera() {
// //     _engine.switchCamera();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Agora Flutter'),
// //       ),
// //       backgroundColor: Colors.black,
// //       body: Center(
// //         child: Stack(
// //           children: <Widget>[
// //             Positioned.fill(
// //               child: PageView(
// //                 padEnds: false,
// //                 reverse: false,
// //                 physics: BouncingScrollPhysics(),
// //                 onPageChanged: (value) {
// //                   setState(() {
// //                     currentPageIndex = value;
// //                   });
// //                   pageController.animateToPage(
// //                     value,
// //                     duration: Duration(milliseconds: 300),
// //                     curve: Curves.easeInOut,
// //                   );
// //                 },
// //                 scrollDirection: Axis.horizontal,
// //                 children: [
// //                   if (_selectedUserId != null)
// //                     Positioned.fill(
// //                       child: GestureDetector(
// //                         onDoubleTap: () {
// //                           setState(() {
// //                             _selectedUserId =
// //                             null; // Reset the selected view on double-tap
// //                           });
// //                         },
// //                         child: Stack(
// //                           children: [
// //                             // Background: Fullscreen video for the selected user
// //                             Center(
// //                               child: AgoraVideoView(
// //                                 controller: _selectedUserId == 0
// //                                     ? VideoViewController(
// //                                   rtcEngine: _engine,
// //                                   canvas: VideoCanvas(uid: 0),
// //                                 )
// //                                     : VideoViewController.remote(
// //                                   rtcEngine: _engine,
// //                                   canvas:
// //                                   VideoCanvas(uid: _selectedUserId!),
// //                                   connection: RtcConnection(
// //                                       channelId: "videoCalling"),
// //                                 ),
// //                               ),
// //                             ),
// //
// //                             // Local view: Small video window positioned in the top-left corner
// //                             Positioned(
// //                               top: 16, // Adjust for padding
// //                               left: 16, // Adjust for padding
// //                               child: GestureDetector(
// //                                   onDoubleTap: () {
// //                                     setState(() {
// //                                       _selectedUserId =
// //                                       0; // Switch to local user view on tap
// //                                     });
// //                                   },
// //                                   child: _selectedUserId == 0
// //                                       ? SizedBox.shrink()
// //                                       : Container(
// //                                     width: 200,
// //                                     height: 200,
// //                                     decoration: BoxDecoration(
// //                                       border: Border.all(
// //                                           color: Colors.white, width: 2),
// //                                       borderRadius:
// //                                       BorderRadius.circular(8),
// //                                       color: Colors.black,
// //                                     ),
// //                                     child: AgoraVideoView(
// //                                       controller: VideoViewController(
// //                                         rtcEngine: _engine,
// //                                         canvas: VideoCanvas(uid: 0),
// //                                       ),
// //                                     ),
// //                                   )),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   _viewRows(),
// //                   _viewSecondRows(),
// //
// //                   // _viewRows(),
// //                   // viewRowsFirstPage(),
// //                 ],
// //                 controller: pageController,
// //               ),
// //             ),
// //             // _viewRows(),
// //             // _panel(),
// //             _toolbar(),
// //             _users.length >= 1
// //                 ? Positioned(
// //               top: MediaQuery.of(context).size.height /
// //                   1.55, // Adjust this value to position the PageView indicator
// //               left: 0,
// //               right: 0,
// //               child: SizedBox(
// //                 height: 100,
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: List.generate(
// //                     2,
// //                         (index) {
// //                       return GestureDetector(
// //                         onTap: () {
// //                           pageController.animateToPage(
// //                             index,
// //                             duration: Duration(milliseconds: 300),
// //                             curve: Curves.easeInOut,
// //                           );
// //                           print("select index is ${index}");
// //                         },
// //                         child: Container(
// //                           margin: EdgeInsets.all(5),
// //                           height: 10.h,
// //                           width: 10.w,
// //                           decoration: BoxDecoration(
// //                             color: currentPageIndex == index
// //                                 ? Colors.blue
// //                                 : AppColor.greyTealColor,
// //                             shape: BoxShape.circle,
// //                             border:
// //                             Border.all(color: Colors.white, width: 2),
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ),
// //               ),
// //             )
// //                 : SizedBox.shrink(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   // TODO: implement wantKeepAlive
// //   bool get wantKeepAlive => true;
// // }
// //
// //
