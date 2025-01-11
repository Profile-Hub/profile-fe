class SubscriptionStatus {
  final bool success;
  final Subscription? subscription;

  SubscriptionStatus({
    required this.success,
    this.subscription,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      success: json['success'],
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
    );
  }
}

class Subscription {
  final String? id; // `id` might be null if not always present
  final int? credit; // Allow nullable `credit`
  final String? status; // Allow nullable `status`
  final DateTime? expirationDate; // Allow nullable `expirationDate`

  Subscription({
    this.id,
    this.credit,
    this.status,
    this.expirationDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'], // Map `_id` to `id`
      credit: json['credit'], // Accept nullable `credit`
      status: json['status'], // Accept nullable `status`
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null, // Handle nullable `expirationDate`
    );
  }
}
