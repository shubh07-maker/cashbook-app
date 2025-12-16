import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_service.dart';
import 'home_screen.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'main.dart';
import 'profile_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final BookService _bookService = BookService();
  final TextEditingController _nameController = TextEditingController();

  Map<String, double> _calculateTotals(List<QueryDocumentSnapshot> docs) {
    double totalIn = 0;
    double totalOut = 0;
    for (var doc in docs) {
      final amount = (doc['amount'] as num).toDouble();
      final isCredit = doc['isCredit'] as bool;
      if (isCredit) {
        totalOut += amount;
      } else {
        totalIn += amount;
      }
    }
    return {
      'balance': totalIn - totalOut,
    };
  }

  void _showAddBookDialog() {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Book"),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Book Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                _bookService.addBook(_nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookshelf"),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
          icon: const Icon(Icons.account_circle, size: 28), // Profile Icon
          onPressed: () {
         Navigator.push(
         context,
         MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  },
),
        ],
      ),
      backgroundColor: isDark ? null : Colors.grey[100], 
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookService.getBooks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final books = snapshot.data!.docs;

          if (books.isEmpty) {
            return const Center(child: Text("No books yet. Tap + to create."));
          }

          return ListView.builder(
            itemCount: books.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final bookDoc = books[index];
              final bookId = bookDoc.id;
              final bookName = bookDoc['name'];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('books')
                    .doc(bookId)
                    .collection('transactions')
                    .snapshots(),
                builder: (context, txSnapshot) {
                  double balance = 0;
                  if (txSnapshot.hasData) {
                    final totals = _calculateTotals(txSnapshot.data!.docs);
                    balance = totals['balance']!;
                  }

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(bookId: bookId, bookName: bookName),
                          ),
                        );
                      },
                      onLongPress: () => _bookService.deleteBook(bookId),
                      title: Text(bookName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      trailing: Text(
                        "₹ ${balance.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red, 
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}