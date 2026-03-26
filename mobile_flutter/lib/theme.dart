import 'package:flutter/material.dart';
const ecoGreen = Color(0xFF0B6E4F);
const ecoBlue  = Color(0xFF0B79C9);
final ecoTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: ecoGreen).copyWith(primary: ecoGreen, secondary: ecoBlue),
  useMaterial3: true,
);
