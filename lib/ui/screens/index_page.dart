import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_structure/router/app_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'calling_page.dart';

@RoutePage()
class IndexPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IndexState();
}

class IndexState extends State<IndexPage> {
  /// create a channelController to retrieve text value
  final _channelController = TextEditingController();


  /// if channel textField is validated to have error
  bool _validateError = false;

  ClientRoleType? _role = ClientRoleType.clientRoleBroadcaster;

  @override
  void dispose() {
    // dispose input controller
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agora Flutter'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          height: 400,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _channelController,
                      decoration: InputDecoration(
                        errorText:
                        _validateError ? 'Channel name is mandatory' : null,
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(width: 1),
                        ),
                        hintText: 'Channel name',
                      ),
                    ),
                  )
                ],
              ),
              Column(
                children: [
                  ListTile(
                    title: Text(
                        ClientRoleType.clientRoleBroadcaster.toString()),
                    leading: Radio(
                      value: ClientRoleType.clientRoleBroadcaster,
                      groupValue: _role,
                      onChanged: (ClientRoleType? value) {
                        setState(() {
                          _role = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onJoin,
                        child: Text('Join group call'),
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all(Colors.blueAccent),
                            foregroundColor:
                            MaterialStateProperty.all(Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          appRouter.push(VideoCallingRoute());
                        },
                        child: Text('Join one to one'),
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all(Colors.blueAccent),
                            foregroundColor:
                            MaterialStateProperty.all(Colors.white)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    setState(() {
      _validateError = _channelController.text.isEmpty;
    });

    if (!_validateError) {
      int permissionRequestCount = 0;
      bool permissionsGranted = false;

      // Loop to request permissions up to two times
      while (permissionRequestCount < 2 && !permissionsGranted) {
        var statusOfCamera = await _handleCameraAndMic(Permission.camera);
        var statusOfMicrophone = await _handleCameraAndMic(
            Permission.microphone);

        if (statusOfCamera.isGranted && statusOfMicrophone.isGranted) {
          permissionsGranted = true;
        } else {
          permissionRequestCount++;
          if (statusOfCamera.isPermanentlyDenied ||
              statusOfMicrophone.isPermanentlyDenied) {
            // Redirect to app settings if either permission is permanently denied
            await openAppSettings();
            return; // Exit the function until the user changes permissions
          }
        }
      }

      // Check if permissions were granted after maximum attempts
      if (permissionsGranted) {
        // Push video page if permissions are granted
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CallPage(
                  channelName: "videoCalling",
                  role: _role,
                ),
          ),
        );
      } else {
        // Show dialog if permissions are not granted after two attempts
        _showPermissionRequiredDialog();
      }
    }
  }

  Future<PermissionStatus> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print('Permission status for $permission: $status');
    return status;
  }

  void _showPermissionRequiredDialog(){
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Permissions Required'),
            content: Text(
              'Camera and microphone permissions are required to join the call. '
                  'Please enable them in the app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

// Future<void> onJoin() async {
//   // update input validation
//   setState(() {
//     _channelController.text.isEmpty
//         ? _validateError = true
//         : _validateError = false;
//   });
//   if (_channelController.text.isNotEmpty) {
//
//     // await for camera and mic permissions before pushing video page
//     var statusOfCamera=await _handleCameraAndMic(Permission.camera);
//     var statusOfMicrophone= await _handleCameraAndMic(Permission.microphone);
//     if(statusOfCamera.isDenied && statusOfMicrophone.isDenied){
//       openAppSettings();
//
//     }
//     else if(statusOfCamera.isGranted && statusOfMicrophone.isGranted){
//       // push video page with given channel name
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => CallPage(
//             channelName: "videoCalling",
//             role: _role,
//           ),
//         ),
//       );
//     }
//     else if(statusOfCamera.isPermanentlyDenied && statusOfMicrophone.isPermanentlyDenied){
//       statusOfCamera=await _handleCameraAndMic(Permission.camera);
//       statusOfMicrophone= await _handleCameraAndMic(Permission.microphone);
//       setState(() {
//
//       });
//     }
//   }
// }

// Future<PermissionStatus> _handleCameraAndMic(Permission permission) async {
//   final status = await permission.request();
//   print(status);
//   return status;
// }


}