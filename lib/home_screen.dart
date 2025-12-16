import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transaction_service.dart';
import 'pdf_helper.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  final String bookId;
  final String bookName;

  const HomeScreen({super.key, required this.bookId, required this.bookName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TransactionService _service;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = TransactionService(widget.bookId);
  }

  void _showEntryDialog(BuildContext context, {required bool isCashOut, DocumentSnapshot? docToEdit}) {
    if (docToEdit != null) {
      _amountController.text = docToEdit['amount'].toString();
      _remarkController.text = docToEdit['remark'];
    } else {
      _amountController.clear();
      _remarkController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(docToEdit != null ? "Edit Transaction" : (isCashOut ? "Add Payment" : "Add Receipt"),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isCashOut ? Colors.red : Colors.green)),
            const SizedBox(height: 15),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _remarkController, decoration: const InputDecoration(labelText: 'Remark', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isCashOut ? Colors.red : Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  if (_amountController.text.isNotEmpty) {
                    double amount = double.parse(_amountController.text);
                    if (docToEdit != null) {
                      _service.updateTransaction(docToEdit.id, amount: amount, remark: _remarkController.text, isCredit: isCashOut);
                    } else {
                      _service.addTransaction(amount: amount, remark: _remarkController.text, isCredit: isCashOut);
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text("SAVE"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100], // Light grey background like the screenshot
      appBar: AppBar(
        title: Text(widget.bookName),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.docs;

          double totalIn = 0;
          double totalOut = 0;
          for (var doc in data) {
            (doc['isCredit'] as bool) ? totalOut += doc['amount'] : totalIn += doc['amount'];
          }

          return Column(
            children: [
              // --- NEW DASHBOARD CARD ---
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Net Balance Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Net Balance", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              Text("₹ ${(totalIn - totalOut).toStringAsFixed(0)}", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          
                          // Total In Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total In (+)", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text("₹ ${totalIn.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Total Out Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Out (-)", style: TextStyle(fontWeight: FontWeight.w500)),
                              Text("₹ ${totalOut.toStringAsFixed(0)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),
                    
                    // View Reports Button (Clickable)
                    InkWell(
                      onTap: () async {
                        PdfHelper.generatePdf(data);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("VIEW REPORTS", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            Icon(Icons.chevron_right, color: Colors.blue, size: 20)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lock Icon Message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Text("Only you can see these entries", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),

              // --- TRANSACTION LIST ---
              Expanded(
                child: data.isEmpty 
                  ? Center(child: Text("Add your first entry below ↓", style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final doc = data[index];
                      bool isCredit = doc['isCredit'];
                      return Card(
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        elevation: 0, // Flat list style
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCredit ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            child: Icon(isCredit ? Icons.remove : Icons.add, color: isCredit ? Colors.red : Colors.green, size: 20)
                          ),
                          title: Text(doc['remark'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd MMM, hh:mm a').format((doc['timestamp'] as Timestamp).toDate())),
                          trailing: Text("₹ ${doc['amount']}", style: TextStyle(color: isCredit ? Colors.red : Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                          onTap: () => _showEntryDialog(context, isCashOut: isCredit, docToEdit: doc),
                          onLongPress: () => _service.deleteTransaction(doc.id),
                        ),
                      );
                    },
                  ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Row(children: [
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.add), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => _showEntryDialog(context, isCashOut: false), 
            label: const Text("CASH IN")
          )),
          const SizedBox(width: 16),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.remove), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => _showEntryDialog(context, isCashOut: true), 
            label: const Text("CASH OUT")
          )),
        ]),
      ),
    );
  }
}