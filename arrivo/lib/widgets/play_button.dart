import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Simple 40 px round teal preview button with a navy play (or pause) icon.
/// The tap area is 48 x 48 for accessibility.
class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Stop preview' : 'Preview sound',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x99FFFFFF)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x6614B8A6), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 26,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
