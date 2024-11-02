import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/secret_keyboard/highlighted_button.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboard.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboards.dart';
import 'package:flutter/material.dart';

openSecretInput(
    {required context,
    required controller,
    done,
    String? fieldName,
    bool obscureText = false,
    bool isSingleLine = false}) {
  showDialog(
      context: context,
      builder: (BuildContext context) => Dialog.fullscreen(
            child: SecretInput(
              originalText: controller.text,
              fieldName: fieldName,
              obscureText: obscureText,
              isSingleLine: isSingleLine,
            ),
          )).then((value) {
    if (value?.text.isNotEmpty ?? false) {
      controller.text = value.text;
    }
    if (done != null && (value?.done != null && value?.done)) {
      done(value);
    }
  });
}

class SecretInput extends StatefulWidget {
  const SecretInput(
      {super.key,
      this.originalText,
      this.obscureText = false,
      this.isSingleLine = false,
      this.fieldName});

  final String? fieldName;
  final String? originalText;
  final bool obscureText;
  final bool isSingleLine;

  @override
  SecretInputState createState() => SecretInputState();
}

class SecretInputState extends State<SecretInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final TextEditingController _textController = TextEditingController();

  List<String> availableKeyboards = Keyboards.availableKeyboards;
  bool isShifted = false;
  bool isSpecial = false;
  bool shouldObscureText = false;

  String activeLanguage = 'English';
  Keyboard activeKeyboard = Keyboards.getKeyboard();

  int? selectionStart;
  int? selectionEnd;

  @override
  void initState() {
    super.initState();
    if (widget.obscureText) {
      shouldObscureText = true;
    }
    if (widget.originalText != null) {
      _textController.text = widget.originalText!;
    }
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _textController.addListener(() {
      if (_textController.selection.start != _textController.selection.end) {
        selectionStart = _textController.selection.start;
        selectionEnd = _textController.selection.end;
      } else {
        selectionStart = null;
        selectionEnd = null;
      }
    });
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
      width: useDefualtSizes || isSpecial
          ? Keyboard.defaultWidth
          : activeKeyboard.keyWidth,
      height: useDefualtSizes || isSpecial
          ? Keyboard.defaultHeight
          : activeKeyboard.keyHeight,
      margin: margins,
      child: HighlightedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.zero,
          padding: paddings,
        ),
        onPressed: () {
          setState(() {
            _textController.text += key;
          });
        },
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
            child: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: const Color.fromRGBO(0, 0, 0, 1).withOpacity(0.55),
              child: Column(
                children: [
                  if (widget.fieldName != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: Text(widget.fieldName!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(
                          top: 10, left: 15, right: 15, bottom: 300),
                      child: TextField(
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            fillColor: Colors.transparent),
                        textAlignVertical: TextAlignVertical.center,
                        controller: _textController,
                        keyboardType: TextInputType.none,
                        obscureText: shouldObscureText ? true : false,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 24),
                        autofocus: true,
                        showCursor: true,
                        cursorColor: Colors.white,
                        cursorHeight: 24,
                        cursorWidth: 3,
                        enableInteractiveSelection: true,
                        expands: widget.isSingleLine ? false : true,
                        minLines: widget.isSingleLine ? 1 : null,
                        maxLines: widget.isSingleLine ? 1 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
                height: 300,
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
                          for (var key in Keyboard.firstRow)
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
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              margin: EdgeInsets.only(
                                  left: Keyboard.defaultMargins.left,
                                  right: Keyboard.defaultMargins.right),
                              child: HighlightedButton(
                                isActive: isShifted,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.only(
                                      top: 2, bottom: 2, left: 5, right: 5),
                                  fixedSize: const Size(50, 40),
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
                                  Icons.arrow_circle_up,
                                  color: Color.fromRGBO(255, 255, 255, 1),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                  left: Keyboard.defaultMargins.left,
                                  right: Keyboard.defaultMargins.right),
                              child: HighlightedButton(
                                isActive: isSpecial,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  fixedSize: const Size(50, 40),
                                  padding: const EdgeInsets.only(
                                      top: 2, bottom: 2, left: 5, right: 5),
                                ),
                                onPressed: () {
                                  setState(() {
                                    isSpecial = !isSpecial;
                                    activeKeyboard = Keyboards.getKeyboard(
                                        language: activeLanguage,
                                        isShifted: isShifted,
                                        isSpecial: isSpecial);
                                  });
                                },
                                child: const Text('#?&!',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _keyboardButton('.', useDefualtSizes: true),
                            _keyboardButton(',', useDefualtSizes: true),
                            _keyboardButton('@', useDefualtSizes: true),
                            _keyboardButton('?', useDefualtSizes: true),
                            Container(
                              height: Keyboard.defaultHeight,
                              margin: EdgeInsets.only(
                                  top: Keyboard.defaultMargins.top,
                                  bottom: Keyboard.defaultMargins.bottom,
                                  left: Keyboard.defaultMargins.left,
                                  right: Keyboard.defaultMargins.right),
                              child: HighlightedButton(
                                  backgroundColor: Colors.red[300],
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.only(
                                        top: 2, bottom: 2, left: 13, right: 15),
                                  ),
                                  onPressed: () {
                                    if (selectionStart != null &&
                                        selectionEnd != null) {
                                      setState(() {
                                        _textController.text = _textController
                                                .text
                                                .substring(0, selectionStart!) +
                                            _textController.text
                                                .substring(selectionEnd!);
                                      });
                                    } else {
                                      setState(() {
                                        _textController.text =
                                            _textController.text.substring(
                                                0,
                                                _textController.text.length -
                                                    1);
                                      });
                                    }
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      Future.doWhile(() async {
                                        await Future.delayed(
                                            const Duration(milliseconds: 100));
                                        setState(() {
                                          _textController.text =
                                              _textController.text.substring(
                                                  0,
                                                  _textController.text.length -
                                                      1);
                                        });
                                        return _textController.text.isNotEmpty;
                                      });
                                    });
                                  },
                                  child: const Icon(Icons.backspace,
                                      color: Colors.white)),
                            ),
                            if (!widget.isSingleLine)
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
                                          top: 2,
                                          bottom: 2,
                                          left: 13,
                                          right: 15),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _textController.text += "\n";
                                      });
                                    },
                                    child: const Icon(
                                        Icons.subdirectory_arrow_left,
                                        color: Colors.white)),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop((
                                    text: _textController.text,
                                    done: false,
                                  ));
                                },
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 35,
                                )),
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
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    shouldObscureText = !shouldObscureText;
                                  });
                                },
                                icon: Icon(
                                  shouldObscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white,
                                  size: 25,
                                )),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 5, top: 2, bottom: 2, right: 5),
                          width: 150,
                          child: HighlightedButton(
                            onPressed: () {
                              setState(() {
                                _textController.text += ' ';
                              });
                            },
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
                            backgroundColor: Colors.lightGreen,
                            onPressed: () {
                              Navigator.of(context).pop((
                                text: _textController.text,
                                done: true,
                              ));
                            },
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
