import 'package:flutter/material.dart';
// import 'package:barkati_frits/utils/colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final Function(String)? onTap;
  final bool isValid;
  final bool enabled; // <--- ADDED THIS LINE

  const CustomTextField({
    Key? key,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.onTap,
    this.isValid = false,
    this.enabled = true, // <--- ADDED THIS LINE (default to true)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390), // reduced width
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          onSubmitted: onTap,
          enabled: enabled, // <--- USED THIS LINE
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: SizedBox(
                      width: 20,
                      height: 45,
                      child: prefixIcon,
                    ),
                  )
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: isValid
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.check_circle,
                        color: Color(0xFFFFC107), size: 20),
                  )
                : suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 20, horizontal: 20), // increased height
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: isValid ? const Color(0xFFFFC107) : Colors.grey.shade300,
                width: isValid ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color:
                    isValid ? const Color(0xFFFFC107) : const Color(0xFFFFC107),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
