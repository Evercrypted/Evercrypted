class Keyboard {
  String name;
  bool isShifted = false;
  bool isSpecial = false;

  List<String> firstRow;
  List<String> secondRow;
  List<String> thirdRow;
  List<String> fourthRow;

  double keyWidth;
  double keyHeight;

  List<String> firstRowShifted;
  List<String> secondRowShifted;
  List<String> thirdRowShifted;
  List<String> fourthRowShifted;

  late ({double top, double bottom, double left, double right}) keyPaddings;
  late ({double top, double bottom, double left, double right}) keyMargins;

  static const defaultWidth = 35.0;
  static const defaultHeight = 40.0;

  static const ({
    double top,
    double bottom,
    double left,
    double right
  }) defaultPaddings = (top: 2, bottom: 2, left: 3, right: 3);
  static const ({
    double top,
    double bottom,
    double left,
    double right
  }) defaultMargins = (top: 2, bottom: 2, left: 3, right: 3);

  final Map<String, List<String>> alternatives;

  Keyboard({
    required this.name,
    this.isShifted = false,
    this.isSpecial = false,
    this.keyPaddings = defaultPaddings,
    this.keyMargins = defaultMargins,
    this.keyWidth = defaultWidth,
    this.keyHeight = defaultHeight,
    required this.firstRow,
    required this.secondRow,
    required this.thirdRow,
    required this.fourthRow,
    this.firstRowShifted = const [],
    required this.secondRowShifted,
    required this.thirdRowShifted,
    required this.fourthRowShifted,
    this.alternatives = const {},
  });

  static const List<String> firstRowSpecial = [
    '[',
    ']',
    '{',
    '}',
    '#',
    '%',
    '^',
    '*',
    '+',
    '='
  ];
  static const List<String> secondRowSpecial = [
    '-',
    '/',
    ':',
    ';',
    '(',
    ')',
    '\$',
    '&',
    '@',
    '"'
  ];
  static const List<String> thirdRowSpecial = [
    '`', // Backtick
    '~',
    '_',
    '\\',
    '|',
    '.',
    ',',
    '?',
    '!',
    '\''
  ];

  get firstRowKeys => isSpecial
      ? firstRowSpecial
      : isShifted
          ? (firstRowShifted.isNotEmpty ? firstRowShifted : firstRow)
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

  get fourthRowKeys => isShifted ? fourthRowShifted : fourthRow;

  List<String>? getAlternatives(String key) {
    return alternatives[key.toLowerCase()];
  }
}
