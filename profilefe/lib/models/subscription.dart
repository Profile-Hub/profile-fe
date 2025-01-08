class SubscriptionStatus {
  final bool hasActiveSubscription;
  final Subscription? subscription;

  SubscriptionStatus({
    required this.hasActiveSubscription,
    this.subscription,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      hasActiveSubscription: json['hasActiveSubscription'],
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
    );
  }
}

class Subscription {
  final String id;
  final int credits;
  final String status;
  final DateTime expirationDate;

  Subscription({
    required this.id,
    required this.credits,
    required this.status,
    required this.expirationDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'],
      credits: json['credits'],
      status: json['status'],
      expirationDate: DateTime.parse(json['expirationDate']),
    );
  }
}