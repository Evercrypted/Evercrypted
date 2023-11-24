import 'package:flutter/material.dart';

import 'main/main_screen.dart';

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  MainWidgetState createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
