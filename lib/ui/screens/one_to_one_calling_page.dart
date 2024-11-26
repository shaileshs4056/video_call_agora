import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Agora details
const appId = "2ac013422f444292914c234d228b87bb";
const token = "007eJxTYOC03x6d88HtVeuer8nzfXbcrzH4+uaB0f7tv+P5b1gG/zyuwGCUmGxgaGxiZJRmYmJiZGlkaWiSbGRskmJkZJFkYZ6UZNHjmt4QyMhQlmvLysgAgSA+D0NZZkpqvnNiTk5mXjoDAwAPeSPu";
const channel = "videoCalling";

class VideoCallingPage extends StatefulWidget {
  const VideoCallingPage({Key? key}) : super(key: key);

  @override
  _VideoCallingPageState createState() => _VideoCallingPageState();
}

class _VideoCallingPageState extends State<VideoCallingPage> {
  late RtcEngine _engine; // Agora engine instance
  bool _localUserJoined = false; // Indicates local user joined
  int? _remoteUid; // Remote user's UID
  bool isVideoDisabled = false;
  bool muted = false;
  bool onSpeaker = false;
  int currentPageIndex = 0;
  int muteVideoRemoteId = 0;
  bool _isSplitScreen = false;
  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Request microphone and camera permissions
    await [Permission.microphone, Permission.camera].request();

    // Initialize Agora engine
    _engine = await createAgoraRtcEngine();
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
          debugPrint("Local user joined: ${connection.localUid}");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user left: $remoteUid");
          setState(() {
            _remoteUid = null;
          });
        },
        onUserMuteVideo: (connection, remoteUid, muted) {
          setState(() {
            if (muted) {
              isVideoDisabled = muted;
              print("User with remoteUid $remoteUid has disabled their video.");
              muteVideoRemoteId = remoteUid;
              // Handle the case when video is disabled
            } else {
              isVideoDisabled = muted;
              print("User with remoteUid $remoteUid has enabled their video.");
              // Handle the case when video is enabled
            }
          });
        },
      ),
    );

    // Enable video and join channel
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  /// Info panel to show logs

  void _onCallEnd(BuildContext context) async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
    if (muted == true) {
      // toastMessageTxt("Audio is muted of user id is ${_users[0]}");
    }
  }

  void _onSpeakerButton() {
    setState(() {
      if (onSpeaker == true) {
        _engine.disableAudio();
      } else {
        _engine.enableAudio();
      }
    });
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }


  Future<void> _onDisableVideoButton() async {
    if (isVideoDisabled == true) {
      _engine.disableVideo();
    } else {
      _engine.enableVideo();
    }
  }

  Widget _toolbar() {
    // if (widget.role == ClientRoleType.clientRoleAudience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: RawMaterialButton(
              onPressed: _onSwitchCamera,
              child: Icon(
                Icons.switch_camera,
                color: Colors.blueAccent,
                size: 18.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: () {
                _onToggleMute();
              },
              child: Icon(
                muted ? Icons.mic_off : Icons.mic,
                color: muted ? Colors.white : Colors.blueAccent,
                size: 18.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: muted ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12.0),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: () {
                _onCallEnd(context);
                Navigator.pop(context);
              },
              child: Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(15.0),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: () {
                setState(() {
                  isVideoDisabled=!isVideoDisabled;
                });
                _onDisableVideoButton();
              },
              child: Icon(
                isVideoDisabled ? Icons.videocam_off : Icons.videocam,
                color: Colors.blueAccent,
                size: 25.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: () {
                setState(() {
                  onSpeaker = !onSpeaker;
                });
                _onSpeakerButton();
              },
              child: Icon(
                onSpeaker ? Icons.volume_off : Icons.volume_up,
                color: Colors.blueAccent,
                size: 18.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _disposeAgora();
  }

  Future<void> _disposeAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  Widget _localVideoView() {
    if (_localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _remoteVideoView() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid!),
          connection: RtcConnection(channelId: channel),
        ),
      );
    } else {
      return const Center(
        child: Text(
          "Waiting for remote user to join...",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('One-to-One Video Call'),
      ),
      body: Stack(
        children: [
          // Remote user view (background or bottom half in split screen)
          if (_remoteUid != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Toggle split-screen mode
                  setState(() {
                    _isSplitScreen = !_isSplitScreen;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: _remoteUid != null
    ? (_isSplitScreen ?EdgeInsets.only(top: MediaQuery.of(context).size.height/2):EdgeInsets.zero ):EdgeInsets.zero,
                  // width: _remoteUid != null
                  //     ? (_isSplitScreen ? MediaQuery.of(context).size.width : 120.0)
                  //     : MediaQuery.of(context).size.width,
                  // height: _remoteUid != null
                  //     ? (_isSplitScreen
                  //     ? MediaQuery.of(context).size.height*0.5
                  //     : 150.0)
                  //     : MediaQuery.of(context).size.height,
                  child: Container(

                    color: Colors.grey[800],
                    child: muteVideoRemoteId == _remoteUid && isVideoDisabled ?Container(
                      color: Colors.black,
                      child: Center(
                        child: Icon(Icons.person,color: Colors.white,size: 20,),
                      ),
                    ):_remoteVideoView(),
                  ),
                ),
              ),
            ),

          // Local user view (foreground or full screen if no remote user)
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                // Toggle split-screen mode
                if (_remoteUid != null) {
                  setState(() {
                    _isSplitScreen = !_isSplitScreen;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _remoteUid != null
                    ? (_isSplitScreen ? MediaQuery.of(context).size.width : 120.0)
                    : MediaQuery.of(context).size.width,
                height: _remoteUid != null
                    ? (_isSplitScreen
                    ? MediaQuery.of(context).size.height*0.5
                    : 150.0)
                    : MediaQuery.of(context).size.height,
                child: Container(
                  color: Colors.grey[800],
                  child: muteVideoRemoteId == 0 && isVideoDisabled?Container(
                    color: Colors.black,
                    child:Center(child: Icon(Icons.person,color: Colors.white,size: 30,)),
                  ):_localVideoView(),
                ),
              ),
            ),
          ),
          _toolbar()
        ],
      ),
    );
  }
}
