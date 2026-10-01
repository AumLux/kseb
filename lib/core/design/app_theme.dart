import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

/// Builds the app-wide [ThemeData] from DESIGN.md tokens.
///
/// Material components pick up the design language from here, so most
/// screens need no per-widget styling.
abstract final class AppTheme {
  static ThemeData light({Locale? locale}) {
    final isMalayalam = locale?.languageCode == 'ml';
    TextStyle t(TextStyle s) =>
        isMalayalam ? AppTypography.forMalayalam(s) : s;

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.ink,
      onSecondary: AppColors.onDark,
      secondaryContainer: AppColors.canvasSunken,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.brandDark,
      onTertiary: AppColors.onDark,
      error: AppColors.danger,
      onError: AppColors.onDark,
      errorContainer: AppColors.dangerBg,
      onErrorContainer: AppColors.danger,
      surface: AppColors.canvas,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMute,
      surfaceContainerLowest: AppColors.canvas,
      surfaceContainerLow: AppColors.canvasSoft,
      surfaceContainer: AppColors.canvasSoft,
      surfaceContainerHigh: AppColors.canvasSunken,
      surfaceContainerHighest: AppColors.canvasSunken,
      outline: AppColors.borderInput,
      outlineVariant: AppColors.hairline,
      shadow: Color(0x14003770),
      scrim: AppColors.scrim,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.onDark,
      inversePrimary: AppColors.primary,
    );

    final textTheme = TextTheme(
      displaySmall: t(AppTypography.display),
      headlineSmall: t(AppTypography.headline),
      titleLarge: t(AppTypography.title),
      titleMedium: t(AppTypography.subtitle),
      titleSmall: t(AppTypography.bodyStrong),
      bodyLarge: t(AppTypography.body),
      bodyMedium: t(AppTypography.body),
      bodySmall: t(AppTypography.caption),
      labelLarge: t(AppTypography.button),
      labelMedium: t(AppTypography.label),
      labelSmall: t(AppTypography.overline),
    );

    const pill = StadiumBorder();
    final buttonText = t(AppTypography.button);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvasSoft,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFallback,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: t(AppTypography.title),
        shape: const Border(bottom: BorderSide(color: AppColors.hairline)),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.canvas,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.canvasSunken,
          disabledForegroundColor: AppColors.inkDisabled,
          minimumSize: const Size(64, AppSizes.primaryActionHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: pill,
          textStyle: buttonText,
          elevation: 0,
        ).copyWith(
          overlayColor: const WidgetStatePropertyAll(Color(0x1F0D253D)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, AppSizes.primaryActionHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: pill,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.canvas,
          minimumSize: const Size(64, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: const BorderSide(color: AppColors.borderInput),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryInk,
          minimumSize: const Size(48, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: pill,
          textStyle: t(AppTypography.label),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.square(AppSizes.minTouchTarget),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md + 2,
        ),
        border: inputBorder(AppColors.borderInput),
        enabledBorder: inputBorder(AppColors.borderInput),
        focusedBorder: inputBorder(AppColors.focusRing, 2),
        errorBorder: inputBorder(AppColors.danger, 2),
        focusedErrorBorder: inputBorder(AppColors.danger, 2),
        disabledBorder: inputBorder(AppColors.hairline),
        labelStyle: t(AppTypography.label).copyWith(color: AppColors.inkMute),
        floatingLabelStyle:
            t(AppTypography.label).copyWith(color: AppColors.primaryInk),
        hintStyle: t(AppTypography.body).copyWith(color: AppColors.inkMute),
        helperStyle: t(AppTypography.caption),
        errorStyle: t(AppTypography.caption).copyWith(color: AppColors.danger),
        prefixIconColor: AppColors.inkMute,
        suffixIconColor: AppColors.inkMute,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.canvas,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.hairline),
        shape: const StadiumBorder(),
        labelStyle: t(AppTypography.label),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.md,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        titleTextStyle: t(AppTypography.bodyStrong),
        subtitleTextStyle: t(AppTypography.caption),
        iconColor: AppColors.inkMute,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        height: 72,
        indicatorColor: AppColors.primary,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.onPrimary
                  : AppColors.inkMute,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            t(AppTypography.label).copyWith(
              color: states.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.inkMute,
            )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.canvas,
        indicatorColor: AppColors.primary,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: const IconThemeData(color: AppColors.onPrimary),
        unselectedIconTheme: const IconThemeData(color: AppColors.inkMute),
        selectedLabelTextStyle: t(AppTypography.label),
        unselectedLabelTextStyle:
            t(AppTypography.label).copyWith(color: AppColors.inkMute),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.hairline,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: t(AppTypography.subtitle),
        contentTextStyle: t(AppTypography.body),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle:
            t(AppTypography.label).copyWith(color: AppColors.onDark),
        actionTextColor: AppColors.primary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.canvasSunken,
        circularTrackColor: AppColors.canvasSunken,
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: AppColors.borderInput, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.ink : null),
        checkColor: const WidgetStatePropertyAll(AppColors.onDark),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.canvasSunken),
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.onPrimary
                : AppColors.borderInput),
        trackOutlineColor:
            const WidgetStatePropertyAll(AppColors.borderInput),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.ink,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: t(AppTypography.caption).copyWith(color: AppColors.onDark),
      ),
    );
  }
}
