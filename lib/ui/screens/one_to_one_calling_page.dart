import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:auto_route/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/store/auth_store.dart';
// Agora details
const appId = "2ac013422f444292914c234d228b87bb";
const token = "007eJxTYFBUP5ze3dsYu8dV7281Y+nqWNWY9Z79lcu7csOq5hx0EFFgMEpMNjA0NjEySjMxMTGyNLI0NEk2MjZJMTKySLIwT0q6bhWZ3hDIyCCzNZiZkQECQXwehrLMlNR858ScnMy8dAYGAJbRH9s=";
const channel = "videoCalling";
@RoutePage()
class VideoCallingPage extends StatefulWidget {
  const VideoCallingPage({Key? key}) : super(key: key);
  @override
  _VideoCallingPageState createState() => _VideoCallingPageState();
}

class _VideoCallingPageState extends State<VideoCallingPage> with WidgetsBindingObserver {
  late RtcEngine _engine; // Agora engine instance
  bool _localUserJoined = false; // Indicates local user joined
  int? _remoteUid; // Remote user's UID
  bool isVideoDisabled = false;
  bool muted = false;
  bool onSpeaker = false;
  int currentPageIndex = 0;
  bool onVideoOff=false;
  int muteVideoRemoteId = 0;
  bool isLocalVideoDisabled = false;
  Map<int, bool> remoteVideoStates = {};// Tracks local user's video status
  bool _isSplitScreen = false;
  final Floating floating = Floating();
  bool isPipEnabled = false; // Tracks if PiP is active
  StreamSubscription<ConnectivityResult>? _subscription;
  @override
  void initState() {
    super.initState();
    _initAgora();
    WidgetsBinding.instance.addObserver(this);
    startMonitoring();
    authStore.startMonitoring();
  }

  ///start monitoring internet connection

  void startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        // No internet connection
        Fluttertoast.showToast(
          msg: "Network disconnected! Check your internet connection.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        // Internet connection restored
        Fluttertoast.showToast(
          msg: "Network reconnected!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    }
    );
  }

  ///stop monitoring
  /// Method to stop monitoring connectivity.
  void stopConnectivityMonitoring() {
  }

  void togglePipMode() {
    setState(() {
      isPipEnabled = !isPipEnabled;
    });
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
        onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
          debugPrint("Remote user $remoteUid has ${muted ? 'disabled' : 'enabled'} their video.");
          setState(() {
            remoteVideoStates[remoteUid] = muted; // Update the remote user's video state
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
    setState(() {
      isVideoDisabled = !isVideoDisabled; // Toggle local video state
    });

    // Notify the Agora SDK about local video mute/unmute
    await _engine.muteLocalVideoStream(isVideoDisabled);

    if (isVideoDisabled) {
      print("Local user has disabled their video.");
    } else {
      print("Local user has enabled their video.");
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
              onPressed: _toggleLocalVideo,
              child: Icon(
                isLocalVideoDisabled ? Icons.videocam_off : Icons.videocam,
                color: isLocalVideoDisabled ? Colors.red : Colors.blueAccent,
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

  // Function to toggle local video
  Future<void> _toggleLocalVideo() async {
    setState(() {
      isLocalVideoDisabled = !isLocalVideoDisabled; // Toggle local video state
    });

    // Notify the Agora SDK about the local video state
    await _engine.muteLocalVideoStream(isLocalVideoDisabled);

    if (isLocalVideoDisabled) {
      print("Local user has disabled their video.");
    } else {
      print("Local user has enabled their video.");
    }
  }

  Widget _localVideoView() {
    if (_localUserJoined) {
      return isLocalVideoDisabled
          ? _placeholderView()
          : AgoraVideoView(
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

  Widget _placeholderView() {
    return Container(
      color: Colors.black,
      child: Center(
          child: Icon(Icons.person,color: Colors.white,size: 30,)
      ),
    );
  }


  // Remote Video View
  Widget _remoteVideoView(int remoteUid) {
    if (remoteVideoStates.containsKey(remoteUid)) {
      bool isRemoteVideoDisabled = remoteVideoStates[remoteUid] ?? false;

      return isRemoteVideoDisabled
          ? Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.person, color: Colors.white, size: 50),
        ),
      )
          : AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: remoteUid),
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


  Future<void> enablePip() async {
    try {
      final status = await floating.enable(const ImmediatePiP());
      debugPrint("PiP status: $status");
    } catch (e) {
      debugPrint("Error enabling PiP: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          await enablePip();
          return false;
        },
        child: SafeArea(
          child: Scaffold(
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
                        child: Container(

                          color: Colors.grey[800],
                          child: isVideoDisabled && muteVideoRemoteId == _remoteUid ?Container(
                            color: Colors.black,
                            child: Center(
                              child: Icon(Icons.person,color: Colors.white,size: 20,),
                            ),
                          ):_remoteVideoView(_remoteUid ?? 0),
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
                        child: muteVideoRemoteId==0 && isVideoDisabled?Container(
                          color: Colors.black,
                          child:Center(child: Icon(Icons.person,color: Colors.white,size: 30,)),
                        ):_localVideoView(),
                      ),
                    ),
                  ),
                ),
                _toolbar(),
                Observer(
                  builder: (_) => Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.black.withOpacity(0.5),
                      child: Text(
                        "Network Status: ${authStore.networkStatus}",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
