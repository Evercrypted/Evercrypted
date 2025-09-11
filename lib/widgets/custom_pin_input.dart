import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui_constants.dart';

class CustomPinInput extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool hasError;
  final bool autofocus;
  final bool autoReset;

  const CustomPinInput({
    super.key,
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.autofocus = false,
    this.autoReset = true,
  });

  @override
  State<CustomPinInput> createState() => _CustomPinInputState();
}

class _CustomPinInputState extends State<CustomPinInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _pin = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    
    // Auto focus first field if requested
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Handle paste operation - if pasted text is longer than 1 character
      if (value.length > 1) {
        _handlePaste(value, index);
        return;
      }
      
      _controllers[index].text = value.substring(value.length - 1);
      
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      // Handle deletion in current field
      _controllers[index].clear();
    }
    
    _updatePin();
  }

  void _onKeyDown(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      } else if (_controllers[index].text.isNotEmpty) {
        _controllers[index].clear();
      }
      _updatePin();
    }
  }

  void _handlePaste(String value, int startIndex) {
    // Extract only digits from pasted text
    String digits = value.replaceAll(RegExp(r'\D'), '');
    
    // Fill available fields starting from current index
    for (int i = 0; i < digits.length && (startIndex + i) < widget.length; i++) {
      _controllers[startIndex + i].text = digits[i];
    }
    
    // Focus next empty field or last field
    int nextIndex = (startIndex + digits.length).clamp(0, widget.length - 1);
    if (nextIndex < widget.length) {
      _focusNodes[nextIndex].requestFocus();
    }
    
    _updatePin();
  }

  void _updatePin() {
    _pin = _controllers.map((controller) => controller.text).join();
    
    if (widget.onChanged != null) {
      widget.onChanged!(_pin);
    }
    
    if (_pin.length == widget.length) {
      widget.onCompleted(_pin);
      
      // Auto reset after completion if enabled
      if (widget.autoReset) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            clearPin();
          }
        });
      }
    }
  }

  void clearPin() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _pin = '';
    if (mounted) {
      _focusNodes[0].requestFocus();
    }
    if (widget.onChanged != null) {
      widget.onChanged!('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyDown(event, index),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.hasError ? errorColor : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.hasError ? errorColor : primaryColor,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.hasError ? errorColor : Colors.grey.shade300,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: errorColor, width: 2),
                ),
              ),
              onChanged: (value) => _onChanged(value, index),
              onTap: () {
                _controllers[index].selection = TextSelection.fromPosition(
                  TextPosition(offset: _controllers[index].text.length),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}