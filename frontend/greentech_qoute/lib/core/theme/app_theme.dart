import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App theme configuration
class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF81C784);

  // Status Colors
  static const Color pendingColor = Color(0xFFFF9800);
  static const Color approvedColor = Color(0xFF4CAF50);
  static const Color rejectedColor = Color(0xFFF44336);
  static const Color expiredColor = Color(0xFF9E9E9E);

  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Text Colors
  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);
  static const Color hintText = Color(0xFF9E9E9E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        primaryContainer: accentGreen,
        onPrimaryContainer: darkGreen,
        secondary: lightGreen,
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: primaryText,
        error: rejectedColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: surfaceColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: rejectedColor),
        ),
        labelStyle: const TextStyle(color: secondaryText),
        hintStyle: const TextStyle(color: hintText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: primaryGreen),
          foregroundColor: primaryGreen,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 32,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dividerColor,
        selectedColor: accentGreen,
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
    );
  }

  /// Get status color based on quote status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return approvedColor;
      case 'rejected':
        return rejectedColor;
      case 'expired':
        return expiredColor;
      case 'pending':
      default:
        return pendingColor;
    }
  }

  /// Get status background color
  static Color getStatusBackgroundColor(String status) {
    final color = getStatusColor(status);
    return color.withOpacity(0.15);
  }
}

/// Typography styles
class AppTypography {
  AppTypography._();

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryText,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryText,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryText,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryText,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryText,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppTheme.primaryText,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppTheme.primaryText,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppTheme.secondaryText,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.secondaryText,
  );

  static const TextStyle currencyLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryGreen,
  );

  static const TextStyle currencyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryGreen,
  );
}

/// Spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: lg);
}
