import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _bg = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF141414);
  static const _card = Color(0xFF1C1C1C);
  static const _border = Color(0xFF272727);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xFF888888);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: Color(0xFF6B35FF),
          surface: _surface,
          onPrimary: Color(0xFF0A0A0A),
          onSurface: Colors.white,
          error: AppColors.expense,
        ),
        scaffoldBackgroundColor: _bg,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
              color: _textPrimary, fontWeight: FontWeight.w900, letterSpacing: -2),
          headlineLarge: GoogleFonts.inter(
              color: _textPrimary, fontWeight: FontWeight.w800, letterSpacing: -1),
          titleLarge: GoogleFonts.inter(
              color: _textPrimary, fontWeight: FontWeight.w700),
          bodyLarge: GoogleFonts.inter(color: _textPrimary),
          bodyMedium: GoogleFonts.inter(color: _textSecondary),
          labelLarge: GoogleFonts.inter(
              color: _textPrimary, fontWeight: FontWeight.w700),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
          iconTheme: const IconThemeData(color: _textPrimary),
          actionsIconTheme: const IconThemeData(color: _textPrimary),
        ),
        cardTheme: CardThemeData(
          color: _card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.expense),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
          ),
          labelStyle: const TextStyle(color: _textSecondary),
          hintStyle: const TextStyle(color: _textSecondary),
          prefixIconColor: _textSecondary,
          errorStyle: const TextStyle(color: AppColors.expense),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _textPrimary,
            side: const BorderSide(color: _border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          shape: CircleBorder(),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _surface,
          indicatorColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF0A0A0A), size: 22);
            }
            return const IconThemeData(color: _textSecondary, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected) ? Colors.white : _textSecondary,
            );
          }),
          height: 72,
        ),
        dividerTheme: const DividerThemeData(
          color: _border,
          thickness: 1,
          space: 0,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: _textSecondary,
          textColor: _textPrimary,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? const Color(0xFF0A0A0A) : _textSecondary,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.accent : _border,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.accent : Colors.transparent,
          ),
          checkColor: WidgetStateProperty.all(const Color(0xFF0A0A0A)),
          side: const BorderSide(color: _border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.accent,
          linearTrackColor: _border,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _card,
          contentTextStyle: GoogleFonts.inter(color: _textPrimary, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titleTextStyle: GoogleFonts.inter(
              color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          contentTextStyle: GoogleFonts.inter(color: _textSecondary, fontSize: 14),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _border),
          ),
          textStyle: GoogleFonts.inter(color: _textPrimary, fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _card,
          selectedColor: Colors.white,
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(_card),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _border),
              ),
            ),
          ),
        ),
      );

  // Light mantido como fallback mas nunca usado
  static ThemeData get light => dark;
}
