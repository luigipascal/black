import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RedactableText extends StatefulWidget {
  final String secret;
  final String placeholder;
  final String unlockKey;

  const RedactableText({
    required this.secret,
    required this.placeholder,
    required this.unlockKey,
    super.key,
  });

  @override
  State<RedactableText> createState() => _RedactableTextState();
}

class _RedactableTextState extends State<RedactableText> {
  bool get _unlocked =>
      context.watch<UnlockProvider>().isUnlocked(widget.unlockKey);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_unlocked) return;
        final ok = await showPurchaseSheet(context, widget.unlockKey);
        if (ok) context.read<UnlockProvider>().unlock(widget.unlockKey);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _unlocked
            ? Text(widget.secret, key: const ValueKey('open'))
            : Container(
                key: const ValueKey('redacted'),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.black,
                child: Text(widget.placeholder,
                    style: const TextStyle(color: Colors.black)),
              ),
      ),
    );
  }
}