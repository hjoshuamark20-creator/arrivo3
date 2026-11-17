import 'package:flutter/material.dart';

import 'constants.dart';

bool isDarkTheme(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// Secondary text color that works on glass in both themes.
Color mutedColor(BuildContext context) =>
    isDarkTheme(context) ? AppColors.slateLight : AppColors.slate;

/// Fill used for rows and fields that sit inside a glass card.
Color rowFill(BuildContext context) =>
    isDarkTheme(context) ? const Color(0x14FFFFFF) : const Color(0x73FFFFFF);

Color glassBorder(BuildContext context) =>
    isDarkTheme(context) ? AppColors.glassBorderDark : AppColors.glassBorderLight;
