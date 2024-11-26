import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:auto_route/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_structure/ui/auth/store/auth_store.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
// Agora details
const appId = "2ac013422f444292914c234d228b87bb";
const token = "007eJxTYDAoVeqJuy7s1TT9++cyW8fzZwJlM59u/PyqZqF8UBzDgqUKDEaJyQaGxiZGRmkmJiZGlkaWhibJRsYmKUZGFkkW5klJlkG+6Q2BjAwhtguZGBkgEMTnYSjLTEnNd07MycnMS2dgAAAbmCEb";
const channel = "videoCalling";

@RoutePage()
class VideoCallingPage extends StatefulWidget {
  const VideoCallingPage({Key? key}) : super(key: key);

  @override
  _VideoCallingPageState createState() => _VideoCallingPageState();
}

class _VideoCallingPageState extends State<VideoCallingPage>  with WidgetsBindingObserver {
  late RtcEngine _engine; // Agora engine instance
  bool _localUserJoined = false; // Indicates local user joined
  final Floating floating = Floating();
  int? _remoteUid; // Remote user's UID
  bool isVideoDisabled = false;
  bool muted = false;
  bool onSpeaker = false;
  int currentPageIndex = 0;
  bool remoteUserVideoOff=false;
  int muteVideoRemoteId = 0;
  bool _isSplitScreen = false;
  bool isPipEnabled = false; // Tracks if PiP is active
  StreamSubscription<ConnectivityResult>? _subscription;
  bool onVideoOff=false;


  /// initState method
  @override
  void initState() {
    super.initState();
    _initAgora();
    WidgetsBinding.instance.addObserver(this);
    startMonitoring();
    authStore.startMonitoring();
  }

  ///dispose method
  @override
  void dispose() {
    super.dispose();
    _disposeAgora();
    WidgetsBinding.instance.removeObserver(this);
    authStore.stopMonitoring();
  }
/// didChange method
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !isPipEnabled) {
      togglePipMode(); // Enable PiP when app is minimized
    }
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
    });
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
  /// Info panel to show logs

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
  void _onCallEnd(BuildContext context) async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  Future<void> _disposeAgora() async {
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
      // _engine.disableVideo();
      setState((){
        isVideoDisabled=!isVideoDisabled;
        onVideoOff=isVideoDisabled;
      });

    } else {
      // _engine.enableVideo();
      setState((){
        isVideoDisabled=!isVideoDisabled;
        onVideoOff=isVideoDisabled;
      });
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
                _onDisableVideoButton();

              },
              child: Icon(
                onVideoOff ? Icons.videocam_off : Icons.videocam,
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
        ? (_isSplitScreen ? EdgeInsets.only(top: MediaQuery.of(context).size.height/2):EdgeInsets.zero ):EdgeInsets.zero,
                      child: Container(
                        color: Colors.grey[800],
                        child: muteVideoRemoteId == _remoteUid?Container(
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
                      child: onVideoOff ?Container(
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
      ),
    );
  }
}
