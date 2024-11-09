

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:flutter_demo_structure/values/colors.dart';
import 'package:flutter_demo_structure/values/extensions/widget_ext.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

// Fill in the app ID obtained from the Agora Console
const appId = "2ac013422f444292914c234d228b87bb";
// Fill in the temporary token generated from Agora Console
const token =
    "007eJxTYHD+/oV7rjpP0/r8w5EnDmSULojbvTbRJiUvePKsi8HvZ61XYDBKTDYwNDYxMkozMTExsjSyNDRJNjI2STEyskiyME9KEtqqm94QyMjQfOE1CyMDBIL4PAxlmSmp+c6JOTmZeekMDACQpCMu";
// Fill in the channel name you used to generate the token
const channel = "videoCalling";

// Application class
@RoutePage()
class VideoCallingPage extends StatefulWidget {
  const VideoCallingPage({Key? key}) : super(key: key);
  @override
  _VideoCallingPageState createState() => _VideoCallingPageState();
}
// Application state class
class _VideoCallingPageState extends State<VideoCallingPage> {
  int? _remoteUid; // The UID of the remote user
  bool _localUserJoined =
      false; // Indicates whether the local user has joined the channel
  late RtcEngine _engine; // The RtcEngine instances

  @override
  void initState() {
    super.initState();
    initAgora();
  }
  Future<void> initAgora() async {
    // Request microphone and camera permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RtcEngine instance
    _engine = await createAgoraRtcEngine();

    // Initialize RtcEngine and set the channel profile to communication mode
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('local user ${connection.localUid} joined');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    // Enable video module
    await _engine.enableVideo();

    // Setup local video without mirror mode (this should be honored by supported SDK versions)
    await _engine.setupLocalVideo(
      VideoCanvas(
        uid: 0, // Set to 0 to let Agora auto-assign UID
        renderMode: RenderModeType.renderModeHidden, // Render mode to fit the view
        mirrorMode: VideoMirrorModeType.videoMirrorModeDisabled, // Disable mirror mode
      ),
    );

    // Start local video preview
    await _engine.startPreview();

    // Join the channel with a token, channel name, and options
    await _engine.joinChannel(
      token: token,
      channelId: channel,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0, // Set to 0 to allow Agora to assign a unique UID
    );
  }



  // Future<void> initAgora() async {
  //   // Get microphone and camera permissions
  //   await [Permission.microphone, Permission.camera].request();
  //   // Create RtcEngine instance
  //   _engine = await createAgoraRtcEngine();
  //   // Initialize RtcEngine and set the channel profile to live broadcasting
  //   await _engine.initialize(const RtcEngineContext(
  //     appId: appId,
  //     channelProfile: ChannelProfileType.channelProfileCommunication,
  //   ));
  //   // Add an event handler
  //   _engine.registerEventHandler(
  //     RtcEngineEventHandler(
  //       // Occurs when the local user joins the channel successfully
  //       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //         debugPrint(
  //             'local user ' + connection.localUid.toString() + ' joined');
  //         setState(() {
  //           _localUserJoined = true;
  //         });
  //       },
  //       // Occurs when a remote user join the channel
  //       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //         debugPrint("remote user $remoteUid joined");
  //         setState(() {
  //           _remoteUid = remoteUid;
  //         });
  //       },
  //       // Occurs when a remote user leaves the channel
  //       onUserOffline: (RtcConnection connection, int remoteUid,
  //           UserOfflineReasonType reason) {
  //         debugPrint("remote user $remoteUid left channel");
  //         setState(() {
  //           _remoteUid = null;
  //         });
  //       },
  //     ),
  //   );
  //   // Enable the video module
  //   await _engine.enableVideo();
  //  
  //   // Enable local video preview
  //   await _engine.startPreview();
  //   // Join a channel using a temporary token and channel name
  //   await _engine.joinChannel(
  //     token: token,
  //     channelId: channel,
  //     options: const ChannelMediaOptions(
  //         // Automatically subscribe to all video streams
  //         autoSubscribeVideo: true,
  //         // Automatically subscribe to all audio streams
  //         autoSubscribeAudio: true,
  //         // Publish camera video
  //         publishCameraTrack: true,
  //         // Publish microphone audio
  //         publishMicrophoneTrack: true,
  //         // Set user role to clientRoleBroadcaster (broadcaster) or clientRoleAudience (audience)
  //         clientRoleType: ClientRoleType.clientRoleBroadcaster),
  //     uid:
  //         0, // When you set uid to 0, a user name is randomly generated by the engine
  //   );
  // }

  void toggleScreenSize() {
    setState(() {
      // Toggle between half-half screen and initial size on tap
      if (localUserHeight == 150.h) {
        // Change to half-half screen on tap
        localUserHeight = 0.45.sh;
        localUserWidth = 1.sw;
        receiverUserHeight = 0.45.sh;
        receiverUserWidth = 1.sw;
      } else {
        // Reset to original size on second tap
        localUserHeight = 150.h;
        localUserWidth = 100.w;
        receiverUserHeight = 1.sh;
        receiverUserWidth = 1.sw;
      }
      isHalfScreen = !isHalfScreen;
      print(isHalfScreen); // Debugging print statement
    });
  }


  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    // Leave the channel
    await _engine.leaveChannel();
    // Release resources
    await _engine.release();
  }

  double localUserHeight = 150.h;
  double localUserWidth = 100.w;
  double receiverUserHeight = 1.sh;
  double receiverUserWidth = 1.sw;
  bool isHalfScreen = true;
  // Build the UI to display local and remote videos
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColor.black,
        appBar: AppBar(
          title: const Text('Agora Video Call'),
        ),
        body: Column(
          children: [
            isHalfScreen? Flexible(
              child: Stack(
                fit: StackFit.loose,
                children: [
                  Positioned(
                    bottom: 10,
                    // top: localUserHeight == 150.h?0:0.5.sh,
                    left: 0,
                    child: _remoteVideo()
                  ),
                  GestureDetector(
                      onTap: () {
                        toggleScreenSize();
                      },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0), // Set the desired border radius
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: localUserWidth,
                          height: localUserHeight,
                          child: Center(
                            child: _localUserJoined
                                ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: _engine,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                                : const CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    )).wrapPaddingAll(10.h)
                ],
              ),
            ):
                Expanded(child: buildHalfScreenVideoView())

          ],
        ),
      ),
    );
  }

  Widget buildHalfScreenVideoView() {
    return Column(
      children: [
        // Top half for Local User Video
        Expanded(
          child: GestureDetector(
            onTap: () {
              toggleScreenSize();
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        ),

        // Bottom half for Remote User Video
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16.0),
              bottomRight: Radius.circular(16.0),
            ),
            child: Center(
              child: _remoteUid != null
                  ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: channel),
                ),
              )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }



  // Widget to display remote video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: SizedBox(
          height: receiverUserHeight,
          width: receiverUserWidth,
          child: AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(channelId: channel),
            ),
          ),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }
}
