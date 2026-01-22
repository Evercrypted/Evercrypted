import 'package:evercrypted/core/entities/settings/settings_model.dart';
import 'package:evercrypted/core/entities/settings/settings_service.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/secret_keyboard/highlighted_button.dart';
import 'package:evercrypted/widgets/secret_keyboard/key_popup_button.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboard.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class EvercryptedKeyboard extends ConsumerStatefulWidget {
  const EvercryptedKeyboard({super.key});
  @override
  EvercryptedKeyboardState createState() => EvercryptedKeyboardState();
}

class EvercryptedKeyboardState extends ConsumerState<EvercryptedKeyboard> {
  late TextEditingController controller;

  List<String> availableKeyboards = ['English']; // Start with only English
  bool isShifted = false;
  bool isSpecial = false;
  bool isSpecialPage2 = false; // iOS-style second page of special chars (#+=)
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
      // Load last used keyboard language
      if (settings != null &&
          availableKeyboards.contains(settings.lastUsedKeyboard)) {
        activeLanguage = settings.lastUsedKeyboard;
        activeKeyboard = Keyboards.getKeyboard(language: activeLanguage);
      }
    });
  }

  void saveLastUsedKeyboard(String language) {
    final settings = SettingsService.getSettings() ?? Settings();
    settings.lastUsedKeyboard = language;
    SettingsService.saveSettings(settings);
  }

  @override
  void initState() {
    super.initState();
    loadAvailableKeyboards();

    final keyboardState = ref.read(keyboardProvider);

    controller = keyboardState.controller;
    controller.addListener(listenerFn);
    controller.addListener(onChangeListener);
  }

  @override
  void dispose() {
    controller.removeListener(listenerFn);
    controller.removeListener(onChangeListener);
    super.dispose();
  }

  onChangeListener() {
    final keyboardState = ref.read(keyboardProvider);
    keyboardState.onChange?.call(controller.text);
  }

  listenerFn() {
    if (controller.selection.start != controller.selection.end) {
      selectionStart = controller.selection.start;
      selectionEnd = controller.selection.end;
    } else {
      selectionStart = null;
      selectionEnd = null;
    }
  }

  deleteSelection() {
    if (selectionStart != null && selectionEnd != null) {
      setState(() {
        controller.text = controller.text.substring(0, selectionStart!) +
            controller.text.substring(selectionEnd!);
      });
    }
  }

  Widget _keyboardButton(key,
      {useDefualtSizes = false,
      double rowLength = 0,
      specialKeysRow = false,
      double? width}) {
    final screenWidth = MediaQuery.of(context).size.width - 2;
    // Calculate keyWidth. specific logic for mixed rows handles this outside or pass custom rowLength
    final keyWidth = width ??
        (rowLength > 0
            ? ((screenWidth - (rowLength + 1) * 2) / rowLength)
            : (useDefualtSizes || isSpecial
                ? Keyboard.defaultWidth
                : activeKeyboard.keyWidth));

    // Get alternatives for this key (accented characters)
    // Look up using lowercase key, then apply case transformation if shifted
    List<String>? alternatives = activeKeyboard.getAlternatives(key);
    if (alternatives != null && isShifted) {
      alternatives = alternatives.map((e) => e.toUpperCase()).toList();
    }

    return Container(
      width: keyWidth,
      height: specialKeysRow ? 60 : 45,
      margin: specialKeysRow
          ? EdgeInsets.symmetric(horizontal: 1, vertical: 1.35)
          : EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withAlpha(20),
      ),
      child: KeyPopupButton(
        keyLabel: key,
        width: keyWidth,
        height: specialKeysRow ? 60 : 45,
        textStyle: const TextStyle(color: Colors.white, fontSize: 20),
        alternatives: alternatives,
        onPressed: () {
          deleteSelection();
          setState(() {
            final newText = controller.text + key;
            controller
              ..text = newText
              ..selection = TextSelection.collapsed(offset: newText.length);
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
        onAlternativeSelected: (selected) {
          deleteSelection();
          setState(() {
            final newText = controller.text + selected;
            controller
              ..text = newText
              ..selection = TextSelection.collapsed(offset: newText.length);
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
      ),
    );
  }

  // --- Helper Widgets for Special Keys ---

  Widget _buildShiftKey() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 42, // Fixed width approx 1.25x normal key
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isShiftLocked ? Colors.white : Colors.white.withAlpha(40),
      ),
      child: HighlightedButton(
        isActive: isShifted,
        style: ElevatedButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
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
          isShiftLocked ? Icons.lock : Icons.arrow_upward,
          color: isShiftLocked ? Colors.black : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(
      {double width = 42,
      double height = 45,
      EdgeInsetsGeometry margin = const EdgeInsets.symmetric(horizontal: 2)}) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.white.withAlpha(40),
      ),
      child: GestureDetector(
        onLongPressStart: (_) async {
          setState(() {
            isBackspaceLongPressed = true;
          });
          while (isBackspaceLongPressed && controller.text.isNotEmpty) {
            setState(() {
              final newText =
                  controller.text.substring(0, controller.text.length - 1);
              controller
                ..text = newText
                ..selection = TextSelection.collapsed(offset: newText.length);
            });
            await Future.delayed(const Duration(milliseconds: 100));
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
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
          ),
          onPressed: () {
            deleteSelection();
            if (controller.text.isNotEmpty) {
              setState(() {
                final newText =
                    controller.text.substring(0, controller.text.length - 1);
                controller
                  ..text = newText
                  ..selection = TextSelection.collapsed(offset: newText.length);
              });
            }
          },
          child: const Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _keyboard() {
    return Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha((255 * 0.3).round())),
          ),
          color: primaryColor,
        ),
        width: MediaQuery.of(context).size.width,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          children: [
            // Header
            Container(
              margin: EdgeInsets.symmetric(vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: [
                  SvgPicture.asset(
                    infinityLogo,
                    height: 14,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Evercrypted Keyboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),

            // Row 1 (Numbers / Special page 1 or 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.ltr,
              children: [
                for (var key in (isSpecial
                    ? (isSpecialPage2
                        ? Keyboard.firstRowSpecial2
                        : Keyboard.firstRowSpecial)
                    : activeKeyboard.firstRowKeys))
                  _keyboardButton(key,
                      useDefualtSizes: true,
                      rowLength: 10,
                      specialKeysRow: isSpecial)
              ],
            ),

            // Row 2
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.ltr,
              children: [
                for (var key in (isSpecial
                    ? (isSpecialPage2
                        ? Keyboard.secondRowSpecial2
                        : Keyboard.secondRowSpecial)
                    : activeKeyboard.secondRowKeys))
                  _keyboardButton(key, rowLength: 10, specialKeysRow: isSpecial)
              ],
            ),

            // Row 3 (Special mode has shorter row + toggle key + backspace)
            Builder(builder: (context) {
              if (!isSpecial) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.ltr,
                  children: [
                    for (var key in activeKeyboard.thirdRowKeys)
                      _keyboardButton(key,
                          rowLength:
                              activeKeyboard.thirdRowKeys.length.toDouble(),
                          specialKeysRow: false),
                  ],
                );
              }

              // Special mode - calculate key widths
              final specialChars = isSpecialPage2
                  ? Keyboard.thirdRowSpecial2
                  : Keyboard.thirdRowSpecial;
              // Available width = screen - toggle(50+4) - backspace(50+4) - margins
              final screenWidth = MediaQuery.of(context).size.width;
              final availableWidth = screenWidth - 50 - 4 - 50 - 4 - 20;
              final keyWidth = availableWidth / specialChars.length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: [
                  // 123/#+= toggle button
                  Container(
                    width: 50,
                    height: 60,
                    margin: EdgeInsets.symmetric(horizontal: 2, vertical: 1.35),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withAlpha(40),
                    ),
                    child: HighlightedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: () {
                        setState(() {
                          isSpecialPage2 = !isSpecialPage2;
                        });
                      },
                      child: Text(
                        isSpecialPage2 ? '123' : '#+=',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Character keys
                  for (var key in specialChars)
                    Container(
                      width: keyWidth,
                      height: 60,
                      margin:
                          EdgeInsets.symmetric(horizontal: 1, vertical: 1.35),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withAlpha(20),
                      ),
                      child: KeyPopupButton(
                        keyLabel: key,
                        width: keyWidth,
                        height: 60,
                        textStyle:
                            const TextStyle(color: Colors.white, fontSize: 20),
                        onPressed: () {
                          deleteSelection();
                          setState(() {
                            final newText = controller.text + key;
                            controller
                              ..text = newText
                              ..selection = TextSelection.collapsed(
                                  offset: newText.length);
                          });
                        },
                      ),
                    ),
                  // Backspace
                  _buildBackspaceKey(
                      width: 50,
                      height: 60,
                      margin:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 1.35)),
                ],
              );
            }),

            // Row 4 (Letters + Shift + Backspace, Normal Mode only)
            if (!isSpecial)
              Container(
                margin: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.ltr,
                  children: [
                    _buildShiftKey(),
                    // Letters
                    for (var key in activeKeyboard.fourthRowKeys)
                      Builder(builder: (context) {
                        // Calculate specific width for this row's keys
                        // Available width = Screen - Shift(42+4) - Backspace(42+4) - Margins(2)
                        // This is approximate but safer than fixed rowLength
                        double availableWidth =
                            MediaQuery.of(context).size.width -
                                (42 + 4) -
                                (42 + 4) -
                                (2 * activeKeyboard.fourthRowKeys.length);
                        return _keyboardButton(key,
                            width: availableWidth /
                                activeKeyboard.fourthRowKeys.length);
                      }),
                    _buildBackspaceKey(),
                  ],
                ),
              ),

            // Row 5 (Space, etc)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.ltr,
                children: [
                  // Special / 123 / #+=
                  Container(
                    width: 42,
                    height: 45,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    child: HighlightedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white.withAlpha(20),
                      ),
                      onPressed: () {
                        setState(() {
                          isSpecial = !isSpecial;
                          isSpecialPage2 =
                              false; // Always reset to page 1 (numbers)
                          activeKeyboard = Keyboards.getKeyboard(
                              language: activeLanguage,
                              activeKeyboard: activeKeyboard,
                              isShifted: isShifted,
                              isSpecial: isSpecial);
                        });
                      },
                      child: Text(isSpecial ? 'ABC' : '123',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                  ),

                  // Hide Keyboard Button (shown on left when onDone is set)
                  Consumer(builder: (context, ref, child) {
                    final keyboardState = ref.watch(keyboardProvider);
                    if (keyboardState.onDone == null) {
                      return SizedBox.shrink();
                    }
                    return Container(
                      width: 42,
                      height: 45,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      child: HighlightedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                        ),
                        onPressed: () {
                          ref.read(keyboardProvider.notifier).close();
                        },
                        child: Icon(Icons.keyboard_hide, color: Colors.white),
                      ),
                    );
                  }),

                  // Shuffle
                  Container(
                    width: 42,
                    height: 45,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    child: HighlightedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isRandomized
                            ? Colors.white
                            : Colors.white.withAlpha(20),
                      ),
                      onPressed: () {
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
                          color: isRandomized ? Colors.black : Colors.white),
                    ),
                  ),

                  // Space
                  // Space
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (availableKeyboards.length <= 1) return;

                        // Swipe logic
                        int currentIndex =
                            availableKeyboards.indexOf(activeLanguage);
                        if (currentIndex == -1) currentIndex = 0;

                        String newLang = activeLanguage;

                        // Swipe Right (velocity > 0) -> Previous Ltr visual? Or Next?
                        // Usually Swipe Left (finger goes left) -> Next. Swipe Right -> Prev.
                        if (details.primaryVelocity! < 0) {
                          // Swipe Left -> Next
                          int nextIndex =
                              (currentIndex + 1) % availableKeyboards.length;
                          newLang = availableKeyboards[nextIndex];
                        } else if (details.primaryVelocity! > 0) {
                          // Swipe Right -> Prev
                          int prevIndex =
                              (currentIndex - 1 + availableKeyboards.length) %
                                  availableKeyboards.length;
                          newLang = availableKeyboards[prevIndex];
                        }

                        if (newLang != activeLanguage) {
                          setState(() {
                            activeLanguage = newLang;
                            activeKeyboard = Keyboards.getKeyboard(
                                language: activeLanguage,
                                isShifted: isShifted,
                                isSpecial: isSpecial,
                                randomize: isRandomized);
                          });
                          saveLastUsedKeyboard(newLang);
                        }
                      },
                      child: Container(
                        height: 45,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.white.withAlpha(40),
                        ),
                        child: HighlightedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5))),
                          onPressed: () {
                            setState(() {
                              final newText = '${controller.text} ';
                              controller
                                ..text = newText
                                ..selection = TextSelection.collapsed(
                                    offset: newText.length);
                            });
                          },
                          child: Text(
                              availableKeyboards.length > 1
                                  ? '< $activeLanguage >'
                                  : 'Space',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),

                  // . Key (kept from last time)
                  // . Key (Only if NOT multiline)
                  Consumer(builder: (context, ref, child) {
                    final keyboardState = ref.watch(keyboardProvider);
                    if (!keyboardState.isMultiLine) {
                      return Container(
                        width: 38,
                        height: 45,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        child: _keyboardButton('.',
                            useDefualtSizes: true, rowLength: 10),
                      );
                    }
                    return SizedBox.shrink();
                  }),

                  // Enter
                  // Enter / Go Split
                  // If multiline, show a separate Return button with long-press alternatives
                  Consumer(builder: (context, ref, child) {
                    final keyboardState = ref.watch(keyboardProvider);
                    if (keyboardState.isMultiLine) {
                      return Container(
                        width: 42,
                        height: 45,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        child: KeyPopupButton(
                          keyLabel: '⏎',
                          width: 42,
                          height: 45,
                          textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          alternatives: const ['.', ',', '?', '!', '@'],
                          onPressed: () {
                            setState(() {
                              final newText = "${controller.text}\n";
                              controller
                                ..text = newText
                                ..selection = TextSelection.collapsed(
                                    offset: newText.length);
                            });
                          },
                          onAlternativeSelected: (selected) {
                            deleteSelection();
                            setState(() {
                              final newText = controller.text + selected;
                              controller
                                ..text = newText
                                ..selection = TextSelection.collapsed(
                                    offset: newText.length);
                            });
                          },
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }),

                  // Send Button OR Hide Keyboard Button
                  Consumer(builder: (context, ref, child) {
                    final keyboardState = ref.watch(keyboardProvider);
                    if (keyboardState.onDone != null) {
                      // Show Send button when onDone is set
                      return Container(
                        width: 42,
                        height: 45,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        child: HighlightedButton(
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.blue),
                            onPressed: () {
                              // Call the onDone callback with the text
                              keyboardState.onDone?.call();
                              // Close the keyboard
                              ref.read(keyboardProvider.notifier).close();
                            },
                            child: Icon(Icons.send, color: Colors.white)),
                      );
                    } else {
                      // Show Hide Keyboard button when no onDone
                      return Container(
                        width: 42,
                        height: 45,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        child: HighlightedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.white.withAlpha(20),
                          ),
                          onPressed: () {
                            ref.read(keyboardProvider.notifier).close();
                          },
                          child: Icon(Icons.keyboard_hide, color: Colors.white),
                        ),
                      );
                    }
                  })
                ],
              ),
            )
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
                          saveLastUsedKeyboard(language);
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
    ref.listen(keyboardProvider, (previous, next) {
      controller.removeListener(listenerFn);
      controller.removeListener(onChangeListener);
      controller = next.controller;
      controller.addListener(listenerFn);
      controller.addListener(onChangeListener);
    });

    return Directionality(
      textDirection: TextDirection.ltr,
      child: keyboardSelectOpen ? _keyboardSelect() : _keyboard(),
    );
  }
}
