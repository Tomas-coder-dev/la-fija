import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? Colors.redAccent.shade700 : const Color(0xFF18E797), // Premium green or red
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.redAccent : const Color(0xFF18E797)).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.only(bottom: 30, left: 24, right: 24),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
