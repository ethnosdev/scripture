/// Defines the formatting for a paragraph of text.
enum ParagraphFormat {
  /// margin, no indentation
  m('m'),

  /// break, blank vertical space
  b('b'),

  /// poetry indentation level 1
  q1('q1'),

  /// poetry indentation level 2
  q2('q2'),

  /// Embedded text opening
  pmo('pmo'),

  /// list item level 1
  li1('li1'),

  /// list item level 2
  li2('li2'),

  /// centered
  ///
  /// Example: MENE, MENE, TEKEL, PARSIN.
  pc('pc'),

  /// right aligned
  ///
  /// Example: Selah
  qr('qr'),

  /// Descriptive Title
  ///
  /// Example: (Psalms "Of David")
  d('d'),

  /// Cross Reference
  r('r'),

  /// Section Heading Level 1
  s1('s1'),

  /// Section Heading Level 2
  s2('s2'),

  /// major section (Psalms)
  ms('ms'),

  /// major section range (Psalms)
  mr('mr'),

  /// Acrostic Heading (Psalm 119)
  qa('qa');

  /// The stable string value of the enum, used for database storage.
  final String id;
  const ParagraphFormat(this.id);

  /// A private, static map for efficient O(1) lookups from a string ID.
  static final Map<String, ParagraphFormat> _byId = Map.fromEntries(
    values.map((v) => MapEntry(v.id, v)),
  );

  /// A convenience getter to check if the format is for main biblical text
  /// as opposed to headings, titles, or other metadata.
  bool get isBiblicalText {
    switch (this) {
      case m:
      case b:
      case q1:
      case q2:
      case pmo:
      case li1:
      case li2:
      case pc:
      case qr:
      case d:
        return true;
      case r:
      case s1:
      case s2:
      case ms:
      case mr:
      case qa:
        return false;
    }
  }

  /// Deserializes a string [value] from a database into a [ParagraphFormat].
  ///
  /// Uses a pre-built map for efficient O(1) performance.
  factory ParagraphFormat.fromJson(String value) {
    final format = _byId[value];
    if (format == null) {
      throw ArgumentError('Unknown ParagraphFormat id: $value');
    }
    return format;
  }

  /// Serializes the enum into a string for database storage.
  String toJson() => id;
}
