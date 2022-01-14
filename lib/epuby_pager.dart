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
        final free = _maxHeight - (accumulator - height);

        if (element is TextElement) {
          final lineHeight = _calculateHeight(_copy(element, 'X'));

          if (free >= lineHeight) {
            final splitted = _splitElement(element, free);
            result.last.add(splitted.first);
            for (final fragment in splitted.sublist(1)) {
              result.add([]);
              result.last.add(fragment);
            }

            accumulator = _calculateHeight(splitted.last);
            continue;
          } else {
            if (height <= size.height) {
              result.add([]);
              result.last.add(element);
              accumulator = height;
              continue;
            } else {
              final splitted = _splitElement(element, size.height);

              for (final fragment in splitted) {
                result.add([]);
                result.last.add(fragment);
              }

              accumulator = _calculateHeight(splitted.last);
              continue;
            }
          }
        }
        result.add([]);
        accumulator = height;
      }

      result.last.add(element);
    }

    return result;
  }

  _copy(TextElement element, String content) {
    TextElement result;

    if (element is Header) {
      result = Header(content);
    } else {
      result = Paragraph(content);
    }

    return result;
  }

  List<TextElement> _splitElement(TextElement element, double free) {
    final result = _split(element, free);

    if (_calculateHeight(result.last) > size.height) {
      final temp = _splitElement(result.last, size.height);
      result.removeAt(result.length - 1);
      result.addAll(temp);
    }

    return result;
  }

  List<TextElement> _split(TextElement element, double free) {
    final words = element.content.split(' ');
    var result = '';

    for (final word in words) {
      final newString = '$result $word';
      final height = _calculateHeight(_copy(element, newString));

      if (height > free) {
        break;
      }

      result = newString.trim();
    }

    final first = _copy(element, result);
    final tailContent = element.content.substring(result.length);
    final second = _copy(element, tailContent);

    return [first, second];
  }

  double get _maxHeight => size.height - renderer.theme.padding.vertical;

  double _calculateHeight(Element element) {
    if (element is TextElement) {
      final style = renderer.getStyle(element);
      final span = TextSpan(text: element.content, style: style.textStyle);
      final painter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          textScaleFactor: renderer.theme.scaleFactor)
        ..layout(maxWidth: size.width);
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
