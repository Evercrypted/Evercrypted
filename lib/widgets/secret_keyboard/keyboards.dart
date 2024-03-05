import 'package:evercrypted/widgets/secret_keyboard/keyboard.dart';

class Keyboards {
  static Keyboard getKeyboard(
      {language = 'English', isShifted = false, isSpecial = false}) {
    switch (language) {
      case ('English'):
        return Keyboard(
          name: 'English',
          firstRow: List<String>.from('1234567890'.split('')),
          secondRow: List<String>.from('qwertyuiop'.split('')),
          thirdRow: List<String>.from('asdfghjkl'.split('')),
          fourthRow: List<String>.from('zxcvbnm'.split('')),
          secondRowShifted: List<String>.from('QWERTYUIOP'.split('')),
          thirdRowShifted: List<String>.from('ASDFGHJKL'.split('')),
          fourthRowShifted: List<String>.from('ZXCVBNM'.split('')),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
      case ('Russian'):
        return Keyboard(
          name: 'Русский',
          firstRow: List<String>.from('1234567890'.split('')),
          secondRow: List<String>.from('йцукенгшщзхъ'.split('')),
          thirdRow: List<String>.from('фывапролджэ'.split('')),
          fourthRow: List<String>.from('ячсмитьбю'.split('')),
          secondRowShifted: List<String>.from('ЙЦУКЕНГШЩЗХЪ'.split('')),
          thirdRowShifted: List<String>.from('ФЫВАПРОЛДЖЭ'.split('')),
          fourthRowShifted: List<String>.from('ЯЧСМИТЬБЮ'.split('')),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
      case ('Georgian'):
        return Keyboard(
          name: 'ქართული',
          firstRow: List<String>.from('1234567890'.split('')),
          secondRow: List<String>.from('ქწერტყუიოპ'.split('')),
          thirdRow: List<String>.from('ასდფგჰჯკლ'.split('')),
          fourthRow: List<String>.from('ზხცვბნმ'.split('')),
          secondRowShifted: List<String>.from('ქჭეღთყუიოპ'.split('')),
          thirdRowShifted: List<String>.from('აშდფგჰჟკლ'.split('')),
          fourthRowShifted: List<String>.from('ძხჩვბნმ'.split('')),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
      case ('Turkish'):
        return Keyboard(
          name: 'Türkçe',
          firstRow: List<String>.from('1234567890'.split('')),
          secondRow: List<String>.from('qwertyuiopğü'.split('')),
          thirdRow: List<String>.from('asdfghjklşi'.split('')),
          fourthRow: List<String>.from('zxcvbnmöç'.split('')),
          secondRowShifted: List<String>.from('QWERTYUIOPĞÜ'.split('')),
          thirdRowShifted: List<String>.from('ASDFGHJKLŞİ'.split('')),
          fourthRowShifted: List<String>.from('ZXCVBNMÖÇ'.split('')),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
      default:
        return Keyboard(
          name: 'English',
          firstRow: List<String>.from('1234567890'.split('')),
          secondRow: List<String>.from('qwertyuiop'.split('')),
          thirdRow: List<String>.from('asdfghjkl'.split('')),
          fourthRow: List<String>.from('zxcvbnm'.split('')),
          secondRowShifted: List<String>.from('QWERTYUIOP'.split('')),
          thirdRowShifted: List<String>.from('ASDFGHJKL'.split('')),
          fourthRowShifted: List<String>.from('ZXCVBNM'.split('')),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
    }
  }

  static List<String> get availableKeyboards =>
      ['English', 'Russian', 'Georgian', 'Turkish'];
}
