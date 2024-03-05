class Keyboard {
  String name;
  bool isShifted = false;
  bool isSpecial = false;

  List<String> firstRow;
  List<String> secondRow;
  List<String> thirdRow;
  List<String> fourthRow;

  static List<String> firstRowShifted = [
    '!',
    '"',
    '#',
    '\$',
    '%',
    '^',
    '&',
    '*',
    '(',
    ')'
  ];
  List<String> secondRowShifted;
  List<String> thirdRowShifted;
  List<String> fourthRowShifted;

  static List<String> firstRowSpecial = [
    '-',
    '_',
    '=',
    '+',
    '[',
    ']',
    '{',
    '}',
    '|',
    '\\'
  ];
  static List<String> secondRowSpecial = [
    ';',
    ':',
    '\'',
    '"',
    ',',
    '.',
    '<',
    '>',
    '/',
    '?'
  ];
  static List<String> thirdRowSpecial = [
    '`',
    '~',
    '!',
    '@',
    '#',
    '\$',
    '%',
    '^',
    '&',
    '*'
  ];
  static List<String> fourthRowSpecial = [
    '(',
    ')',
    '_',
    '+',
    '-',
    '=',
    '{',
    '}',
    '[',
    ']'
  ];

  Keyboard(
      {required this.name,
      this.isShifted = false,
      this.isSpecial = false,
      required this.firstRow,
      required this.secondRow,
      required this.thirdRow,
      required this.fourthRow,
      required this.secondRowShifted,
      required this.thirdRowShifted,
      required this.fourthRowShifted});

  get firstRowKeys => isSpecial
      ? firstRowSpecial
      : isShifted
          ? firstRowShifted
          : firstRow;
  get secondRowKeys => isSpecial
      ? secondRowSpecial
      : isShifted
          ? secondRowShifted
          : secondRow;

  get thirdRowKeys => isSpecial
      ? thirdRowSpecial
      : isShifted
          ? thirdRowShifted
          : thirdRow;

  get fourthRowKeys => isSpecial
      ? fourthRowSpecial
      : isShifted
          ? fourthRowShifted
          : fourthRow;
}
