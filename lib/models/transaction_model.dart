enum TransactionStatus { pending, completed, cancelled, failed }

class TransactionModel {
  final String id;
  final String userId;
  final String toolId;
  final String toolName;
  final String toolImage;
  final double amount;
  final DateTime date;
  final TransactionStatus status;
  final String paymentMethod;
  final String transactionReference; // e.g., UPI ID or Card last 4 digits

  TransactionModel({
    required this.id,
    required this.userId,
    required this.toolId,
    required this.toolName,
    required this.toolImage,
    required this.amount,
    required this.date,
    required this.status,
    required this.paymentMethod,
    required this.transactionReference,
  });

  // Ready for backend integration
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'toolId': toolId,
    'amount': amount,
    'status': status.name,
    'paymentMethod': paymentMethod,
    'date': date.toIso8601String(),
  };
}
