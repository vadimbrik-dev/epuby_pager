library epuby_pager;

import 'package:bookvar/bookvar.dart';
import 'package:epuby/epuby.dart';
import 'package:flutter/material.dart'
    show TextSpan, TextPainter, TextDirection;

typedef Page = List<Element>;

class PageSize {
  final double width;
  final double height;

  PageSize({required this.width, required this.height});
}

class Pager {
  final PageSize size;
  final BookRenderer renderer;

  Pager({required this.size, required this.renderer});

  List<Page> paginate(Chapter chapter) {
    List<Page> result = [[]];
    var accumulator = 0.0;

    for (final element in chapter) {
      final height = _calculateHeight(element);
      accumulator += height;

      if (accumulator > _maxHeight) {
        result.add([]);
        accumulator = height;
      }

      result.last.add(element);
    }

    return result;
  }

  double get _maxHeight => size.height - renderer.theme.padding.vertical;

  double _calculateHeight(Element element) {
    if (element is TextElement) {
      final style = renderer.getStyle(element);
      final span = TextSpan(text: element.content, style: style.textStyle);
      final paddings =
          renderer.theme.padding.horizontal + style.padding.horizontal;
      final painter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          textScaleFactor: renderer.theme.scaleFactor)
        ..layout(maxWidth: size.width - paddings);
      return painter.height + style.padding.vertical;
    }
    if (element is BlockElement) {
      final width = size.width - renderer.theme.padding.horizontal;
      final height = width / element.aspectRatio;
      return height;
    }
    throw Exception('Undefined element type');
  }
}
