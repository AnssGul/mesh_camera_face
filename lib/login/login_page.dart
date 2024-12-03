import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../camera/camera.dart';

class LoginPage extends StatelessWidget {
  final List<CameraDescription> cameras;
  const LoginPage({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(cameras: cameras),
              ),
            );
          },
          child: const Text('Go to Camera Screen'),
        ),
      ),
    );
  }
}
