import 'plan_item.dart';

enum ModificationStatus {
  applied('APPLIED'),
  removed('REMOVED'),
  parentApprovalRequired('PARENT_APPROVAL_REQUIRED');

  final String wireValue;
  const ModificationStatus(this.wireValue);

  static ModificationStatus fromWire(String value) => ModificationStatus.values
      .firstWhere((s) => s.wireValue == value, orElse: () => ModificationStatus.applied);
}

/// Result of a plan-modification request. Per the spec, a required item's
/// deletion is never silently honored when parent policy locks it -- instead
/// [status] comes back as PARENT_APPROVAL_REQUIRED and [updatedItem] is null.
class ModificationResult {
  final ModificationStatus status;
  final PlanItem? updatedItem;
  final String message;
  final String reason;

  const ModificationResult({
    required this.status,
    this.updatedItem,
    required this.message,
    required this.reason,
  });

  factory ModificationResult.fromJson(Map<String, dynamic> json) => ModificationResult(
        status: ModificationStatus.fromWire(json['modificationStatus'] as String),
        updatedItem: json['updatedItem'] == null
            ? null
            : PlanItem.fromJson(json['updatedItem'] as Map<String, dynamic>),
        message: json['message'] as String,
        reason: json['reason'] as String,
      );

  Map<String, dynamic> toJson() => {
        'modificationStatus': status.wireValue,
        'updatedItem': updatedItem?.toJson(),
        'message': message,
        'reason': reason,
      };
}
