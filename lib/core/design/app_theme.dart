import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'motion/motion.dart';

/// Builds the app-wide [ThemeData] from DESIGN.md tokens.
///
/// Material components pick up the design language from here, so most
/// screens need no per-widget styling.
abstract final class AppTheme {
  static final _cache = <bool, ThemeData>{};

  /// Built once per script (Latin / Malayalam), not on every app rebuild.
  static ThemeData light({Locale? locale}) {
    final isMalayalam = locale?.languageCode == 'ml';
    return _cache.putIfAbsent(isMalayalam, () => _build(isMalayalam));
  }

  static ThemeData _build(bool isMalayalam) {
    TextStyle t(TextStyle s) => isMalayalam ? AppTypography.forMalayalam(s) : s;

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.ink,
      onSecondary: AppColors.onDark,
      secondaryContainer: AppColors.canvasSunken,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.brandOrange,
      onTertiary: AppColors.ink,
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
      inversePrimary: AppColors.lavender,
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

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: color, width: width),
        );

    WidgetStateProperty<Color> pressable(Color normal, Color pressed, Color disabled) =>
        WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled)
            ? disabled
            : s.contains(WidgetState.pressed)
                ? pressed
                : normal);

    const transitions = AppPageTransitions();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFallback,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      // InkSparkle compiles a shader and costs more per tap; ripple is instant.
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: transitions,
        TargetPlatform.iOS: transitions,
        TargetPlatform.windows: transitions,
        TargetPlatform.macOS: transitions,
        TargetPlatform.linux: transitions,
        TargetPlatform.fuchsia: transitions,
      }),
      dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: t(AppTypography.title),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.canvas,
          systemNavigationBarIconBrightness: Brightness.dark,
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
          foregroundColor: AppColors.onPrimary,
          disabledForegroundColor: AppColors.inkDisabled,
          minimumSize: const Size(64, AppSizes.primaryActionHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: pill,
          textStyle: buttonText,
          elevation: 0,
        ).copyWith(
          backgroundColor: pressable(AppColors.primary, AppColors.primaryPress, AppColors.canvasSunken),
          overlayColor: const WidgetStatePropertyAll(Color(0x14FFFFFF)),
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
          foregroundColor: AppColors.primaryDeep,
          backgroundColor: AppColors.canvas,
          minimumSize: const Size(64, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: const BorderSide(color: AppColors.primary),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          minimumSize: const Size(48, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: pill,
          textStyle: t(AppTypography.label).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.square(AppSizes.minTouchTarget),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        // A soft lift so the FAB reads as floating above lists.
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: const StadiumBorder(),
        extendedTextStyle: t(AppTypography.button).copyWith(fontSize: 15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        border: inputBorder(AppColors.borderInput),
        enabledBorder: inputBorder(AppColors.borderInput),
        focusedBorder: inputBorder(AppColors.focusRing, 2),
        errorBorder: inputBorder(AppColors.danger, 2),
        focusedErrorBorder: inputBorder(AppColors.danger, 2),
        disabledBorder: inputBorder(AppColors.hairline),
        labelStyle: t(AppTypography.label).copyWith(color: AppColors.inkMute),
        floatingLabelStyle: t(AppTypography.label).copyWith(color: AppColors.primaryDeep),
        hintStyle: t(AppTypography.body).copyWith(color: AppColors.inkMute),
        helperStyle: t(AppTypography.caption),
        errorStyle: t(AppTypography.caption).copyWith(color: AppColors.danger),
        prefixIconColor: AppColors.inkMute,
        suffixIconColor: AppColors.inkMute,
      ),
      // Groww-style filter pills: selected = ink pill with white text, no
      // checkmark; unselected = white with a hairline.
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.ink : AppColors.canvas),
        side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
            color: s.contains(WidgetState.selected) ? AppColors.ink : AppColors.hairline)),
        showCheckmark: false,
        checkmarkColor: AppColors.onDark,
        shape: const StadiumBorder(),
        // Chips resolve the label *colour* by state (not the whole style).
        labelStyle: t(AppTypography.label).copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColors.onDark : AppColors.inkSecondary),
        ),
        iconTheme: const IconThemeData(size: 18, color: AppColors.inkSecondary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        pressElevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.inkMute,
        labelStyle: t(AppTypography.label).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: t(AppTypography.label).copyWith(fontSize: 15, fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
        dividerColor: AppColors.hairline,
        overlayColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.06)),
        splashFactory: NoSplash.splashFactory,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.md,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        titleTextStyle: t(AppTypography.bodyStrong),
        subtitleTextStyle: t(AppTypography.caption),
        iconColor: AppColors.inkMute,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primarySoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? AppColors.primaryDeep : AppColors.inkMute,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => t(AppTypography.label).copyWith(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? AppColors.ink : AppColors.inkMute,
            )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.canvas,
        indicatorColor: AppColors.primarySoft,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: const IconThemeData(color: AppColors.primaryDeep),
        unselectedIconTheme: const IconThemeData(color: AppColors.inkMute),
        selectedLabelTextStyle: t(AppTypography.label).copyWith(fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: t(AppTypography.label).copyWith(color: AppColors.inkMute),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderInput,
        dragHandleSize: Size(36, 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: t(AppTypography.title),
        contentTextStyle: t(AppTypography.body),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        elevation: 0,
        contentTextStyle: t(AppTypography.label).copyWith(color: AppColors.onDark),
        actionTextColor: AppColors.lavender,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySoft,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: AppColors.canvas,
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: AppColors.borderInput, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.borderInput),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.canvasSunken),
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.borderInput),
        trackOutlineColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.borderInput),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.canvas,
          selectedBackgroundColor: AppColors.primarySoft,
          selectedForegroundColor: AppColors.primaryDeep,
          foregroundColor: AppColors.inkSecondary,
          side: const BorderSide(color: AppColors.hairline),
          textStyle: t(AppTypography.label),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(color: AppColors.ink, borderRadius: AppRadius.smAll),
        textStyle: t(AppTypography.caption).copyWith(color: AppColors.onDark),
      ),
    );
  }
}
