import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboard.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboards.dart';
import 'package:flutter/material.dart';

class SecretInput extends StatefulWidget {
  const SecretInput({super.key, this.originalText});

  final String? originalText;

  @override
  SecretInputState createState() => SecretInputState();
}

class SecretInputState extends State<SecretInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  List<String> keyboards = Keyboards.availableKeyboards;
  bool isShifted = false;
  bool isSpecial = false;

  String activeLanguage = 'English';
  Keyboard activeKeyboard = Keyboards.getKeyboard();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _keyboardButton(key) {
    return SizedBox(
      width: 34,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding:
                const EdgeInsets.only(top: 2, bottom: 2, left: 3, right: 3),
            backgroundColor: primaryColor,
            elevation: 0,
            side: const BorderSide(color: Colors.white),
            shadowColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)))),
        onPressed: () {},
        child: Text(key,
            style: const TextStyle(color: Colors.white, fontSize: 20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();

    return FadeTransition(
        opacity: _animation,
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              height: MediaQuery.of(context).size.height - 280,
              width: MediaQuery.of(context).size.width,
              color: Colors.black.withOpacity(0.5),
              child: SelectableText(widget.originalText ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
            Container(
                height: 280,
                padding: const EdgeInsets.only(top: 5),
                width: MediaQuery.of(context).size.width,
                color: primaryColor,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var key in activeKeyboard.firstRowKeys)
                            _keyboardButton(key)
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var key in activeKeyboard.secondRowKeys)
                            _keyboardButton(key)
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var key in activeKeyboard.thirdRowKeys)
                            _keyboardButton(key)
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var key in activeKeyboard.fourthRowKeys)
                            _keyboardButton(key)
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.only(
                                      top: 2, bottom: 2, left: 5, right: 5),
                                  backgroundColor: primaryColor,
                                  elevation: 0,
                                  side: const BorderSide(color: Colors.white),
                                  shadowColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(5)))),
                              onPressed: () {
                                setState(() {
                                  isShifted = !isShifted;
                                  activeKeyboard = Keyboards.getKeyboard(
                                      language: activeLanguage,
                                      isShifted: isShifted,
                                      isSpecial: isSpecial);
                                });
                              },
                              child: const Icon(
                                Icons.arrow_right_alt,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.language,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 5, top: 2, bottom: 2, right: 5),
                          width: 150,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                elevation: 0,
                                side: const BorderSide(color: Colors.white),
                                shadowColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)))),
                            onPressed: () {},
                            child: const Icon(
                              Icons.space_bar,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 5, top: 2, bottom: 2, right: 5),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                elevation: 0,
                                side: const BorderSide(color: Colors.white),
                                shadowColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)))),
                            onPressed: () {},
                            child: const Icon(
                              Icons.done,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ))
          ],
        )));
  }
}
