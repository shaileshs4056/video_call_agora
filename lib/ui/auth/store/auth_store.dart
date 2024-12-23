import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_structure/core/api/base_response/base_response.dart';
import 'package:flutter_demo_structure/core/exceptions/app_exceptions.dart';
import 'package:flutter_demo_structure/core/exceptions/dio_exception_util.dart';
import 'package:flutter_demo_structure/core/locator/locator.dart';
import 'package:flutter_demo_structure/data/model/request/login_request_model.dart';
import 'package:flutter_demo_structure/data/model/response/user_profile_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobx/mobx.dart';
import '../../../../data/repository_impl/auth_repo_impl.dart';
part 'auth_store.g.dart';


class AuthStore = _AuthStoreBase with _$AuthStore;
abstract class _AuthStoreBase with Store {
  late StreamSubscription<ConnectivityResult> _subscription;
  late RtcEngine _engine;
  @observable
  BaseResponse<UserData?>? loginResponse;

  @observable
  BaseResponse? logoutResponse;

  @observable
  String? errorMessage;

  // Currently selected user (for example, to focus the view)
  @observable
  int? selectedUserId = 0;

  @observable
  int? selectedRemoteUserIdForFocus = null;



  @observable
  bool isBluetoothHeadphoneConnected = false;

  @observable
  String connectedDeviceName = "None";

  // Observable for connection status
  @observable
  String networkStatus = "Connected";

  @observable
  bool isMuted = false; // Tracks microphone mute/unmute state

  @observable
  bool onSpeaker = true; // Tracks speakerphone toggle state

  @observable
  int? _streamId;
  // Observable to track the current page index
  @observable
  int currentPageIndex = 0;

  @observable
  ObservableList<Widget> list = ObservableList<Widget>();

  final GoogleSignIn googleSignIn = GoogleSignIn();

  @observable
  ObservableList<String> infoStrings = ObservableList<String>();

  // List of users (both local and remote)
  @observable
  ObservableList<int> users = ObservableList<int>();

  @observable
  ObservableMap<int, bool> userVideoStates = ObservableMap<int, bool>();

  // Getter for accessing the engine
  RtcEngine get engine => _engine;



  _AuthStoreBase();

  // Actions
  @action
  void addUser(int uid) {
    if (!users.contains(uid)) {
      users.add(uid);
    }
  }

  @action
  void removeUser(int uid) {
    users.remove(uid);
  }

  // Action to automatically update the selected user
  @action
  void updateSelectedUser() {
    if (users.isNotEmpty) {
      selectedUserId = users.first; // Default to the first user
    } else {
      selectedUserId = 0; // Default to local user
    }
  }

  @action
  void updateVideoState(int uid, bool isMuted) {
    userVideoStates[uid] = isMuted;
  }

  @action
  void selectUser(int uid) {
    selectedUserId = uid;
  }

  @action
  void setPageIndex(int index) {
    currentPageIndex = index;
  }

  // Actions to update states
  @action
  void setSelectedUserId(int? uid) {
    selectedUserId = uid;
  }

  // Actions to update states
  @action
  void setSelectedRemoteUserIdForFocus(int? uid) {
    selectedRemoteUserIdForFocus = uid;
  }

