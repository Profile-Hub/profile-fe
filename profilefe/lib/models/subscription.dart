class SubscriptionStatus {
  final bool success;
  final Subscription? subscription;
  final String? message; 

  SubscriptionStatus({
    required this.success,
    this.subscription,
    this.message, 
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      success: json['success'],
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
      message: json['message'],
    );
  }
}

class Subscription {
  final String? userId;
  final String? planId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? credit;
  final String? paymentId;
  final String? orderId;
  final int? amount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Subscription({
    this.userId,
    this.planId,
    this.status,
    this.startDate,
    this.endDate,
    this.credit,
    this.paymentId,
    this.orderId,
    this.amount,
    this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      userId: json['userId'],
      planId: json['planId'],
      status: json['status'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      credit: json['credit'],
      paymentId: json['paymentId'],
      orderId: json['orderId'],
      amount: json['amount'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}
