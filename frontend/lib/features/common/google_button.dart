import 'package:material_ui/material_ui.dart';

/// "Sign in with Google" in Google's branded style: the four-colour G on a
/// white (or, in dark mode, near-black) pill with a grey outline.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.label = 'Sign in with Google',
  });

  final VoidCallback? onPressed;
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: dark ? const Color(0xFF131314) : Colors.white,
        foregroundColor: dark
            ? const Color(0xFFE3E3E3)
            : const Color(0xFF1F1F1F),
        disabledBackgroundColor: dark ? const Color(0xFF131314) : Colors.white,
        side: BorderSide(
          color: dark ? const Color(0xFF8E918F) : const Color(0xFF747775),
        ),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      icon: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Image.asset(
              'assets/images/brand/google_g.png',
              width: 20,
              height: 20,
              excludeFromSemantics: true,
            ),
      label: Text(label),
    );
  }
}
