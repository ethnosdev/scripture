final _punctuationRegex = RegExp(r'^[\p{P}\p{S}]+$', unicode: true);

/// Returns true if [text] consists entirely of punctuation or symbol characters.
bool isPunctuation(String text) {
  return text.isNotEmpty && _punctuationRegex.hasMatch(text);
}
