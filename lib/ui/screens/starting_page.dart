// import 'package:auto_route/annotations.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_demo_structure/router/app_router.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// @RoutePage()
// class StartingPage extends StatefulWidget {
//   @override
//   _StartingPageState createState() => _StartingPageState();
// }
//
// class _StartingPageState extends State<StartingPage> {
//   final myController = TextEditingController();
//   bool _validateError = false;
//
//   @override
//   void dispose() {
//     myController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text('Agora Group Video Calling'),
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 Padding(padding: EdgeInsets.only(top: 20)),
//                 Text(
//                   'Agora Group Video Call Demo',
//                   style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 Padding(padding: EdgeInsets.symmetric(vertical: 20)),
//                 Container(
//                   width: MediaQuery.of(context).size.width * 0.8,
//                   child: TextFormField(
//                     controller: myController,
//                     decoration: InputDecoration(
//                       labelText: 'Channel Name',
//                       labelStyle: TextStyle(color: Colors.blue),
//                       hintText: 'Enter channel name',
//                       hintStyle: TextStyle(color: Colors.black45),
//                       errorText:
//                       _validateError ? 'Channel name is mandatory' : null,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(padding: EdgeInsets.symmetric(vertical: 30)),
//                 Container(
//                   width: MediaQuery.of(context).size.width * 0.25,
//                   child: MaterialButton(
//                     onPressed: onJoin,
//                     height: 40,
//                     color: Colors.blueAccent,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         Text(
//                           'Join',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                         Icon(
//                           Icons.arrow_forward,
//                           color: Colors.white,
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> onJoin() async {
//     setState(() {
//       myController.text.isEmpty ? _validateError = true : _validateError = false;
//     });
//     if (myController.text.isNotEmpty) {
//       await [Permission.microphone, Permission.camera].request();
//       appRouter.push(CustomVideoCallRoute());
//     }
//   }
// }
