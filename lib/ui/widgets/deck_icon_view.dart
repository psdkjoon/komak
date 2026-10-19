import 'package:flutter/material.dart' hide Icon, Text;
import 'package:komak/decks/deck_icons.dart';
import 'package:komak/localization/localization.dart';

class DeckIconView extends StatelessWidget {
  const DeckIconView({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 48,
  });

  final String iconKey;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(iconForDeckKey(iconKey), color: color, size: size * 0.52),
    );
  }
}
