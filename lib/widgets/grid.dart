import 'package:flutter/material.dart';

class Grid extends StatelessWidget {
  final List<Widget> children;
  final double childWidth;

  const Grid({
    super.key,
    required this.children,
    required this.childWidth,
  });

  @override
  Widget build(BuildContext context) {
    final int columnCount =
        (MediaQuery.of(context).size.width / childWidth).floor();
    final int rowCount = (children.length / columnCount).ceil();

    return Column(
      children: [
        for (int i = 0; i < rowCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int j = 0; j < columnCount; j++)
                  if (i * columnCount + j < children.length)
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: children[i * columnCount + j]),
              ],
            ),
          )
      ],
    );
  }
}