  @action
  Future<void> initialize({
    required String appId,
    required String channelName,
    required ClientRoleType role,
    required String token,
  }) async {
    if (appId.isEmpty) {
      infoStrings.add('APP_ID missing, please provide your APP_ID in settings.dart');
      infoStrings.add('Agora Engine is not starting');
      return;
    }

    await _initAgoraRtcEngine(appId, role);
    _addAgoraEventHandlers();

    VideoEncoderConfiguration configuration = VideoEncoderConfiguration (
      dimensions: VideoDimensions(width: 1920, height: 1080),
    );

    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: ChannelMediaOptions(),
    );
  }

  /// here starting _initAgoraRtcEngine
  @action
  Future<void> _initAgoraRtcEngine(String appId, ClientRoleType role) async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: role);
  }

  /// Add Agora event handlers
  @action
  void _addAgoraEventHandlers() {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) {
        infoStrings.add('onError: $msg');
      },
      onJoinChannelSuccess: (connection, elapsed) {
        infoStrings.add('onJoinChannel: ${connection.channelId}, uid: ${connection.localUid}');
      },
      onLeaveChannel: (connection, stats) {
        infoStrings.add('onLeaveChannel');
        users.clear();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        infoStrings.add('userJoined: $remoteUid');
        users.add(remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        infoStrings.add('userOffline: $remoteUid');
        users.remove(remoteUid);
      },
      onFirstRemoteVideoFrame: (connection, remoteUid, width, height, elapsed) {
        infoStrings.add('firstRemoteVideo: $remoteUid ${width}x$height');
      },
      onUserMuteVideo: (connection, remoteUid, muted) {
        userVideoStates[remoteUid] = muted;
      },
      onStreamMessage: (connection, remoteUid, streamId, data, length, sentTs) {
        try {
          String message = String.fromCharCodes(data);
          final decodedMessage = jsonDecode(message);

          if (decodedMessage["uid"] != null && decodedMessage["videoMuted"] != null) {
            userVideoStates[decodedMessage["uid"]] = decodedMessage["videoMuted"];
          }
        } catch (e) {
          print("Error handling stream message: $e");
        }
      },
      onStreamMessageError: (connection, remoteUid, streamId, error, missed, cached) {
        print("Stream message error: $error");
      },
    ));
  }

  /// mute audio action
  @action
  void muteAudio(){
    isMuted = !isMuted;
    engine.muteLocalAudioStream(isMuted);
  }

  /// End call action
  @action
  Future<void> onCallEnd(BuildContext context) async {
    try {
      print("Ending call...");



      // Leave the Agora channel
      await engine.leaveChannel();
      print("Left channel successfully.");

      // Release Agora engine
      await engine.release();
      print("Agora engine released.");

      // Stop any ongoing monitoring or observers
      authStore.stopMonitoring();

      // Navigate back to the previous screen
      Navigator.pop(context);
      print("Call ended and navigated back.");
      // Reset state
      selectedUserId = null;
      currentPageIndex = 0;
      isMuted = false; // Reset mute state
      userVideoStates[0] = false; // Reset video state
      onSpeaker = true; // Reset speaker state
    } catch (e) {
      print('Error ending call: $e');
    }
  }



  ///start a call
  @action
  Future<void> startCall() async {
    try {
      print("Starting call...");

      // Default: Unmute audio
      isMuted = false;
      await engine.muteLocalAudioStream(isMuted);

      // Default: Enable video
      userVideoStates[0] = false; // Video is not muted initially
      await engine.muteLocalVideoStream(userVideoStates[0]!);

      // Default: Enable speaker
      onSpeaker = true;
      await engine.setEnableSpeakerphone(onSpeaker);

      print("Call settings initialized: Audio unmuted, video enabled, speaker enabled.");
    } catch (e) {
      print("Error during startCall: $e");
    }
  }



  /// switch camera
  void onSwitchCamera(){
    engine.switchCamera();
  }

  ///toggle video
  @action
  void toggleLocalVideo() {
      userVideoStates[0] = !(userVideoStates[0] ?? false); // Toggle local video state.
      print( userVideoStates[0]);
      print("your id is");

    // Mute or unmute the local video stream
    engine.muteLocalVideoStream(userVideoStates[0] ?? false);

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

  ///current page index

  @action
  void setCurrentPageIndex(int value) {
    currentPageIndex = value;
  }
  ///on speaker change

  void onSpeakerButton() {
    // Toggle speakerphone mode
    if (onSpeaker) {
      engine.setEnableSpeakerphone(false); // Use earpiece
    } else {
      engine.setEnableSpeakerphone(true); // Use speakerphone
    }
    // Toggle the `onSpeaker` boolean to update the UI
    onSpeaker = !onSpeaker;
  }


  @action
  Future login(LoginRequestModel request) async {
    try {
      errorMessage = null;
      await Future.delayed(const Duration(seconds: 5), () {});
      loginResponse = BaseResponse(message: "Login successfully", code: "1");
    } on DioException catch (dioError) {
      errorMessage = DioExceptionUtil.handleError(dioError);
    } on AppException catch (e) {
      errorMessage = e.toString();
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      errorMessage = e.toString();
    }
  }

  @action
  void resetSelectedUser() {
    selectedUserId = null;
  }


  // Initialize connectivity monitoring
  @action
  void startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      switch (result) {
        case ConnectivityResult.none:
          updateNetworkStatus("Disconnected");
          break;
        case ConnectivityResult.mobile:
          updateNetworkStatus("Mobile Data");
          break;
        case ConnectivityResult.wifi:
          updateNetworkStatus("Wi-Fi");
          break;
        default:
          updateNetworkStatus("Unknown");
      }
    });
  }

  // Stop connectivity monitoring
  @action
  void stopMonitoring() {
    _subscription.cancel();
  }

  // Update network status
  @action
  void updateNetworkStatus(String status) {
    networkStatus = status;
  }

  @action
  Future logout() async {
    try {
      errorMessage = null;
      var commonStoreFuture = ObservableFuture<BaseResponse>(authRepo.logout());
      logoutResponse = await commonStoreFuture;
    } on DioException catch (dioError) {
      errorMessage = DioExceptionUtil.handleError(dioError);
    } on AppException catch (e) {
      errorMessage = e.toString();
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      errorMessage = e.toString();
    }
  }

}

final authStore = locator<AuthStore>();
final storage = new FlutterSecureStorage();
