import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  // Now we need the bookId to know WHERE to save the money
  final String bookId;

  TransactionService(this.bookId);

  // Reference to the specific book's transactions
  CollectionReference get operations =>
      FirebaseFirestore.instance.collection('books').doc(bookId).collection('transactions');

  Future<void> addTransaction({
    required double amount,
    required String remark,
    required bool isCredit,
  }) {
    return operations.add({
      'amount': amount,
      'remark': remark,
      'isCredit': isCredit,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> updateTransaction(String id, {
    required double amount,
    required String remark,
    required bool isCredit,
  }) {
    return operations.doc(id).update({
      'amount': amount,
      'remark': remark,
      'isCredit': isCredit,
    });
  }

  Future<void> deleteTransaction(String docId) {
    return operations.doc(docId).delete();
  }

  Stream<QuerySnapshot> getTransactions() {
    return operations.orderBy('timestamp', descending: true).snapshots();
  }
}