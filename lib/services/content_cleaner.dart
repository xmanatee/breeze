import 'package:html/parser.dart' as html_parser;

class ContentCleaner {
  static String cleanHtmlContent(final String htmlContent,
      {final int maxLength = 15000}) {
    final document = html_parser.parse(htmlContent);

    document
        .querySelectorAll(
            'script, style, iframe, noscript, img, video, audio, embed, object, canvas')
        .forEach((final element) {
      element.remove();
    });

    document
        .querySelectorAll('[class*="advert"], [id*="advert"]')
        .forEach((final element) {
      element.remove();
    });

    document.querySelectorAll('*').forEach((final element) {
      if (element.localName == 'a' ||
          element.localName == 'button' ||
          element.localName == 'input' ||
          element.localName == 'select' ||
          element.localName == 'textarea') {
        element.attributes.removeWhere(
            (final attr, final value) => attr != 'class' && attr != 'id');
      } else {
        element.attributes.clear();
      }
    });

    var cleanedHtmlContent = document.body?.outerHtml ?? '';
    cleanedHtmlContent =
        cleanedHtmlContent.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleanedHtmlContent.length > maxLength) {
      cleanedHtmlContent = cleanedHtmlContent.substring(0, maxLength);
    }

    return cleanedHtmlContent;
  }
}
