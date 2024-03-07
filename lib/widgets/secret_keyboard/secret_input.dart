import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/secret_keyboard/highlighted_button.dart';
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

  List<String> availableKeyboards = Keyboards.availableKeyboards;
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

  Widget _keyboardButton(key, {useDefualtSizes = false}) {
    final EdgeInsets paddings = useDefualtSizes
        ? EdgeInsets.only(
            top: Keyboard.defaultPaddings.top,
            bottom: Keyboard.defaultPaddings.bottom,
            left: Keyboard.defaultPaddings.left,
            right: Keyboard.defaultPaddings.right)
        : EdgeInsets.only(
            top: activeKeyboard.keyPaddings.top,
            bottom: activeKeyboard.keyPaddings.bottom,
            left: activeKeyboard.keyPaddings.left,
            right: activeKeyboard.keyPaddings.right);
    final EdgeInsets margins = useDefualtSizes
        ? EdgeInsets.only(
            top: Keyboard.defaultMargins.top,
            bottom: Keyboard.defaultMargins.bottom,
            left: Keyboard.defaultMargins.left,
            right: Keyboard.defaultMargins.right)
        : EdgeInsets.only(
            top: activeKeyboard.keyMargins.top,
            bottom: activeKeyboard.keyMargins.bottom,
            left: activeKeyboard.keyMargins.left,
            right: activeKeyboard.keyMargins.right);
    return Container(
      width: useDefualtSizes ? Keyboard.defaultWidth : activeKeyboard.keyWidth,
      height:
          useDefualtSizes ? Keyboard.defaultHeight : activeKeyboard.keyHeight,
      margin: margins,
      child: HighlightedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.zero,
          padding: paddings,
        ),
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
              height: MediaQuery.of(context).size.height - 270 - 93,
              width: MediaQuery.of(context).size.width,
              color: Colors.black.withOpacity(0.5),
              child: SelectableText(widget.originalText ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
            Container(
                height: 270,
                padding: const EdgeInsets.only(top: 5),
                width: MediaQuery.of(context).size.width,
                color: primaryColor,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var key in activeKeyboard.firstRowKeys)
                            _keyboardButton(key, useDefualtSizes: true)
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var key in activeKeyboard.secondRowKeys)
                            _keyboardButton(key)
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var key in activeKeyboard.thirdRowKeys)
                            _keyboardButton(key)
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var key in activeKeyboard.fourthRowKeys)
                            _keyboardButton(key),
                          Container(
                            height: Keyboard.defaultHeight,
                            margin: EdgeInsets.only(
                                top: Keyboard.defaultMargins.top,
                                bottom: Keyboard.defaultMargins.bottom,
                                left: Keyboard.defaultMargins.left,
                                right: Keyboard.defaultMargins.right),
                            child: HighlightedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.only(
                                      top: 2, bottom: 2, left: 13, right: 15),
                                ),
                                onPressed: () {},
                                child: const Icon(Icons.backspace,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            HighlightedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.only(
                                    top: 2, bottom: 2, left: 5, right: 5),
                              ),
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
                                color: Color.fromRGBO(255, 255, 255, 1),
                              ),
                            ),
                            DropdownButton(
                                iconSize: 0.0,
                                dropdownColor: secondaryColor,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                value: activeLanguage,
                                items: availableKeyboards
                                    .map((e) => DropdownMenuItem<String>(
                                          alignment:
                                              AlignmentDirectional.center,
                                          value: e,
                                          child:
                                              Text(Keyboards.abbreviations[e]!),
                                        ))
                                    .toList(),
                                onChanged: (object) {
                                  setState(() {
                                    activeLanguage = object!;
                                    activeKeyboard = Keyboards.getKeyboard(
                                        language: activeLanguage,
                                        isShifted: isShifted,
                                        isSpecial: isSpecial);
                                  });
                                }),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 5, top: 2, bottom: 2, right: 5),
                          width: 150,
                          child: HighlightedButton(
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
                          child: HighlightedButton(
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
