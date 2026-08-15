import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/heart_valve_entry.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _kHeaderBg   = PdfColors.blue800;
const _kAccent     = PdfColor.fromInt(0xFF1565C0);
const _kRowAlt     = PdfColors.grey100;
const _kSummaryBg  = PdfColor.fromInt(0xFFE3F2FD);
const _kSummaryBdr = PdfColor.fromInt(0xFF1E88E5);

class PdfHelper {
  static Future<Uint8List> generateReport({
    required List<HeartValveEntry> entries,
    required String operatorName,
    required int year,
    required int month,
  }) async {
    final pdf     = pw.Document();
    final dtFmt   = DateFormat('dd/MM/yy HH:mm');
    final period  = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final genTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final Map<String, int> breakdown = {};
    for (final e in entries) {
      breakdown[e.model] = (breakdown[e.model] ?? 0) + 1;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        header: (_) => _buildHeader(operatorName, period, genTime),
        footer: (ctx) => _buildFooter(ctx),
        build: (pw.Context ctx) => [
          pw.SizedBox(height: 14),
          entries.isEmpty ? _buildEmptyState() : _buildTable(entries, dtFmt),
          pw.SizedBox(height: 20),
          _buildSummaryBox(breakdown, entries.length),
        ],
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildHeader(String operatorName, String period, String genTime) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MYValve Log',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _kAccent)),
                pw.Text('Monthly Production Log',
                    style: pw.TextStyle(fontSize: 13, color: PdfColors.blueGrey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(period,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kAccent)),
                pw.SizedBox(height: 2),
                pw.Text('Operator: ${operatorName.isEmpty ? "N/A" : operatorName}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _kHeaderBg)),
                pw.Text('Generated: $genTime',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: _kAccent, thickness: 1.5),
        pw.SizedBox(height: 2),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildEmptyState() {
    return pw.Center(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 40),
        child: pw.Text('No entries found for this period.',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
      ),
    );
  }

  static pw.Widget _buildTable(List<HeartValveEntry> entries, DateFormat dtFmt) {
    const headers = ['Sr. No.', 'Model', 'Serial No.', 'Batch No.', 'Size', 'Take Time', 'Submit Time'];

    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(0.7),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(2.1),
      3: const pw.FlexColumnWidth(1.8),
      4: const pw.FlexColumnWidth(0.8),
      5: const pw.FlexColumnWidth(2.2),
      6: const pw.FlexColumnWidth(2.2),
    };

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: _kHeaderBg),
      children: headers.map((h) => _headerCell(h)).toList(),
    );

    final dataRows = List.generate(entries.length, (i) {
      final e = entries[i];
      final bg = i.isEven ? _kRowAlt : PdfColors.white;
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          _dataCell('${i + 1}', align: pw.TextAlign.center),
          _dataCell(e.model, isBold: true),
          _dataCell(e.serialNo),
          _dataCell(e.batchNo),
          _dataCell(e.size, align: pw.TextAlign.center),
          _dataCell(dtFmt.format(e.takeTime)),
          _dataCell(dtFmt.format(e.submitTime)),
        ],
      );
    });

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.6),
      columnWidths: colWidths,
      children: [headerRow, ...dataRows],
    );
  }

  static pw.Widget _buildSummaryBox(Map<String, int> breakdown, int grandTotal) {
    final sortedModels = breakdown.keys.toList()..sort();

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _kSummaryBg,
        border: pw.Border.all(color: _kSummaryBdr, width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Production Summary',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _kAccent)),
          pw.Divider(color: _kSummaryBdr, thickness: 0.8),
          pw.SizedBox(height: 4),
          if (sortedModels.isEmpty)
            pw.Text('No data available.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            ...sortedModels.map((model) {
              final count = breakdown[model]!;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 8, height: 8,
                      decoration: pw.BoxDecoration(color: _kAccent, shape: pw.BoxShape.circle),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(child: pw.Text(model, style: const pw.TextStyle(fontSize: 10))),
                    pw.Text('$count',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              );
            }),
          pw.SizedBox(height: 8),
          pw.Divider(color: _kSummaryBdr, thickness: 0.8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kAccent)),
              pw.Text('$grandTotal',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _kAccent)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  static pw.Widget _dataCell(String text,
      {bool isBold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.grey900)),
    );
  }
}
