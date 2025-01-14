import 'package:evercrypted/widgets/secret_keyboard/keyboard.dart';

class Keyboards {
  static Keyboard getKeyboard(
      {language = 'English',
      Keyboard? activeKeyboard,
      isShifted = false,
      isSpecial = false,
      randomize = false}) {
    // Helper function to randomize a list
    List<String> randomizeList(List<String> list) {
      if (randomize) {
        var shuffled = List<String>.from(list);
        shuffled.shuffle();
        return shuffled;
      }
      return list;
    }

    switch (language) {
      case ('English'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('qwertyuiop'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('asdfghjkl'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('zxcvbnm'.split(''));
        return Keyboard(
          name: 'English',
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
      case ('Russian'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('йцукенгшщзх'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('фывапролджэ'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('ячсмитьбюъ'.split(''));
        return Keyboard(
          name: 'Русский',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
      case ('Georgian'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('ქწერტყუიოპ'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('ასდფგჰჯკლ'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('ზხცვბნმ'.split(''));
        return Keyboard(
          name: 'ქართული',
          keyPaddings: (top: 2, bottom: 2, left: 1, right: 1),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              randomizeList('ქჭეღთყუიოპ'.split('')),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              randomizeList('აშდფგჰჟკლ'.split('')),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              randomizeList('ძხჩვბნმ'.split('')),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
      case ('Turkish'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('qwertyuiopğ'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('asdfghjklşi'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('zxcvbnmöçü'.split(''));
        return Keyboard(
          name: 'Türkçe',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
      default:
        return Keyboard(
          name: 'English',
          firstRow: randomizeList('1234567890'.split('')),
          secondRow: randomizeList('qwertyuiop'.split('')),
          thirdRow: randomizeList('asdfghjkl'.split('')),
          fourthRow: randomizeList('zxcvbnm'.split('')),
          secondRowShifted: randomizeList('QWERTYUIOP'.split('')),
          thirdRowShifted: randomizeList('ASDFGHJKL'.split('')),
          fourthRowShifted: randomizeList('ZXCVBNM'.split('')),
          isShifted: isShifted,
          isSpecial: isSpecial,
        );
    }
  }

  static List<String> get availableKeyboards =>
      ['English', 'Russian', 'Georgian', 'Turkish'];

  static Map<String, String> abbreviations = {
    'English': 'EN',
    'Russian': 'RU',
    'Georgian': 'GE',
    'Turkish': 'TR',
  };
}
