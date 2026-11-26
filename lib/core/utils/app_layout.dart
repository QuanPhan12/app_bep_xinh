import 'package:flutter/material.dart';

/// Widths refer to logical pixels. Columns use their parent's available width.
class AppLayout {
  const AppLayout._();
  static const tabletBreakpoint = 600.0;
  static const splitBreakpoint = 840.0;
  static const pageMaxWidth = 1120.0;
  static const formMaxWidth = 720.0;
  static const compactMaxWidth = 440.0;
  static const sheetMaxWidth = 640.0;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;
  // Điện thoại xoay ngang vẫn cần bottom bar; chiều rộng riêng lẻ có thể vượt 600.
  static bool useNavigationRail(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= tabletBreakpoint;
  static double pageWidth(BuildContext context) =>
      isTablet(context) ? pageMaxWidth : compactMaxWidth;
  static double formWidth(BuildContext context) =>
      isTablet(context) ? formMaxWidth : compactMaxWidth;
  static double sheetWidth(BuildContext context) =>
      isTablet(context) ? sheetMaxWidth : compactMaxWidth;

  static int gridColumns(
    double width, {
    double minTileWidth = 210,
    double spacing = 16,
  }) => ((width + spacing) / (minTileWidth + spacing)).floor().clamp(2, 4);
}
