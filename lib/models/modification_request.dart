enum ModificationReason {
  tired('TIRED'),
  tooMuch('TOO_MUCH'),
  wrongTime('WRONG_TIME'),
  dontWant('DONT_WANT');

  final String wireValue;
  const ModificationReason(this.wireValue);

  static ModificationReason fromWire(String value) => ModificationReason.values
      .firstWhere((r) => r.wireValue == value, orElse: () => ModificationReason.tired);
}

/// A student's request to change an existing plan item. Mirrors the spec's
/// student-feedback modification flow (section 14) -- the mock service does
/// not blindly comply; see ModificationLogic for the rule-based decision.
class ModificationRequest {
  final String planItemId;
  final ModificationReason reason;
  final String? freeText;

  const ModificationRequest({
    required this.planItemId,
    required this.reason,
    this.freeText,
  });

  Map<String, dynamic> toJson() => {
        'planItemId': planItemId,
        'reason': reason.wireValue,
        'freeText': freeText,
      };
}
