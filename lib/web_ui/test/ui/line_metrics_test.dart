// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(
    withImplicitView: true,
    setUpTestViewDimensions: false,
  );

  test('empty paragraph', () {
    const double fontSize = 10.0;
    final ui.Paragraph paragraph = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: fontSize,
    )).build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(paragraph.getLineMetricsAt(0), isNull);
    expect(paragraph.numberOfLines, 0);
    expect(paragraph.getLineNumberAt(0), isNull);
  }, skip: isHtml); // https://github.com/flutter/flutter/issues/144412

  test('Basic line related metrics', () {
    const double fontSize = 10;
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontStyle: ui.FontStyle.normal,
      fontWeight: ui.FontWeight.normal,
      fontSize: fontSize,
      maxLines: 1,
      ellipsis: 'BBB',
    ))..addText('A' * 100);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 100.0));

    expect(paragraph.numberOfLines, 1);

    expect(paragraph.getLineMetricsAt(-1), isNull);
    expect(paragraph.getLineMetricsAt(0)?.lineNumber, 0);
    expect(paragraph.getLineMetricsAt(1), isNull);

    expect(paragraph.getLineNumberAt(-1), isNull);
    expect(paragraph.getLineNumberAt(0), 0);
    expect(paragraph.getLineNumberAt(6), 0);
    // The last 3 characters on the first line are ellipsized with BBB.
    expect(paragraph.getLineMetricsAt(7), isNull);
  });

  test('Basic glyph metrics', () {
    const double fontSize = 10;
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontStyle: ui.FontStyle.normal,
      fontWeight: ui.FontWeight.normal,
      fontFamily: 'FlutterTest',
      fontSize: fontSize,
      maxLines: 1,
      ellipsis: 'BBB',
    ))..addText('A' * 100);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 100.0));

    expect(paragraph.getGlyphInfoAt(-1), isNull);

    // The last 3 characters on the first line are ellipsized with BBB.
    expect(paragraph.getGlyphInfoAt(0)?.graphemeClusterCodeUnitRange, const ui.TextRange(start: 0, end: 1));
    expect(paragraph.getGlyphInfoAt(6)?.graphemeClusterCodeUnitRange, const ui.TextRange(start: 6, end: 7));
    expect(paragraph.getGlyphInfoAt(7), isNull);
    expect(paragraph.getGlyphInfoAt(200), isNull);
  });

  test('Basic glyph metrics - hit test', () {
    const double fontSize = 10.0;
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: fontSize,
      fontFamily: 'FlutterTest',
    ))..addText('Test\nTest');
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final ui.GlyphInfo? bottomRight = paragraph.getClosestGlyphInfoForOffset(const ui.Offset(99.0, 99.0));
    final ui.GlyphInfo? last = paragraph.getGlyphInfoAt(8);
    expect(bottomRight, equals(last));
    expect(bottomRight, isNot(paragraph.getGlyphInfoAt(0)));

    expect(bottomRight?.graphemeClusterLayoutBounds, const ui.Rect.fromLTWH(30, 10, 10, 10));
    expect(bottomRight?.graphemeClusterCodeUnitRange, const ui.TextRange(start: 8, end: 9));
    expect(bottomRight?.writingDirection, ui.TextDirection.ltr);
  });

  test('rounding hack is always disabled', () {
    const double fontSize = 1.25;
    const String text = '12345';
    assert((fontSize * text.length).truncate() != fontSize * text.length);
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: fontSize, fontFamily: 'FlutterTest'),
    );
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: text.length * fontSize));

    expect(paragraph.maxIntrinsicWidth, text.length * fontSize);
    switch (paragraph.computeLineMetrics()) {
      case [ui.LineMetrics(width: final double width)]:
        expect(width, text.length * fontSize);
      case final List<ui.LineMetrics> metrics:
        expect(metrics, hasLength(1));
    }
  }, skip: isHtml); // The rounding hack doesn't apply to the html renderer
}
