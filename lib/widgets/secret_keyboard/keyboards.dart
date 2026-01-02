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
          firstRowShifted: activeKeyboard?.firstRowShifted ??
              ['!', '@', '#', '\$', '%', '^', '&', '*', '(', ')'],
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
        final secondRow = activeKeyboard?.secondRow ??
            randomizeList('йцукенгшщзхъ'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('фывапролджэ'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('ячсмитьбю'.split(''));
        return Keyboard(
          name: 'Русский',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          firstRowShifted: activeKeyboard?.firstRowShifted ??
              ['!', '"', '№', ';', '%', ':', '?', '*', '(', ')'],
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
          alternatives: {
            'е': ['ё'],
            'ь': ['ъ'],
          },
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

        final alternatives = {
          'ტ': ['თ'],
          'წ': ['ჭ'],
          'პ': ['ფ'],
          'ს': ['შ'],
          'ც': ['ჩ'],
          'ზ': ['ძ'],
          'რ': ['ღ'],
          'ჯ': ['ჟ'],
        };

        return Keyboard(
            name: 'ქართული',
            keyPaddings: (top: 2, bottom: 2, left: 1, right: 1),
            firstRow: activeKeyboard?.firstRow ?? firstRow,
            secondRow: activeKeyboard?.secondRow ?? secondRow,
            thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
            fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
            firstRowShifted: activeKeyboard?.firstRowShifted ??
                ['!', '@', '#', '\$', '%', '^', '&', '*', '(', ')'],
            secondRowShifted: activeKeyboard?.secondRowShifted ??
                secondRow.map((e) {
                  if (alternatives.containsKey(e)) {
                    return alternatives[e]![0];
                  }
                  return e;
                }).toList(),
            thirdRowShifted: activeKeyboard?.thirdRowShifted ??
                thirdRow.map((e) {
                  if (alternatives.containsKey(e)) {
                    return alternatives[e]![0];
                  }
                  return e;
                }).toList(),
            fourthRowShifted: activeKeyboard?.fourthRowShifted ??
                fourthRow.map((e) {
                  if (alternatives.containsKey(e)) {
                    return alternatives[e]![0];
                  }
                  return e;
                }).toList(),
            isShifted: isShifted,
            isSpecial: isSpecial,
            alternatives: alternatives);
      case ('Turkish'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow = activeKeyboard?.secondRow ??
            randomizeList('qwertyuıopğü'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('asdfghjklşi'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('zxcvbnmöç'.split(''));
        return Keyboard(
          name: 'Türkçe',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          firstRowShifted: activeKeyboard?.firstRowShifted ??
              ['!', '\'', '^', '+', '%', '&', '/', '(', ')', '='],
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
          alternatives: {
            // Removed i/o/u/g/s/c as they are now separate keys or covered
          },
        );
      case ('German'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('qwertzuiopü'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('asdfghjklöä'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('yxcvbnm'.split(''));
        return Keyboard(
          name: 'Deutsch',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          firstRowShifted: activeKeyboard?.firstRowShifted ??
              ['!', '"', '§', '\$', '%', '&', '/', '(', ')', '='],
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
          alternatives: {
            // Removed a/o/u/s as they are now separate keys (except ß? ß is usually missing on iOS German, or long press on s. I'll leave ß in alternatives for 's')
            's': ['ß'],
          },
        );
      case ('Spanish'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('qwertyuiop'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('asdfghjklñ'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('zxcvbnm'.split(''));
        return Keyboard(
          name: 'Español',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          firstRowShifted: activeKeyboard?.firstRowShifted ??
              ['!', '"', '·', '\$', '%', '&', '/', '(', ')', '='],
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
          alternatives: {
            'a': ['á'],
            'e': ['é'],
            'i': ['í'],
            'o': ['ó'],
            'u': ['ú', 'ü'],
            // Removed 'n': ['ñ']
          },
        );
      case ('French'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('azertyuiop'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('qsdfghjklm'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('wxcvbn'.split(''));
        return Keyboard(
          name: 'Français',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          firstRowShifted: activeKeyboard?.firstRowShifted ??
              [
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
                '8',
                '9',
                '0'
              ], // French Shift+Number is Numbers usually, but here Unshift is already numbers. Let's make it standard symbols to be useful
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
          alternatives: {
            'a': ['à', 'â', 'æ'],
            'e': ['é', 'è', 'ê', 'ë'],
            'i': ['î', 'ï'],
            'o': ['ô', 'œ'],
            'u': ['ù', 'û', 'ü'],
            'c': ['ç'],
          },
        );
      case ('Italian'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('qwertyuiop'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('asdfghjkl'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('zxcvbnm'.split(''));
        return Keyboard(
          name: 'Italiano',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          firstRowShifted: activeKeyboard?.firstRowShifted ??
              ['!', '"', '£', '\$', '%', '&', '/', '(', ')', '='],
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
          alternatives: {
            'a': ['à'],
            'e': ['è', 'é'],
            'i': ['ì'],
            'o': ['ò'],
            'u': ['ù'],
          },
        );
      case ('Greek'):
        final firstRow =
            activeKeyboard?.firstRow ?? randomizeList('1234567890'.split(''));
        final secondRow =
            activeKeyboard?.secondRow ?? randomizeList('ςερτυθιοπ'.split(''));
        final thirdRow =
            activeKeyboard?.thirdRow ?? randomizeList('ασδφγηξκλ'.split(''));
        final fourthRow =
            activeKeyboard?.fourthRow ?? randomizeList('ζχψωβνμ'.split(''));
        return Keyboard(
          name: 'Ελληνικά',
          keyPaddings: (top: 2, bottom: 2, left: 2, right: 2),
          firstRow: activeKeyboard?.firstRow ?? firstRow,
          secondRow: activeKeyboard?.secondRow ?? secondRow,
          thirdRow: activeKeyboard?.thirdRow ?? thirdRow,
          fourthRow: activeKeyboard?.fourthRow ?? fourthRow,
          firstRowShifted: activeKeyboard?.firstRowShifted ??
              ['!', '@', '#', '\$', '%', '^', '&', '*', '(', ')'],
          secondRowShifted: activeKeyboard?.secondRowShifted ??
              secondRow.map((e) => e.toUpperCase()).toList(),
          thirdRowShifted: activeKeyboard?.thirdRowShifted ??
              thirdRow.map((e) => e.toUpperCase()).toList(),
          fourthRowShifted: activeKeyboard?.fourthRowShifted ??
              fourthRow.map((e) => e.toUpperCase()).toList(),
          isShifted: isShifted,
          isSpecial: isSpecial,
          alternatives: {
            'α': ['ά'],
            'ε': ['έ'],
            'η': ['ή'],
            'ι': ['ί'],
            'ο': ['ό'],
            'υ': ['ύ'],
            'ω': ['ώ'],
          },
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

  static List<String> get availableKeyboards => [
        'English',
        'Spanish',
        'French',
        'German',
        'Russian',
        'Italian',
        'Turkish',
        'Greek',
        'Georgian',
      ];

  static Map<String, String> abbreviations = {
    'English': 'EN',
    'Russian': 'RU',
    'Georgian': 'GE',
    'Turkish': 'TR',
    'German': 'DE',
    'Spanish': 'ES',
    'French': 'FR',
    'Italian': 'IT',
    'Greek': 'EL',
  };
}
