import 'package:flutter/material.dart';

class SoundButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SoundButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        iconSize: 64,
        icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
