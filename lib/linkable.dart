library linkable;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkable/constants.dart';
import 'package:linkable/emailParser.dart';
import 'package:linkable/httpParser.dart';
import 'package:linkable/link.dart';
import 'package:linkable/parser.dart';
import 'package:linkable/telParser.dart';
import 'package:url_launcher/url_launcher.dart';

class Linkable extends StatelessWidget {
  final String text;

  final textColor;

  final linkColor;

  List<Parser> _parsers = List<Parser>();
  List<Link> _links = List<Link>();

  Linkable({
    Key key,
    @required this.text,
    this.textColor = Colors.black,
    this.linkColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    init();
    return TextSpan(
        text: '',
        children: _getTextSpans(),
      );
  }

  _getTextSpans() {
    List<TextSpan> _textSpans = List<TextSpan>();
    int i = 0;
    int pos = 0;
    while (i < text.length) {
      _textSpans.add(_text(text.substring(
          i,
          pos < _links.length && i <= _links[pos].regExpMatch.start
              ? _links[pos].regExpMatch.start
              : text.length)));
      if (pos < _links.length && i <= _links[pos].regExpMatch.start) {
        _textSpans.add(_link(
            text.substring(
                _links[pos].regExpMatch.start, _links[pos].regExpMatch.end),
            _links[pos].type));
        i = _links[pos].regExpMatch.end;
        pos++;
      } else {
        i = text.length;
      }
    }
    return _textSpans;
  }

  _text(String text) {
    return TextSpan(text: text, style: TextStyle(color: textColor));
  }

  _link(String text, String type) {
    return TextSpan(
        text: text,
        style: TextStyle(color: linkColor),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _launch(_getUrl(text, type));
          });
  }

  _launch(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _getUrl(String text, String type) {
    switch (type) {
      case http:
        return text.substring(0, 4) == 'http' ? text : 'http://$text';
      case email:
        return text.substring(0, 7) == 'mailto:' ? text : 'mailto:$text';
      case tel:
        return text.substring(0, 4) == 'tel:' ? text : 'tel:$text';
      default:
        return text;
    }
  }

  init() {
    _addParsers();
    _parseLinks();
    _filterLinks();
  }

  _addParsers() {
    _parsers.add(EmailParser(text));
    _parsers.add(HttpParser(text));
    _parsers.add(TelParser(text));
  }

  _parseLinks() {
    for (Parser parser in _parsers) {
      _links.addAll(parser.parse().toList());
    }
  }

  _filterLinks() {
    _links.sort(
            (Link a, Link b) =>
            a.regExpMatch.start.compareTo(b.regExpMatch.start));

    List<Link> _filteredLinks = List<Link>();
    if (_links.length > 0) {
      _filteredLinks.add(_links[0]);
    }

    for (int i = 0; i < _links.length - 1; i++) {
      if (_links[i + 1].regExpMatch.start > _links[i].regExpMatch.end) {
        _filteredLinks.add(_links[i + 1]);
      }
    }
    _links = _filteredLinks;
  }
}
