import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:auto_route/annotations.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_structure/values/colors.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../auth/store/auth_store.dart';

const String appID = '2ac013422f444292914c234d228b87bb'; // Your Agora App ID
const String token = "007eJxTYFBUP5ze3dsYu8dV7281Y+nqWNWY9Z79lcu7csOq5hx0EFFgMEpMNjA0NjEySjMxMTGyNLI0NEk2MjZJMTKySLIwT0q6bhWZ3hDIyCCzNZiZkQECQXwehrLMlNR858ScnMy8dAYGAJbRH9s="; // Your Agora Token

@RoutePage()
class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String? channelName;

  String? name;

  /// non-modifiable client role of the page
  final ClientRoleType? role;

  /// Creates a call page with given channel name.
  CallPage({Key? key, this.channelName, this.name, this.role})
      : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _users = <int>[];
  final _infoStrings = <String>[];
  final Floating floating = Floating();
  int? _selectedUserId;
  bool isVideoDisabled = false;
  bool muted = false;
  bool onSpeaker = false;
  late RtcEngine _engine;
  late final PageController pageController;
  int currentPageIndex = 0;
  int muteVideoRemoteId = 0;
  final Map<int, bool> userVideoStates = {}; // Store video states for all users.
  bool isLocalVideoDisabled = false;
  int myUid = 0; // Replace with actual user ID.
  int? _streamId;

  @override
  void dispose() {
    // clear users
    _users.clear();
    _dispose();
    pageController.dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    // destroy sdk
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
    WidgetsBinding.instance.addObserver(this);
    authStore.startMonitoring();
    pageController = PageController(
      initialPage: 0,
    );
  }

  Future<void> initialize() async {
    if (appID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 1920, height: 1080));
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(
        token: token,
        channelId: widget.channelName!,
        uid: 0,
        options: ChannelMediaOptions());
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: appID,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    await _engine.enableVideo();
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: widget.role!);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) {
            (code) {
          setState(() {
            final info = 'onError: $code';
            _infoStrings.add(info);
          });
        };
      },
      onJoinChannelSuccess: (connection, elapsed) {
        setState(() {
          final info =
              'onJoinChannel: ${connection.channelId}, uid: ${connection.localUid}';
          _infoStrings.add(info);
        });
      },
      onLeaveChannel: (connection, stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
        });
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() {
          final info = 'userJoined: $remoteUid';
          _infoStrings.add(info);
          _users.add(remoteUid);
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        setState(() {
          final info = 'userOffline: $remoteUid';
          _infoStrings.add(info);
          _users.remove(remoteUid);
        });
      },
      onFirstRemoteVideoFrame: (connection, remoteUid, width, height, elapsed) {
        setState(() {
          final info = 'firstRemoteVideo: $remoteUid ${width}x $height';
          _infoStrings.add(info);
        });
      },
      onUserMuteVideo: (connection, remoteUid, muted) {
        setState(() {
          userVideoStates[remoteUid] = muted;
        });
      },
      onStreamMessage: (RtcConnection connection, int remoteUid, int streamId, Uint8List data, int length, int sentTs) {
        try {
          // Decode the received data into a string
          String message = String.fromCharCodes(data);

          // Parse the JSON message
          final decodedMessage = jsonDecode(message);

          if (decodedMessage["uid"] != null && decodedMessage["videoMuted"] != null) {
            setState(() {
              userVideoStates[decodedMessage["uid"]] = decodedMessage["videoMuted"];
            });
          }
        } catch (e) {
          print("Error handling stream message: $e");
        }
      },
      onStreamMessageError: (RtcConnection connection, int remoteUid, int streamId, ErrorCodeType error, int missed, int cached) {
        print("Stream message error: $error");
      },
    ));
  }


  void toggleLocalVideo() {
    setState(() {
      userVideoStates[0] = !(userVideoStates[0] ?? false); // Toggle local video state.
    });

    // Mute or unmute the local video stream
    _engine.muteLocalVideoStream(userVideoStates[0] ?? false);

    // Broadcast the local video state to remote users
    if (_streamId != null) {
      try {
        // Create the message data
        String message = jsonEncode({
          "uid": 0, // Local user ID
          "videoMuted": userVideoStates[0], // Video muted state
        });

        // Convert the message to Uint8List
        Uint8List messageData = Uint8List.fromList(message.codeUnits);

        // Calculate the length of the message
        int length = messageData.length;

        // Send the message with the calculated length
        _engine.sendStreamMessage(
          streamId: _streamId!,
          data: messageData,
          length: length, // Specify the length here
        );
      } catch (e) {
        print("Error sending stream message: $e");
      }
    }
  }

  // Helper function to get list of native views
  List<Widget> _getRenderViewsForPageOne() {
    final List<Widget> list = [];

    // Add local user view
    list.add(
      GestureDetector(
        onDoubleTap: () {
          setState(() {
            _selectedUserId = 0; // Select local user
          });
        },
        child: (userVideoStates[0] ?? false) // Check if local video is muted
            ? Container(
          color: Colors.black,
          child: Center(
            child: Icon(Icons.person, color: Colors.white, size: 50.0),
          ),
        )
            : AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: 0), // Local user's video canvas
          ),
        ),
      ),
    );

    // Add remote user views
    for (var uid in _users.take(min(_users.length, 5))) {
      list.add(
        GestureDetector(
          onDoubleTap: () {
            setState(() {
              _selectedUserId = uid; // Select remote user
            });
          },
          child: (userVideoStates[uid] ?? false) // Check if remote video is muted
              ? Container(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.person, color: Colors.white, size: 50.0),
            ),
          )
              : AgoraVideoView(
            key: Key(uid.toString()), // Unique key for each remote view
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: uid), // Remote user's video canvas
              connection: RtcConnection(channelId: "videoCalling"),
            ),
          ),
        ),
      );
    }

    return list;
  }


  //runnig

  List<Widget> _getRenderViewsForPageTwo() {
    final List<Widget> list = [];

    // Add local user view


    /*// Local view
    list.add(
      Container(
        color: AppColor.red,
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: 0), // 0 for the local user
          ),
        ),
      ),
    );*/

    // Remote views for each user in _users list
    if(_users.length>5)
      _users.sublist(5,_users.length).forEach((int uid) {

        list.add(
          GestureDetector(
            onDoubleTap: () {
              setState(() {
                _selectedUserId = uid; // Select remote user
              });
            },
            child: (userVideoStates[uid] ?? false) // Check if remote video is muted
                ? Container(
              color: Colors.black,
              child: Center(
                child: Icon(Icons.person, color: Colors.white, size: 50.0),
              ),
            ):Container(
              color: AppColor.green,
              child: AgoraVideoView(
                key: Key(uid.toString()), // Unique key for each remote view
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: uid), // Remote user's video canvas
                  connection: RtcConnection(channelId: "videoCalling"),
                ),
              ),
            ),
          ),
        );
      });

    return list;
  }

  // List<Widget> _getRenderViewsForPageTwo() {
  //   final List<Widget> list = [];
  //   // Check if there are users beyond the first 5
  //   if (_users.length > 5) {
  //
  //     // Iterate through users starting from index 5
  //     _users.sublist(5, _users.length).forEach((int uid) {
  //       list.add(
  //         GestureDetector(
  //           onTap: () {
  //             // Toggle video on/off for the user
  //             // setState(() {
  //             //   userVideoStates[uid] = !(userVideoStates[uid] ?? true);
  //             // });
  //           },
  //           child: Container(
  //             child: userVideoStates[uid] ?? false // Check if video is ON
  //                 ? Container(
  //               color: Colors.black,
  //               child: Center(
  //                 child: Icon(Icons.person, color: Colors.white, size: 50.0),
  //               ),
  //             )
  //                 : AgoraVideoView(
  //               key: Key(uid.toString()), // Unique key for each remote view
  //               controller: VideoViewController.remote(
  //                 rtcEngine: _engine,
  //                 canvas: VideoCanvas(uid: uid), // Remote user's video canvas
  //                 connection: RtcConnection(channelId: "videoCalling"),
  //               ),
  //             ),
  //
  //           ),
  //         ),
  //       );
  //     });
  //   }
  //   return list;
  // }
  //

  // List<Widget> _getRenderViewsForPageTwo() {
  //   final List<Widget> list = [];
  //   if(_users.length>5){
  //     _users.sublist(5, _users.length).forEach((int uid) {
  //       list.add(
  //         GestureDetector(
  //           onDoubleTap: () {
  //             setState(() {
  //               _selectedUserId = uid; // Select remote user
  //             });
  //           },
  //           child: (userVideoStates[uid] ?? false) // Check if remote video is muted
  //               ? Container(
  //             color: Colors.black,
  //             child: Center(
  //               child: Icon(Icons.person, color: Colors.white, size: 50.0),
  //             ),
  //           )
  //               : AgoraVideoView(
  //             key: Key(uid.toString()), // Unique key for each remote view
  //             controller: VideoViewController.remote(
  //               rtcEngine: _engine,
  //               canvas: VideoCanvas(uid: uid), // Remote user's video canvas
  //               connection: RtcConnection(channelId: "videoCalling"),
  //             ),
  //           ),
  //         ),
  //       );
  //     });
  //   }
  //   return list;
  // }
  Future<void> _onDisableVideoButton() async {
    if (isVideoDisabled == true) {
      _engine.disableVideo();
    } else {
      _engine.enableVideo();
    }
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  Widget _secondPageExpandedVideoRow(List<Widget> views) {
    return Expanded(
      child: Row(
        children: views.map((view) {
          return Expanded(
            child: view, // Directly render the widget or placeholder
          );
        }).toList(),
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViewsForPageOne();
    print("views length ${views.length}");
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
              children: <Widget>[_videoView(views[0])],
            ));
      case 2:
        return Container(
            child: Column(
              children: <Widget>[
                _expandedVideoRow([views[0]]),
                _expandedVideoRow([views[1]])
              ],
            ));
      case 3:
        return Container(
            child: Column(
              children: <Widget>[
                _expandedVideoRow(views.sublist(0, 2)),
                _expandedVideoRow(views.sublist(2, 3))
              ],
            ));
      case 4:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 4))
            ],
          ),
        );
      case 5:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 4)),
              _expandedVideoRow(views.sublist(4, 5)),
            ],
          ),
        );
      case 6:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 4)),
              _expandedVideoRow(views.sublist(4, 6)),
            ],
          ),
        );
      default:
    }
    return Container();
  }
  // Widget _viewRows() {
  //   final views = _getRenderViewsForPageOne();
  //
  //   // Ensure 6 slots, replacing null with placeholders
  //   final paddedViews = List.generate(
  //     6,
  //         (index) => index < views.length ? _videoView(views[index]) : Container(color: Colors.black),
  //   );
  //
  //   return Container(
  //     child: Column(
  //       children: [
  //         _expandedVideoRow(paddedViews.sublist(0, 2)),
  //         _expandedVideoRow(paddedViews.sublist(2, 4)),
  //         _expandedVideoRow(paddedViews.sublist(4, 6)),
  //       ],
  //     ),
  //   );
  // }
  Widget _viewSecondRows() {
    final views = _getRenderViewsForPageTwo();

    // Ensure 6 slots with placeholders for missing views
    final paddedViews = List.generate(
      6,
          (index) => index < views.length ? _videoView(views[index]) : Container(color: Colors.black), // Placeholder
    );

    return Container(
      child: Column(
        children: [
          _secondPageExpandedVideoRow(paddedViews.sublist(0, 2)),
          _secondPageExpandedVideoRow(paddedViews.sublist(2, 4)),
          _secondPageExpandedVideoRow(paddedViews.sublist(4, 6)),
        ],
      ),
    );
  }

  // Widget _viewSecondRows() {
  //   final views = _getRenderViewsForPageTwo();
  //   switch (views.length) {
  //     case 1:
  //       return Container(
  //           child: Column(
  //             children: <Widget>[_videoView(views[0])],
  //           ));
  //     case 2:
  //       return Container(
  //           child: Column(
  //             children: <Widget>[
  //               _expandedVideoRow([views[0]]),
  //               _expandedVideoRow([views[1]])
  //             ],
  //           ));
  //     case 3:
  //       return Container(
  //           child: Column(
  //             children: <Widget>[
  //               _expandedVideoRow(views.sublist(0, 2)),
  //               _expandedVideoRow(views.sublist(2, 3))
  //             ],
  //           ));
  //
  //     case 7:
  //       return Container(
  //         child: Column(
  //           children: <Widget>[
  //             _expandedVideoRow(views.sublist(0, 2)),
  //             _expandedVideoRow(views.sublist(2, 4)),
  //             _expandedVideoRow(views.sublist(4, 6)),
  //             _expandedVideoRow(views.sublist(6, 7))
  //           ],
  //         ),
  //       );
  //     case 8:
  //       return Container(
  //         child: Column(
  //           children: <Widget>[
  //             _expandedVideoRow(views.sublist(0, 2)),
  //             _expandedVideoRow(views.sublist(2, 4)),
  //             _expandedVideoRow(views.sublist(4, 6)),
  //             _expandedVideoRow(views.sublist(6, 8))
  //           ],
  //         ),
  //       );
  //     case 9:
  //       return Container(
  //         child: Column(
  //           children: <Widget>[
  //             _expandedVideoRow(views.sublist(0, 2)),
  //             _expandedVideoRow(views.sublist(2, 4)),
  //             _expandedVideoRow(views.sublist(4, 6)),
  //             _expandedVideoRow(views.sublist(6, 8)),
  //             _expandedVideoRow(views.sublist(8, 9))
  //           ],
  //         ),
  //       );
  //
  //     default:
  //   }
  //   return Container();
  // }

  Widget viewBlackContainer() {
    return Expanded(
      child: Container(
        color: Colors.black,
      ),
    );
  }

  /// Video layout wrapper

  /// Toolbar layout
  Widget _toolbar() {
    print("users length is ${_users.length}");
    // if (widget.role == ClientRoleType.clientRoleAudience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: RawMaterialButton(
              onPressed: () {
                _onToggleMute();
              },
              child: Icon(
                muted ? Icons.mic_off : Icons.mic,
                color: muted ? Colors.white : Colors.blueAccent,
                size: 20.0,
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
                size: 35.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(15.0),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: _onSwitchCamera,
              child: Icon(
                Icons.switch_camera,
                color: Colors.blueAccent,
                size: 20.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: toggleLocalVideo,
              child: Icon(
                userVideoStates[0] == true
                    ? Icons.videocam_off
                    : Icons.videocam,
                color: userVideoStates[0] == true
                    ? Colors.red
                    : Colors.blueAccent,
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
                size: 25.0,
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
        await  enablePip();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Agora Flutter'),
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: PageView(
                  padEnds: false,
                  reverse: false,
                  physics: BouncingScrollPhysics(),
                  onPageChanged: (value) {
                    setState(() {
                      currentPageIndex = value;
                    });
                    pageController.animateToPage(
                      value,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_selectedUserId != null)
                      Positioned.fill(
                        child: GestureDetector(
                          onDoubleTap: () {
                            setState(() {
                              _selectedUserId =
                              null; // Reset the selected view on double-tap
                            });
                          },
                          child: Stack(
                            children: [
                              // Background: Fullscreen video for the selected user
                              Center(
                                child: AgoraVideoView(
                                  controller: _selectedUserId == 0
                                      ? VideoViewController(
                                    rtcEngine: _engine,
                                    canvas: VideoCanvas(uid: 0),
                                  )
                                      : VideoViewController.remote(
                                    rtcEngine: _engine,
                                    canvas:
                                    VideoCanvas(uid: _selectedUserId!),
                                    connection: RtcConnection(
                                        channelId: "videoCalling"),
                                  ),
                                ),
                              ),

                              // Local view: Small video window positioned in the top-left corner
                              Positioned(
                                top: 16, // Adjust for padding
                                left: 16, // Adjust for padding
                                child: GestureDetector(
                                    onDoubleTap: () {
                                      setState(() {
                                        _selectedUserId =
                                        0; // Switch to local user view on tap
                                      });
                                    },
                                    child: _selectedUserId == 0
                                        ? SizedBox.shrink()
                                        : Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        borderRadius:
                                        BorderRadius.circular(8),
                                        color: Colors.black,
                                      ),
                                      child: AgoraVideoView(
                                        controller: VideoViewController(
                                          rtcEngine: _engine,
                                          canvas: VideoCanvas(uid: 0),
                                        ),
                                      ),
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _viewRows(),
                    _viewSecondRows(),

                    // _viewRows(),
                    // viewRowsFirstPage(),
                  ],
                  controller: pageController,
                ),
              ),
              // _viewRows(),
              // _panel(),
              _toolbar(),
              _users.length >= 6
                  ? Positioned(
                top: MediaQuery.of(context).size.height /
                    1.55, // Adjust this value to position the PageView indicator
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                          (index) {
                        return GestureDetector(
                          onTap: () {
                            pageController.animateToPage(
                              index,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            print("select index is ${index}");
                          },
                          child: Container(
                            margin: EdgeInsets.all(5),
                            height: 10.h,
                            width: 10.w,
                            decoration: BoxDecoration(
                              color: currentPageIndex == index
                                  ? Colors.blue
                                  : AppColor.greyTealColor,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
                  : SizedBox.shrink(),
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

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

