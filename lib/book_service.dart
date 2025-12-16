import 'package:cloud_firestore/cloud_firestore.dart';

class BookService {
  final CollectionReference books = FirebaseFirestore.instance.collection('books');

  // Create a new Book
  Future<void> addBook(String name) {
    return books.add({
      'name': name,
      'createdAt': Timestamp.now(),
    });
  }

  // Delete a Book
  Future<void> deleteBook(String docId) {
    return books.doc(docId).delete();
  }

  // Get List of Books
  Stream<QuerySnapshot> getBooks() {
    return books.orderBy('createdAt', descending: true).snapshots();
  }
}