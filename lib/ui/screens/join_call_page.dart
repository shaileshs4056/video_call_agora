import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_structure/router/app_router.dart';
import 'package:flutter_demo_structure/values/colors.dart';

@RoutePage()
class JoinCallPage extends StatefulWidget {
  const JoinCallPage({super.key});

  @override
  State<JoinCallPage> createState() => _JoinCallPageState();
}

class _JoinCallPageState extends State<JoinCallPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Call Screen'),
      ),
      body: Center(
        child: ElevatedButton(

          onPressed: () {
            appRouter.push(VideoCallingRoute());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.green,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: TextStyle(fontSize: 18),
          ),
          child: Text('Join Call'),
        ),
      ),
    );
  }
}
