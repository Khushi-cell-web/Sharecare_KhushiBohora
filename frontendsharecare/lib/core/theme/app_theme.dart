import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared colors, spacing, and ThemeData for the app.
class AppTheme {
  AppTheme._();

  static ThemeMode _activeThemeMode = ThemeMode.light;

  static void setActiveThemeMode(ThemeMode mode) {
    _activeThemeMode = mode;
  }

  static bool get _useDarkPalette {
    if (_activeThemeMode == ThemeMode.dark) {
      return true;
    }
    if (_activeThemeMode == ThemeMode.light) {
      return false;
    }
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  // Dark theme foundation
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color surfaceDark = Color(0xFF172238);
  static const Color surfaceDarker = Color(0xFF223149);
  static const Color darkBlue = Color(0xFF6EA8FE);
  static const Color darkBlueDeep = Color(0xFF2F5AA8);
  static const Color darkBlueSoft = Color(0xFF9FC2FF);

  // Donation History pink palette (source of truth for global theming)
  static const Color _primaryPinkColorLight = Color(0xFFFFC1CC);
  static const Color _primaryPinkLightLight = Color(0xFFFFEEF3);
  static const Color _primaryPinkSoftLight = Color(0xFFFFD9E2);
  static const Color _primaryPinkDarkLight = Color(0xFF8A4E5E);
  static const Color _primaryPinkMutedLight = Color(0xFFB07A88);

  static Color get primaryPinkColor =>
      _useDarkPalette ? darkBlue : _primaryPinkColorLight;
  static Color get primaryPinkLight =>
      _useDarkPalette ? const Color(0xFF1A2740) : _primaryPinkLightLight;
  static Color get primaryPinkSoft =>
      _useDarkPalette ? const Color(0xFF264069) : _primaryPinkSoftLight;
  static Color get primaryPinkDark =>
      _useDarkPalette ? darkBlueDeep : _primaryPinkDarkLight;
  static Color get primaryPinkMuted =>
      _useDarkPalette ? darkBlueSoft : _primaryPinkMutedLight;

  // Legacy aliases used throughout existing screens.
  static Color get primaryGreen => _useDarkPalette ? darkBlue : primaryPinkColor;
  static Color get primaryGreenDark =>
      _useDarkPalette ? darkBlueDeep : primaryPinkDark;
  static Color get primaryGreenLight =>
      _useDarkPalette ? darkBlueSoft : primaryPinkSoft;

  // Secondary accents
  static const Color accentYellow = Color(0xFFF4B400); // soft yellow
  static const Color accentBrown = Color(0xFF8D6E63); // warm brown
  static Color get accentTeal =>
      _useDarkPalette ? darkBlueSoft : primaryPinkMuted;
  static const Color accentOrange = Color(0xFFE65100); // muted orange

  /// Legacy names used by older screens.
  static Color get primaryTeal => primaryGreen;
  static Color get primaryTealDark => primaryGreenDark;
  static const Color ctaOrange = accentOrange;
  static const Color accentPurple = Color(0xFF9C27B0);
  static Color get secondaryGreen => primaryGreen;
  static const Color accentPink = Color(0xFFEC407A);
  static const Color accentDark = Color(0xFF37474F);
  static Color get accentGreen => primaryGreen;
  static const Color pastelBlueDeep = Color(0xFF64B5F6);
  static const Color statusPendingPastel = Color(0xFFFFF8E1);
  static Color get statusVolunteerPastel => primaryPinkLight;
  static Color get statusCompletedPastel => primaryPinkLight;
  static Color get pastelMintLight => primaryPinkLight;

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDark = Color(0xFF121212); // for buttons

  // Status and chips
  static const Color chipUrgent = Color(0xFFE57373);
  static Color get chipFilter => primaryGreenDark;
  static Color get statusSuccess => primaryGreenDark;
  static const Color statusWarning = accentYellow;
  static const Color statusError = Color(0xFFE57373);

  static const Color navy = Color(0xFF587281);
  static const Color navyLight = Color(0xFF90A4AE);

  static const Color _backgroundLight = Color(0xFFF0F4F8);
  static const Color _surfaceWhite = Color(0xFFFFFFFF);
  static Color get backgroundLight =>
      _useDarkPalette ? backgroundDark : _backgroundLight;
  static Color get surfaceWhite => _useDarkPalette ? surfaceDark : _surfaceWhite;
  static Color get impactGreen => primaryGreenLight;

  static Color get roleDonorAccent => primaryGreen;
  static Color get roleVolunteerAccent => accentTeal;
  static const Color roleNgoAccent = accentYellow;

  static Color get appBarSurfaceLight => primaryGreen;
  static Color get appBarOnSurfaceLight =>
      _useDarkPalette ? Colors.white : primaryPinkDark;
  static const Color textTertiary = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF546E7A);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color surfaceLightGrey = Color(0xFFF5F8FA);

