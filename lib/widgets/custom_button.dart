import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const CustomButton({
    super.key,
    required this.onTap,
    required this.text,
    this.backgroundColor = Colors.green,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.60, // 75% of screen width
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: const StadiumBorder(), // pill shape
          ),
          child: Text(
            text,
            style: TextStyle(color: textColor, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
