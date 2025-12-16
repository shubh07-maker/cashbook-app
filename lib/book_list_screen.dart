import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_service.dart';
import 'home_screen.dart'; 

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final BookService _bookService = BookService();
  final TextEditingController _nameController = TextEditingController();

  // Helper to calculate totals from a list of documents
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
      'in': totalIn,
      'out': totalOut,
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
          decoration: const InputDecoration(labelText: "Book Name (e.g. Jan 2025)"),
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
    return Scaffold(
      appBar: AppBar(title: const Text("My Bookshelf")),
      backgroundColor: Colors.grey[100], // Light grey background for better contrast
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookService.getBooks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final books = snapshot.data!.docs;

          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No books yet.", style: TextStyle(color: Colors.grey)),
                  Text("Tap + to create one.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: books.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final bookDoc = books[index];
              final bookId = bookDoc.id;
              final bookName = bookDoc['name'];

              // Nested StreamBuilder: Peeks inside EACH book to calculate totals
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('books')
                    .doc(bookId)
                    .collection('transactions')
                    .snapshots(),
                builder: (context, txSnapshot) {
                  // Default values if loading
                  double totalIn = 0;
                  double totalOut = 0;
                  double balance = 0;

                  if (txSnapshot.hasData) {
                    final totals = _calculateTotals(txSnapshot.data!.docs);
                    totalIn = totals['in']!;
                    totalOut = totals['out']!;
                    balance = totals['balance']!;
                  }

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(bookId: bookId, bookName: bookName),
                          ),
                        );
                      },
                      onLongPress: () => _bookService.deleteBook(bookId),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Book Name and Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bookName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                            const Divider(height: 20),

                            // Section 1: Net Balance (Big Center Text)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Net Balance", style: TextStyle(color: Colors.grey, fontSize: 14)),
                                Text(
                                  "₹ ${balance.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Section 2: Income and Expense Row
                            Row(
                              children: [
                                // Income
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Total In (+)", style: TextStyle(color: Colors.green, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(
                                          "₹ ${totalIn.toStringAsFixed(0)}",
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Expense
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Total Out (-)", style: TextStyle(color: Colors.red, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(
                                          "₹ ${totalOut.toStringAsFixed(0)}",
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBookDialog,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        label: const Text("New Book"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}