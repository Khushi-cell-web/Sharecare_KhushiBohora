import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared colors, spacing, and ThemeData for the app.
class AppTheme {
  AppTheme._();

  // Dark theme foundation
  static const Color backgroundDark = Color(0xFF121212); // or 0xFF0F1F1A
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDarker = Color(0xFF16231E); // dark green variation

  // Primary brand palette
  static const Color primaryGreen = Color(0xFF2ECC71); // main
  static const Color primaryGreenDark = Color(0xFF1B5E20); // slightly darker
  static const Color primaryGreenLight = Color(0xFF4EE48C);

  // Secondary accents
  static const Color accentYellow = Color(0xFFF4B400); // soft yellow
  static const Color accentBrown = Color(0xFF8D6E63); // warm brown
  static const Color accentTeal = Color(0xFF00796B); // dark teal depth
  static const Color accentOrange = Color(0xFFE65100); // muted orange

  /// Legacy names used by older screens.
  static const Color primaryTeal = accentTeal;
  static const Color primaryTealDark = Color(0xFF004D40);
  static const Color ctaOrange = accentOrange;
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color secondaryGreen = primaryGreen;
  static const Color accentPink = Color(0xFFEC407A);
  static const Color accentDark = Color(0xFF37474F);
  static const Color accentGreen = primaryGreen;
  static const Color pastelBlueDeep = Color(0xFF64B5F6);
  static const Color statusPendingPastel = Color(0xFFFFF8E1);
  static const Color statusVolunteerPastel = Color(0xFFE0F2F1);
  static const Color statusCompletedPastel = Color(0xFFE8F5E9);
  static const Color pastelMintLight = Color(0xFFF1F8E9);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDark = Color(0xFF121212); // for buttons

  // Status and chips
  static const Color chipUrgent = Color(0xFFE57373);
  static const Color chipFilter = primaryGreen;
  static const Color statusSuccess = Color(0xFF2ECC71);
  static const Color statusWarning = accentYellow;
  static const Color statusError = Color(0xFFE57373);

  static const Color navy = Color(0xFF587281);
  static const Color navyLight = Color(0xFF90A4AE);

  static const Color backgroundLight = Color(0xFFF0F4F8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color impactGreen = primaryGreenLight;

  static const Color roleDonorAccent = primaryGreen;
  static const Color roleVolunteerAccent = accentTeal;
  static const Color roleNgoAccent = accentYellow;

  static const Color appBarSurfaceLight = primaryGreen;
  static const Color appBarOnSurfaceLight = Colors.white;
  static const Color textTertiary = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF546E7A);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color surfaceLightGrey = Color(0xFFF5F8FA);

  // Category colors
  static const Color categoryFood = Color(0xFF1B5E20);
  static const Color categoryClothes = Color(0xFF00796B);
  static const Color categoryFunds = Color(0xFFF4B400);
  static const Color categoryBlood = Color(0xFF8D6E63);
  static const Color categoryOrgan = Color(0xFF37474F);

  static const Color categoryFoodIcon = Color(0xFF2ECC71);
  static const Color categoryClothesIcon = Color(0xFF009688);
  static const Color categoryFundsIcon = Color(0xFFFFD54F);
  static const Color categoryBloodIcon = Color(0xFFE53935);
  static const Color categoryOrganIcon = Color(0xFFB0BEC5);
  static const Color categoryOtherIcon = Color(0xFF4DB6AC);

  // Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // Border radius
  static const double radiusSm = 12.0;
  static const double radiusMd = 24.0;
  static const double radiusLg = 32.0;
  static const double radiusXl = 40.0;
  static const double radiusXxl = 48.0;

  // Elevation and shadows
  static const double elevationCard = 2.0;
  static const double elevationCardHover = 4.0;

  static const String mapTileUrlTemplate =
      'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';
  static const List<String> mapTileSubdomains = ['a', 'b', 'c', 'd'];

  // Shadow presets
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 14,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get deepShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 22,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> colorShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.22),
      blurRadius: 16,
      spreadRadius: -4,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get softGlow => [
    BoxShadow(
      color: primaryGreen.withOpacity(0.24),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];

  // Legacy solid colors for old references.
  static const Color headerSolid = primaryGreenDark;
  static const Color ctaSolid = primaryGreen;

  static ThemeData get lightTheme {
    return _buildTheme(
      ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),
      _buildTextTheme(textDark, textSecondary),
      backgroundLight,
      surfaceWhite,
      primaryGreen,
      textPrimary,
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(textPrimary, textSecondary);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primaryGreen,
          onPrimary: textDark,
          primaryContainer: primaryGreenDark,
          onPrimaryContainer: textPrimary,
          secondary: accentYellow,
          onSecondary: textDark,
          secondaryContainer: accentBrown,
          onSecondaryContainer: textPrimary,
          tertiary: accentTeal,
          onTertiary: textPrimary,
          surface: surfaceDark,
          onSurface: textPrimary,
          surfaceContainerHighest: surfaceDarker,
          error: statusError,
          onError: textPrimary,
          outline: Colors.white38,
        );

    return _buildTheme(
      colorScheme,
      textTheme,
      backgroundDark,
      surfaceDark,
      backgroundDark, // Match background to remove gradient appbars
      textPrimary,
    );
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
    Color bgColor,
    Color surfaceColor,
    Color appBarBg,
    Color appBarFg,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: appBarFg,
        ),
        iconTheme: IconThemeData(color: appBarFg, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: colorScheme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarBrightness: colorScheme.brightness,
          systemNavigationBarIconBrightness:
              colorScheme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: elevationCard,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: const EdgeInsets.symmetric(vertical: spaceSm, horizontal: 0),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.primary.withOpacity(0.35);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.8);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: spaceXl, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.primary.withOpacity(0.35);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.8);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: spaceXl, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceXl,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceLg,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        hintStyle: GoogleFonts.inter(color: textSecondary.withOpacity(0.7)),
      ),
      iconTheme: IconThemeData(color: textPrimary, size: 24),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        color: primaryColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.poppins(
        color: primaryColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.poppins(
        color: primaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.poppins(
        color: primaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.poppins(
        color: primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.inter(
        color: secondaryColor,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: GoogleFonts.inter(
        color: secondaryColor,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Compatibility gradients (using solid colors)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [primaryGreenDark, primaryGreenDark],
  );
  static const LinearGradient headerGradientWarm = LinearGradient(
    colors: [accentYellow, accentYellow],
  );
  static const LinearGradient ctaGradient = LinearGradient(
    colors: [primaryGreen, primaryGreen],
  );
  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
  );
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [accentTeal, accentTeal],
  );
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [accentBrown, accentBrown],
  );
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryGreenDark, primaryGreenDark],
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [primaryGreen, primaryGreen],
  );
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [accentYellow, accentYellow],
  );
  static const LinearGradient peachyGradient = LinearGradient(
    colors: [accentBrown, accentBrown],
  );
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [accentYellow, accentYellow],
  );
  static const LinearGradient purpleBlueGradient = LinearGradient(
    colors: [accentTeal, accentTeal],
  );
}
