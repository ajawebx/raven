String getAsSearchQuery(String category) {
  if (category.startsWith("#")) {
    category = category.replaceFirst("#", "");
  }
  return category;
}

String createTag(String inputString) {
  RegExp specialChars = RegExp(r'[^\w\s]', multiLine: true);
  String tag = inputString.replaceAll(specialChars, '').toLowerCase();
  return tag;
}

bool isNumeric(String str) {
  return double.tryParse(str) != null;
}

String findStringBetween(String text, String start, String end) {
  text = text.replaceAll(RegExp("\\s+"), " ");
  int startIndex = text.indexOf(start);
  int endIndex = text.indexOf(end, startIndex + start.length);

  if (startIndex != -1 && endIndex != -1) {
    return text.substring(startIndex + start.length, endIndex);
  } else {
    return "";
  }
}
