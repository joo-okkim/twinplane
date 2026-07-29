/// Requests a new 이해도 확인 (comprehension check) assessment for a
/// completed, evidence-required plan item. Deliberately carries only the
/// item id -- subject/scope are resolved server-side (see
/// twinplane-backend's resolveScope) so a client can't force generation for
/// scope it doesn't own.
class AssessmentGenerateRequest {
  final String planItemId;

  const AssessmentGenerateRequest({required this.planItemId});

  Map<String, dynamic> toJson() => {'planItemId': planItemId};
}
