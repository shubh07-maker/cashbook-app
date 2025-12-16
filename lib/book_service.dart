import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookService {
  final CollectionReference books = FirebaseFirestore.instance.collection('books');
  final String? userId = FirebaseAuth.instance.currentUser?.uid; // Get Current User ID

  // Create Book (Tag it with the User ID)
  Future<void> addBook(String name) {
    if (userId == null) return Future.error("Not logged in");
    return books.add({
      'name': name,
      'uid': userId, // IMPORTANT: This makes it private
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteBook(String docId) {
    return books.doc(docId).delete();
  }

  // Get Books (Only filter for THIS user)
  Stream<QuerySnapshot> getBooks() {
    if (userId == null) return const Stream.empty();
    return books
        .where('uid', isEqualTo: userId) // Filter Logic
        
        .snapshots();
  }
}