  // Category colors
  static Color get categoryFood => primaryGreenDark;
  static Color get categoryClothes => accentTeal;
  static const Color categoryFunds = Color(0xFFF4B400);
  static const Color categoryBlood = Color(0xFF8D6E63);
  static const Color categoryOrgan = Color(0xFF37474F);

  static Color get categoryFoodIcon => primaryGreenDark;
  static Color get categoryClothesIcon => accentTeal;
  static const Color categoryFundsIcon = Color(0xFFFFD54F);
  static const Color categoryBloodIcon = Color(0xFFE53935);
  static const Color categoryOrganIcon = Color(0xFFB0BEC5);
  static Color get categoryOtherIcon => accentTeal;

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
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 14,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get deepShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 22,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> colorShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.22),
      blurRadius: 16,
      spreadRadius: -4,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get softGlow => [
    BoxShadow(
      color: primaryPinkColor.withValues(alpha: 0.24),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];

  // Legacy solid colors for old references.
  static Color get headerSolid => primaryGreenDark;
  static Color get ctaSolid => primaryGreen;

  static ThemeData get lightTheme {
    return _buildTheme(
      ColorScheme.fromSeed(
        seedColor: _primaryPinkColorLight,
        brightness: Brightness.light,
      ),
      _buildTextTheme(textDark, textSecondary),
      _backgroundLight,
      _surfaceWhite,
      _primaryPinkColorLight,
      _primaryPinkDarkLight,
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(textPrimary, const Color(0xFFB8C5DB));
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: darkBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: darkBlue,
          onPrimary: Colors.white,
          primaryContainer: darkBlueDeep,
          onPrimaryContainer: Colors.white,
          secondary: darkBlueSoft,
          onSecondary: backgroundDark,
          secondaryContainer: const Color(0xFF203152),
          onSecondaryContainer: Colors.white,
          tertiary: const Color(0xFF74B4FF),
          onTertiary: Colors.white,
          surface: surfaceDark,
          onSurface: textPrimary,
          surfaceContainerHighest: surfaceDarker,
          error: statusError,
          onError: Colors.white,
          outline: const Color(0xFF4A5C79),
        );

    return _buildTheme(
      colorScheme,
      textTheme,
      backgroundDark,
      surfaceDark,
      colorScheme.primaryContainer,
      Colors.white,
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
      primaryColor: colorScheme.primary,
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
              return colorScheme.primary.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.8);
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
              return colorScheme.primary.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.8);
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
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.primary.withValues(alpha: 0.5);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.8);
            }
            return colorScheme.primary;
          }),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
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
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
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
        hintStyle: GoogleFonts.inter(
          color: textSecondary.withValues(alpha: 0.7),
        ),
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
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.18),
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
  static LinearGradient get headerGradient => LinearGradient(
    colors: [primaryGreenDark, primaryGreenDark],
  );
  static LinearGradient get headerGradientWarm => const LinearGradient(
    colors: [accentYellow, accentYellow],
  );
  static LinearGradient get ctaGradient => LinearGradient(
    colors: [primaryGreen, primaryGreen],
  );
  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
  );
  static LinearGradient get purpleGradient => LinearGradient(
    colors: [accentTeal, accentTeal],
  );
  static LinearGradient get pinkGradient => const LinearGradient(
    colors: [accentBrown, accentBrown],
  );
  static LinearGradient get blueGradient => LinearGradient(
    colors: [primaryGreenDark, primaryGreenDark],
  );
  static LinearGradient get greenGradient => LinearGradient(
    colors: [primaryGreen, primaryGreen],
  );
  static LinearGradient get sunsetGradient => const LinearGradient(
    colors: [accentYellow, accentYellow],
  );
  static LinearGradient get peachyGradient => const LinearGradient(
    colors: [accentBrown, accentBrown],
  );
  static LinearGradient get orangeGradient => const LinearGradient(
    colors: [accentYellow, accentYellow],
  );
  static LinearGradient get purpleBlueGradient => LinearGradient(
    colors: [accentTeal, accentTeal],
  );
}
