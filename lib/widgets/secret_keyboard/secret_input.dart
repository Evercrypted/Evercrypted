import 'package:evercrypted/core/entities/settings/settings_service.dart';
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
  final ScrollController _scrollController = ScrollController();

  List<String> availableKeyboards = ['English']; // Start with only English
  bool isShifted = false;
  bool isSpecial = false;
  bool shouldObscureText = false;

  String activeLanguage = 'English';
  Keyboard activeKeyboard = Keyboards.getKeyboard();

  int? selectionStart;
  int? selectionEnd;

  bool isShiftLocked = false;
  DateTime? lastShiftPress;

  bool isRandomized = false;

  bool isBackspaceLongPressed = false;

  void loadAvailableKeyboards() async {
    final settings = SettingsService.getSettings();
    setState(() {
      availableKeyboards = settings != null
          ? List<String>.from(settings.availableKeyboards)
          : ['English'];
    });
  }

  @override
  void initState() {
    super.initState();
    loadAvailableKeyboards();
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
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });

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
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _keyboardButton(key,
      {useDefualtSizes = false, rowLength = 0, specialKeysRow = false}) {
    final screenWidth = MediaQuery.of(context).size.width - 2;
    final keyWidth = rowLength > 0
        ? ((screenWidth - (rowLength + 1) * 2) / rowLength)
        : (useDefualtSizes || isSpecial
            ? Keyboard.defaultWidth
            : activeKeyboard.keyWidth);

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

    // Get alternative characters for this key
    final List<String> alternatives = activeKeyboard.getAlternatives(key) ?? [];
    final GlobalKey buttonKey = GlobalKey();

    return Container(
      width: keyWidth,
      height: specialKeysRow ? 60 : 45,
      margin: specialKeysRow
          ? EdgeInsets.symmetric(horizontal: 1, vertical: 1.35)
          : EdgeInsets.all(1),
      child: GestureDetector(
        onLongPressStart: alternatives.isEmpty
            ? null
            : (details) {
                // Get the specific button's position using its key
                final RenderBox button =
                    buttonKey.currentContext!.findRenderObject() as RenderBox;
                final Offset position = button.localToGlobal(Offset.zero);

                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return Stack(
                      children: [
                        Positioned(
                          left: position.dx -
                              ((alternatives.length * 40) / 2) +
                              (keyWidth / 2), // Center horizontally
                          top: position.dy -
                              80, // Increased offset to show above the key
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800],
                            child: Container(
                              height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: alternatives
                                    .map((char) => InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              _textController.text += char;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12),
                                            alignment: Alignment.center,
                                            child: Text(
                                              char,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
        child: HighlightedButton(
          key: buttonKey, // Add the key to the button
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: paddings,
          ),
          onPressed: () {
            setState(() {
              _textController.text += key;
              if (isShifted && !isShiftLocked) {
                isShifted = false;
                activeKeyboard = Keyboards.getKeyboard(
                    language: activeLanguage,
                    activeKeyboard: activeKeyboard,
                    isShifted: false,
                    isSpecial: isSpecial);
              }
            });
          },
          child: Text(key,
              style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
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
              color: const Color.fromRGBO(0, 0, 0, 1)
                  .withAlpha((0.55 * 255).round()),
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
                      alignment: Alignment.center,
                      child: TextField(
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero),
                        textAlignVertical: TextAlignVertical.center,
                        controller: _textController,
                        keyboardType: TextInputType.none,
                        obscureText: shouldObscureText && widget.isSingleLine
                            ? true
                            : false,
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
                        onChanged: (text) {
                          _textController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length),
                          );
                        },
                        scrollController: _scrollController,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var key in activeKeyboard.firstRowKeys)
                          _keyboardButton(key,
                              useDefualtSizes: true,
                              rowLength: activeKeyboard.firstRowKeys.length,
                              specialKeysRow: isSpecial)
                      ],
                    ),
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var key in activeKeyboard.secondRowKeys)
                            _keyboardButton(key,
                                rowLength: activeKeyboard.secondRowKeys.length,
                                specialKeysRow: isSpecial)
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var key in activeKeyboard.thirdRowKeys)
                          _keyboardButton(key,
                              rowLength: activeKeyboard.thirdRowKeys.length,
                              specialKeysRow: isSpecial)
                      ],
                    ),
                    if (!isSpecial)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var key in activeKeyboard.fourthRowKeys)
                            _keyboardButton(key,
                                rowLength: activeKeyboard.fourthRowKeys.length)
                        ],
                      ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                margin: EdgeInsets.only(
                                    left: Keyboard.defaultMargins.left,
                                    right: Keyboard.defaultMargins.right * 2),
                                child: HighlightedButton(
                                  isActive: isShifted,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.only(
                                        top: 2, bottom: 2, left: 5, right: 5),
                                    fixedSize: const Size(60, 45),
                                    backgroundColor:
                                        isShiftLocked ? Colors.blue[300] : null,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      final now = DateTime.now();
                                      if (lastShiftPress != null &&
                                          now.difference(lastShiftPress!) <
                                              const Duration(
                                                  milliseconds: 300)) {
                                        isShiftLocked = !isShiftLocked;
                                        isShifted = isShiftLocked;
                                      } else {
                                        isShiftLocked = false;
                                        isShifted = !isShifted;
                                      }
                                      lastShiftPress = now;

                                      activeKeyboard = Keyboards.getKeyboard(
                                          language: activeLanguage,
                                          activeKeyboard: activeKeyboard,
                                          isShifted: isShifted,
                                          isSpecial: isSpecial);
                                    });
                                  },
                                  child: Icon(
                                    isShiftLocked
                                        ? Icons.lock
                                        : Icons.arrow_circle_up,
                                    color: Colors.white,
                                    size: 25,
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
                                    fixedSize: const Size(60, 45),
                                    padding: const EdgeInsets.only(
                                        top: 2, bottom: 2, left: 5, right: 5),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isSpecial = !isSpecial;
                                      activeKeyboard = Keyboards.getKeyboard(
                                          language: activeLanguage,
                                          activeKeyboard: activeKeyboard,
                                          isShifted: isShifted,
                                          isSpecial: isSpecial);
                                    });
                                  },
                                  child: const Text('#?&!',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20)),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _keyboardButton('.', useDefualtSizes: true),
                              _keyboardButton(',', useDefualtSizes: true),
                              _keyboardButton('?', useDefualtSizes: true),
                              Container(
                                margin: EdgeInsets.only(
                                    top: Keyboard.defaultMargins.top,
                                    bottom: Keyboard.defaultMargins.bottom,
                                    left: Keyboard.defaultMargins.left * 2,
                                    right: Keyboard.defaultMargins.right),
                                child: GestureDetector(
                                  onLongPressStart: (_) async {
                                    setState(() {
                                      isBackspaceLongPressed = true;
                                    });
                                    while (isBackspaceLongPressed &&
                                        _textController.text.isNotEmpty) {
                                      setState(() {
                                        _textController.text =
                                            _textController.text.substring(
                                                0,
                                                _textController.text.length -
                                                    1);
                                      });
                                      await Future.delayed(
                                          const Duration(milliseconds: 100));
                                    }
                                  },
                                  onLongPressEnd: (_) {
                                    setState(() {
                                      isBackspaceLongPressed = false;
                                    });
                                  },
                                  child: HighlightedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size.zero,
                                      fixedSize: const Size(60, 45),
                                      padding: const EdgeInsets.only(
                                          top: 2,
                                          bottom: 2,
                                          left: 13,
                                          right: 15),
                                    ),
                                    onPressed: () {
                                      if (selectionStart != null &&
                                          selectionEnd != null) {
                                        setState(() {
                                          _textController.text =
                                              _textController.text.substring(
                                                      0, selectionStart!) +
                                                  _textController.text
                                                      .substring(selectionEnd!);
                                        });
                                      } else {
                                        if (_textController.text.isNotEmpty) {
                                          setState(() {
                                            _textController.text =
                                                _textController.text.substring(
                                                    0,
                                                    _textController
                                                            .text.length -
                                                        1);
                                          });
                                        }
                                      }
                                    },
                                    child: const Icon(
                                      Icons.backspace,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 45,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop((
                                      text: _textController.text,
                                      done: false,
                                    ));
                                  },
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: 40,
                                  )),
                              if (availableKeyboards.length > 1)
                                DropdownButton(
                                    padding:
                                        EdgeInsets.only(left: 5, right: 10),
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
                                              child: Text(
                                                  Keyboards.abbreviations[e]!),
                                            ))
                                        .toList(),
                                    onChanged: (object) {
                                      setState(() {
                                        activeLanguage = object!;
                                        isShifted = false;
                                        isSpecial = false;
                                        isShiftLocked = false;
                                        activeKeyboard = Keyboards.getKeyboard(
                                            language: activeLanguage,
                                            isShifted: false,
                                            isSpecial: false,
                                            randomize: isRandomized);
                                      });
                                    }),
                              if (widget.isSingleLine)
                                InkWell(
                                    onTap: () {
                                      setState(() {
                                        shouldObscureText = !shouldObscureText;
                                      });
                                    },
                                    child: Icon(
                                      shouldObscureText
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                      size: 25,
                                    )),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    isRandomized = !isRandomized;
                                    activeKeyboard = Keyboards.getKeyboard(
                                        language: activeLanguage,
                                        isShifted: isShifted,
                                        isSpecial: isSpecial,
                                        randomize: isRandomized);
                                  });
                                },
                                child: Icon(
                                  isRandomized
                                      ? Icons.shuffle_on_outlined
                                      : Icons.shuffle,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.30,
                          height: 45,
                          child: HighlightedButton(
                            onPressed: () {
                              setState(() {
                                _textController.text += ' ';
                              });
                            },
                            child: const Icon(
                              Icons.space_bar,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                        if (!widget.isSingleLine)
                          HighlightedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                fixedSize: const Size(60, 45),
                                padding: const EdgeInsets.only(
                                    top: 2, bottom: 2, left: 13, right: 15),
                              ),
                              onPressed: () {
                                setState(() {
                                  _textController.text += "\n";
                                });
                              },
                              child: const Icon(Icons.subdirectory_arrow_left,
                                  color: Colors.white, size: 30)),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: 45,
                          child: Container(
                            margin: const EdgeInsets.only(left: 4, right: 3),
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
                                size: 25,
                              ),
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
