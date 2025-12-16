import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfHelper {
  static Future<void> generatePdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    // Calculate totals for the report
    double totalIn = 0;
    double totalOut = 0;
    for (var doc in docs) {
      final isCredit = doc['isCredit'] as bool;
      final amount = (doc['amount'] as num).toDouble();
      if (isCredit) totalOut += amount; else totalIn += amount;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("CashBook Statement", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),
              
              // Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total IN: + ${totalIn.toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.green)),
                    pw.Text("Total OUT: - ${totalOut.toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.red)),
                    pw.Text("Net Balance: ${(totalIn - totalOut).toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Transaction Table
              pw.Table.fromTextArray(
                headers: ['Date', 'Remark', 'Type', 'Amount'],
                data: docs.map((doc) {
                  final date = (doc['timestamp'] as Timestamp).toDate();
                  final isCredit = doc['isCredit'] as bool;
                  return [
                    DateFormat('dd-MMM HH:mm').format(date),
                    doc['remark'],
                    isCredit ? "OUT" : "IN",
                    "${doc['amount']}",
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    // This opens the standard print/share dialog on the phone
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}