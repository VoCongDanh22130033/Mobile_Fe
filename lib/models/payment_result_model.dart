// File: lib/models/payment_result_model.dart

class PaymentResultModel {
  final String transactionRef; // Mã đơn hàng (vnp_TxnRef)
  final String amount;         // Số tiền (vnp_Amount đã format)
  final String bankCode;       // Mã Ngân hàng (vnp_BankCode)
  final String payDate;        // Thời gian (vnp_PayDate đã format)
  final String responseCode;   // Mã phản hồi VNPAY (vnp_ResponseCode)
  final String transactionStatus; // Trạng thái giao dịch (vnp_TransactionStatus)

  PaymentResultModel({
    required this.transactionRef,
    required this.amount,
    required this.bankCode,
    required this.payDate,
    required this.responseCode,
    required this.transactionStatus,
  });

  // Hàm tiện ích để kiểm tra giao dịch thành công (00)
  bool get isSuccess => responseCode == '00' && transactionStatus == '00';
}