import 'package:flutter/widgets.dart';
import 'package:scripture/scripture_core.dart'; // for ParagraphFormat

class UsfmParagraphStyle {
  final TextStyle textStyle;
  final TextStyle verseNumberStyle;
  final TextAlign textAlign;
  final double firstLineIndent;
  final double subsequentLinesIndent;
  final bool selectable;

  const UsfmParagraphStyle({
    required this.textStyle,
    TextStyle? verseNumberStyle,
    this.textAlign = TextAlign.start,
    this.firstLineIndent = 0.0,
    this.subsequentLinesIndent = 0.0,
    this.selectable = true,
  }) : verseNumberStyle = verseNumberStyle ?? textStyle;

  /// Creates a style based on standard USFM layout rules.
  ///
  /// [baseStyle] is the font/color you want to use for standard text.
  factory UsfmParagraphStyle.usfmDefaults({
    required ParagraphFormat format,
    required TextStyle baseStyle,
  }) {
    // 1. Derive Font Styles
    TextStyle style = baseStyle;
    TextStyle verseStyle = baseStyle.copyWith(
      color: baseStyle.color?.withValues(alpha: 0.6),
      fontSize: baseStyle.fontSize,
    );

    bool isSelectable = true;

    switch (format) {
      case ParagraphFormat.qr:
      case ParagraphFormat.d:
      case ParagraphFormat.r:
      case ParagraphFormat.s2:
        style = baseStyle.copyWith(fontStyle: FontStyle.italic);
      case ParagraphFormat.qa:
      case ParagraphFormat.s1:
        style = baseStyle.copyWith(fontWeight: FontWeight.bold);
      case ParagraphFormat.ms:
      case ParagraphFormat.ms1:
        style = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 14) * 1.5,
          fontWeight: FontWeight.bold,
        );
      case ParagraphFormat.ms2:
        style = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 14) * 1.2,
          fontWeight: FontWeight.bold,
        );
      case ParagraphFormat.mr:
        style = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 14) * 1.2,
          fontStyle: FontStyle.italic,
          color: baseStyle.color?.withValues(alpha: 0.6),
        );
      case ParagraphFormat.p:
      case ParagraphFormat.m:
      case ParagraphFormat.b:
      case ParagraphFormat.q1:
      case ParagraphFormat.q2:
      case ParagraphFormat.pmo:
      case ParagraphFormat.li1:
      case ParagraphFormat.li2:
      case ParagraphFormat.pc:
        // use base style
        break;
    }

    if (!format.isBiblicalText) {
      isSelectable = false;
    }

    // 2. Derive Layout (Alignment & Indents)
    TextAlign align = TextAlign.start;
    double indent1 = 0.0;
    double indent2 = 0.0;

    switch (format) {
      case ParagraphFormat.pc:
      case ParagraphFormat.d:
      case ParagraphFormat.r:
      case ParagraphFormat.mr:
      case ParagraphFormat.ms:
      case ParagraphFormat.ms1:
      case ParagraphFormat.ms2:
        align = TextAlign.center;
      case ParagraphFormat.qr:
        align = TextAlign.right;
      case ParagraphFormat.pmo:
        indent1 = 20.0;
        indent2 = 20.0;
      case ParagraphFormat.q1:
      case ParagraphFormat.li1:
        indent1 = 20.0;
        indent2 = 100.0;
      case ParagraphFormat.q2:
      case ParagraphFormat.li2:
        indent1 = 60.0;
        indent2 = 100.0;
      case ParagraphFormat.p:
        indent1 = 20.0;
      case ParagraphFormat.m:
      case ParagraphFormat.b:
      case ParagraphFormat.s1:
      case ParagraphFormat.s2:
      case ParagraphFormat.qa:
        // use default alignment and indents
        break;
    }

    return UsfmParagraphStyle(
      textStyle: style,
      verseNumberStyle: verseStyle,
      textAlign: align,
      firstLineIndent: indent1,
      subsequentLinesIndent: indent2,
      selectable: isSelectable,
    );
  }

  UsfmParagraphStyle copyWith({
    TextStyle? textStyle,
    TextStyle? verseNumberStyle,
    TextAlign? textAlign,
    double? firstLineIndent,
    double? subsequentLinesIndent,
    bool? selectable,
  }) {
    return UsfmParagraphStyle(
      textStyle: textStyle ?? this.textStyle,
      verseNumberStyle: verseNumberStyle ?? this.verseNumberStyle,
      textAlign: textAlign ?? this.textAlign,
      firstLineIndent: firstLineIndent ?? this.firstLineIndent,
      subsequentLinesIndent:
          subsequentLinesIndent ?? this.subsequentLinesIndent,
      selectable: selectable ?? this.selectable,
    );
  }
}
