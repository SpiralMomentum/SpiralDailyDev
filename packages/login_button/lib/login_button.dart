import 'package:flutter/material.dart';

/// [LoginButton] is a reusable widget that displays a button typically used
/// for login actions.
///
/// It mirrors the API of Flutter's [ElevatedButton] to provide a familiar
/// interface. Consumers inject the tap behaviour via the [onPressed]
/// callback.
class LoginButton extends StatelessWidget {
  /// Creates a [LoginButton].
  const LoginButton({
    super.key,
    required this.onPressed,
    this.label = 'Login',
    this.backgroundColor,
    this.textStyle,
    this.width,
    this.height,
  });

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// The text label displayed inside the button. Defaults to `Login`.
  final String label;

  /// Background color of the button. If null, defaults to the theme's color.
  final Color? backgroundColor;

  /// Text style for the label.
  final TextStyle? textStyle;

  /// Optional width of the button.
  final double? width;

  /// Optional height of the button.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
      child: Text(label, style: textStyle),
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: button);
    }
    return button;
  }
}
