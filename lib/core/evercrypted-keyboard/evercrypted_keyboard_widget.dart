import 'package:evercrypted/core/entities/settings/settings_service.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/secret_keyboard/highlighted_button.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboard.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EvercryptedKeyboard extends ConsumerStatefulWidget {
  const EvercryptedKeyboard({super.key});
  @override
  EvercryptedKeyboardState createState() => EvercryptedKeyboardState();
}

class EvercryptedKeyboardState extends ConsumerState<EvercryptedKeyboard> {
  final textController = TextEditingController();

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

  bool keyboardSelectOpen = false;

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

    final keyboardState = ref.read(keyboardProvider);

    textController.text = keyboardState.startingText ?? '';

    // Add listener to textController to call widget.onTextChange
    textController.addListener(_textChangeListener);
  }

  // Create a dedicated method for the listener
  void _textChangeListener() {
    final keyboardState = ref.read(keyboardProvider);
    keyboardState.onEvercryptedKeyboardTextChange(textController.text);
  }

  @override
  void didUpdateWidget(EvercryptedKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final keyboardState = ref.read(keyboardProvider);
    textController.text = keyboardState.startingText ?? '';
  }

  @override
  void dispose() {
    // Remove the listener before disposing the controller
    textController.removeListener(_textChangeListener);
    textController.dispose();
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

    return Container(
      width: keyWidth,
      height: specialKeysRow ? 60 : 45,
      margin: specialKeysRow
          ? EdgeInsets.symmetric(horizontal: 1, vertical: 1.35)
          : EdgeInsets.all(1),
      child: GestureDetector(
        child: HighlightedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: paddings,
          ),
          onPressed: () {
            setState(() {
              textController.text += key;
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
              style: const TextStyle(color: Colors.white, fontSize: 20),
              textDirection: TextDirection.ltr),
        ),
      ),
    );
  }

  Widget _keyboard() {
    return Container(
        height: 300,
        padding: const EdgeInsets.only(top: 5),
        width: MediaQuery.of(context).size.width,
        color: primaryColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.ltr,
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
                textDirection: TextDirection.ltr,
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
              textDirection: TextDirection.ltr,
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
                textDirection: TextDirection.ltr,
                children: [
                  for (var key in activeKeyboard.fourthRowKeys)
                    _keyboardButton(key,
                        rowLength: activeKeyboard.fourthRowKeys.length)
                ],
              ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              width: MediaQuery.of(context).size.width,
              height: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.ltr,
                children: [
                  Row(
                    textDirection: TextDirection.ltr,
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
                                      const Duration(milliseconds: 300)) {
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
                            isShiftLocked ? Icons.lock : Icons.arrow_circle_up,
                            color: Colors.white,
                            size: 25,
                            textDirection: TextDirection.ltr,
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                              textDirection: TextDirection.ltr),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    textDirection: TextDirection.ltr,
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
                                textController.text.isNotEmpty) {
                              setState(() {
                                textController.text = textController.text
                                    .substring(
                                        0, textController.text.length - 1);
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
                                  top: 2, bottom: 2, left: 13, right: 15),
                            ),
                            onPressed: () {
                              if (selectionStart != null &&
                                  selectionEnd != null) {
                                setState(() {
                                  textController.text = textController.text
                                          .substring(0, selectionStart!) +
                                      textController.text
                                          .substring(selectionEnd!);
                                });
                              } else {
                                if (textController.text.isNotEmpty) {
                                  setState(() {
                                    textController.text = textController.text
                                        .substring(
                                            0, textController.text.length - 1);
                                  });
                                }
                              }
                            },
                            child: const Icon(
                              Icons.backspace,
                              color: Colors.white,
                              size: 30,
                              textDirection: TextDirection.ltr,
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
              textDirection: TextDirection.ltr,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    textDirection: TextDirection.ltr,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: InkWell(
                              onTap: () {
                                shouldShowKeyboard.value = false;
                              },
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 40,
                                textDirection: TextDirection.ltr,
                              )),
                        ),
                      ),
                      if (availableKeyboards.length > 1)
                        Material(
                          color: Colors.transparent,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  keyboardSelectOpen = !keyboardSelectOpen;
                                });
                              },
                              child: Icon(Icons.language,
                                  color: Colors.white,
                                  size: 25,
                                  textDirection: TextDirection.ltr),
                            ),
                          ),
                        ),
                      // Material(
                      //   color: Colors.transparent,
                      //   child: Directionality(
                      //     textDirection: TextDirection.ltr,
                      //     child: InkWell(
                      //         onTap: () {
                      //           setState(() {
                      //             shouldObscureText = !shouldObscureText;
                      //           });
                      //         },
                      //         child: Icon(
                      //           shouldObscureText
                      //               ? Icons.visibility_off
                      //               : Icons.visibility,
                      //           color: Colors.white,
                      //           size: 25,
                      //           textDirection: TextDirection.ltr,
                      //         )),
                      //   ),
                      // ),
                      Material(
                          color: Colors.transparent,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: InkWell(
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
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.30,
                  height: 45,
                  child: HighlightedButton(
                    onPressed: () {
                      setState(() {
                        textController.text += ' ';
                      });
                    },
                    child: const Icon(
                      Icons.space_bar,
                      color: Colors.white,
                      size: 25,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ),
                HighlightedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      fixedSize: const Size(60, 45),
                      padding: const EdgeInsets.only(
                          top: 2, bottom: 2, left: 13, right: 15),
                    ),
                    onPressed: () {
                      setState(() {
                        textController.text += "\n";
                      });
                    },
                    child: const Icon(Icons.subdirectory_arrow_left,
                        color: Colors.white,
                        size: 30,
                        textDirection: TextDirection.ltr)),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: 45,
                  child: Container(
                    margin: const EdgeInsets.only(left: 4, right: 3),
                    child: HighlightedButton(
                      backgroundColor: Colors.lightGreen,
                      onPressed: () {
                        Navigator.of(context).pop((
                          text: textController.text,
                          done: true,
                        ));
                      },
                      child: const Icon(
                        Icons.done,
                        color: Colors.white,
                        size: 25,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _keyboardSelect() {
    return Container(
      color: primaryColor,
      height: 300,
      padding: const EdgeInsets.only(top: 5, bottom: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              'Select Keyboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: availableKeyboards.map((language) {
                    final isActive = language == activeLanguage;
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: HighlightedButton(
                        isActive: isActive,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            activeLanguage = language;
                            isShifted = false;
                            isSpecial = false;
                            isShiftLocked = false;
                            activeKeyboard = Keyboards.getKeyboard(
                              language: activeLanguage,
                              isShifted: false,
                              isSpecial: false,
                              randomize: isRandomized,
                            );
                            keyboardSelectOpen = false;
                          });
                        },
                        child: Text(
                          language,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isActive ? 22 : 18,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: HighlightedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                setState(() {
                  keyboardSelectOpen = false;
                });
              },
              child: Text(
                'Back to Keyboard',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return keyboardSelectOpen ? _keyboardSelect() : _keyboard();
  }
}
