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
import 'package:mobx/mobx.dart';
import '../auth/store/auth_store.dart';

const String appID = '2ac013422f444292914c234d228b87bb'; // Your Agora App ID
const String token =
    "007eJxTYLj9Wkd9wp+cB5/TDhosv290tKdo9n9LmZh+Xp5333p0ZSsVGIwSkw0MjU2MjNJMTEyMLI0sDU2SjYxNUoyMLJIszJOSNgslpjcEMjK85e5jZGSAQBCfh6EsMyU13zkxJyczL52BAQCl1CKm"; // Your Agora Token

@RoutePage()
class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;

  String? name;

  /// non-modifiable client role of the page
  final ClientRoleType role;

  /// Creates a call page with given channel name.
  CallPage({Key? key, required this.channelName, this.name, required this.role})
      : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  final Floating floating = Floating();
  late final PageController pageController;

  @override
  void dispose() {
    // clear users
    authStore.users.clear();
    _dispose();
    pageController.dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    // destroy sdk
    await authStore.engine.leaveChannel();
    await authStore.engine.release();
  }

  @override
  void initState() {
    super.initState();
    authStore.initialize(
        appId: appID,
        channelName: widget.channelName,
        role: widget.role,
        token: token);
    // initialize agora sdk
    WidgetsBinding.instance.addObserver(this);
    authStore.startMonitoring();
    pageController = PageController(
      initialPage: 0,
    );
  }

  List<Widget> _getRenderViewsForPageOne() {
    final List<Widget> list = [];
    // Add local user view
    list.add(
      Observer(builder: (context) {
        return GestureDetector(
          onDoubleTap: () {
            authStore.selectUser(0); // Select local user
            print("your id id :${authStore.userVideoStates[0]}");
          },
          child: (authStore.userVideoStates[0] ?? false)
              ? Observer(builder: (context) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child:
                          Icon(Icons.person, color: Colors.white, size: 50.0),
                    ),
                  );
                })
              : AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: authStore.engine,
                    canvas: VideoCanvas(uid: 0), // Local user's video canvas
            ),
          ),
        );
      }),
    );
    // Add remote user views
    for (var uid in authStore.users.take(min(authStore.users.length, 5))) {
      list.add(
        Observer(builder: (context) {
          return GestureDetector(
            onDoubleTap: () {
              authStore.selectUser(uid); // Select remote user
            },
            child: (authStore.userVideoStates[uid] ?? false)
                ? Container(
                    color: Colors.black,
                    child: Center(
                      child:
                          Icon(Icons.person, color: Colors.white, size: 50.0),
                    ),
                  )
                : AgoraVideoView(
                    key: Key(uid.toString()), // Unique key for each remote view
                    controller: VideoViewController.remote(
                      rtcEngine: authStore.engine,
                      canvas:
                          VideoCanvas(uid: uid), // Remote user's video canvas
                      connection: RtcConnection(channelId: "videoCalling"),
                    ),
                  ),
          );
        }),
      );
    }

    return list;
  }

  List<Widget> _getRenderViewsForPageTwo() {
    final List<Widget> list = [];
    // Remote views for each user in _users list
    if (authStore.users.length > 5)
      authStore.users.sublist(5, authStore.users.length).forEach((int uid) {
        list.add(Observer(
          builder: (_) {
            return GestureDetector(
              onDoubleTap: () {
                authStore.setSelectedUserId(uid);
                print(
                    "your id id :${authStore.userVideoStates[uid]}"); // Select remote user using MobX action
              },
              child: (authStore.userVideoStates[uid] ??
                      false) // Check if remote video is muted
                  ? Container(
                      color: Colors.black,
                      child: Center(
                        child:
                            Icon(Icons.person, color: Colors.white, size: 50.0),
                      ),
                    )
                  : Container(
                      color: AppColor.green,
                      child: AgoraVideoView(
                        key: Key(
                            uid.toString()), // Unique key for each remote view
                        controller: VideoViewController.remote(
                          rtcEngine: authStore.engine,
                          canvas: VideoCanvas(
                              uid: uid), // Remote user's video canvas
                          connection: RtcConnection(channelId: "videoCalling"),
                        ),
                      ),
                    ),
            );
          },
        ));
      });

    return list;
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

  Widget _viewRows() {
    final views = _getRenderViewsForPageOne();
    switch (views.length) {
      case 1:
        return Container(
          child: Column(
            children: <Widget>[_videoView(views[0])],
          ),
        );
      case 2:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoRow([views[0]]),
              _expandedVideoRow([views[1]]),
            ],
          ),
        );
      case 3:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 3)),
            ],
          ),
        );
      case 4:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 4)),
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
        return Container();
    }
  }

  Widget _viewSecondRows() {
    final views = _getRenderViewsForPageTwo();

    // Ensure 6 slots with placeholders for missing views
    final paddedViews = List.generate(
      6,
      (index) => index < views.length
          ? _videoView(views[index])
          : Container(color: Colors.black), // Placeholder
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
    // if (widget.role == ClientRoleType.clientRoleAudience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Observer(builder: (context) {
            return Flexible(
              child: RawMaterialButton(
                onPressed: () {
                  authStore.muteAudio();
                },
                child: Icon(
                  authStore.isMuted ? Icons.mic_off : Icons.mic,
                  color: authStore.isMuted ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: authStore.isMuted ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
            );
          }),
          Observer(builder: (context) {
            return Flexible(
              child: RawMaterialButton(
                onPressed: () {
                  authStore.onCallEnd(context);
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
            );
          }),
          Observer(builder: (context) {
            return Flexible(
              child: RawMaterialButton(
                onPressed: authStore.onSwitchCamera,
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
            );
          }),
          Observer(builder: (context) {
            return Flexible(
              child: RawMaterialButton(
                onPressed: authStore.toggleLocalVideo,
                child: Icon(
                  authStore.userVideoStates[0] == true
                      ? Icons.videocam_off
                      : Icons.videocam,
                  color: authStore.userVideoStates[0] == true
                      ? Colors.red
                      : Colors.blueAccent,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
            );
          }),
          Observer(builder: (context) {
            return Flexible(
              child: RawMaterialButton(
                onPressed: () {
                  authStore.onSpeakerButton();
                },
                child: Icon(
                  authStore.onSpeaker ? Icons.volume_up : Icons.volume_off,
                  color: Colors.blueAccent,
                  size: 25.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
            );
          }),
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
      child: Scaffold(
        appBar: AppBar(
          title: Text('Agora Flutter'),
        ),
        backgroundColor: Colors.black,
        body: Observer(
          builder: (context) {
            return Center(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: PageView(
                      padEnds: false,
                      reverse: false,
                      physics: BouncingScrollPhysics(),
                      onPageChanged: (value) {
                        authStore.setCurrentPageIndex(value);
                        pageController.animateToPage(
                          value,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      children: [
                        // if (authStore.selectedUserId != null)
                        //   Positioned.fill(
                        //     child: GestureDetector(
                        //       onDoubleTap: () {
                        //           authStore.selectedUserId = null; // Reset the selected view on double-tap
                        //       },
                        //       child: Stack(
                        //         children: [
                        //           // Background: Fullscreen video for the selected user
                        //           Center(
                        //             child: AgoraVideoView(
                        //               controller: authStore.selectedUserId == 0
                        //                   ? VideoViewController(
                        //                 rtcEngine: authStore.engine,
                        //                 canvas: VideoCanvas(uid: 0),
                        //               )
                        //                   : VideoViewController.remote(
                        //                 rtcEngine: authStore.engine,
                        //                 canvas:
                        //                 VideoCanvas(uid: authStore.selectedUserId!),
                        //                 connection: RtcConnection(
                        //                     channelId: "videoCalling"),
                        //               ),
                        //             ),
                        //           ),
                        //           // Local view: Small video window positioned in the top-left corner
                        //           Positioned(
                        //             top: 16, // Adjust for padding
                        //             left: 16, // Adjust for padding
                        //             child: GestureDetector(
                        //                 onDoubleTap: () {
                        //
                        //                     authStore.selectedUserId =
                        //                     0; // Switch to local user view on tap
                        //                 },
                        //                 child: authStore.selectedUserId == 0
                        //                     ? SizedBox.shrink()
                        //                     : Container(
                        //                   width: 200,
                        //                   height: 200,
                        //                   decoration: BoxDecoration(
                        //                     border: Border.all(
                        //                         color: Colors.white, width: 2),
                        //                     borderRadius:
                        //                     BorderRadius.circular(8),
                        //                     color: Colors.black,
                        //                   ),
                        //                   child: AgoraVideoView(
                        //                     controller: VideoViewController(
                        //                       rtcEngine: authStore.engine,
                        //                       canvas: VideoCanvas(uid: 0),
                        //                     ),
                        //                   ),
                        //                 )),
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //   ),
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
                  authStore.users.length >= 6
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
                                  color: authStore.currentPageIndex == index
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
            );
          }
        ),

      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
