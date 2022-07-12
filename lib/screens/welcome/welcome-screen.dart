import 'package:flutter/material.dart';

import '../../ui_constants.dart';
import '../mainpage.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Spacer(flex: 2),
          Image.asset("assets/images/welcome_image.png"),
          Spacer(flex: 3),
          Text(
            "Welcome to our freedom \nMessaging App",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headline5
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Text(
            "Freedom talk any person of your \nmother language",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.color
                    ?.withOpacity(0.64)),
          ),
          const Spacer(flex: 3),
          FittedBox(
            child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainWidget(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      "Skip",
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.color
                              ?.withOpacity(0.8)),
                    ),
                    SizedBox(width: defaultPadding / 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context)
                            .textTheme
                            .bodyText1
                            ?.color
                            ?.withOpacity(0.8))
                  ],
                )),
          )
        ],
      )),
    );
  }
}
