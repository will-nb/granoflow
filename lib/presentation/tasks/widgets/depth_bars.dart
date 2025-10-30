import 'package:flutter/material.dart';

const List<Color> depthBarColors = <Color>[
  Color(0xFF7F8CFF),
  Color(0xFF5AC9B0),
  Color(0xFFFFB86C),
  Color(0xFFE59BFF),
];

class DepthBars extends StatelessWidget {
  const DepthBars({super.key, required this.depth});

  final int depth;

  @override
  Widget build(BuildContext context) {
    if (depth <= 0) {
      return const SizedBox(width: 4, height: 40);
    }
    final bars = List<Widget>.generate(depth, (index) {
      return Container(
        width: 4,
        height: 40,
        margin: EdgeInsets.only(right: index == depth - 1 ? 0 : 4),
        decoration: BoxDecoration(
          color: depthBarColors[index % depthBarColors.length],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });
    return SizedBox(
      width: depth * 8,
      child: Row(mainAxisSize: MainAxisSize.min, children: bars),
    );
  }
}

