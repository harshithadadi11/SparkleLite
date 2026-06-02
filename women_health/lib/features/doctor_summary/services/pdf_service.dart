import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../../data/models/doctor_summary.dart';

class PdfService {
  static Future<Uint8List> generateDoctorSummaryPdf(DoctorSummary summary) async {
    final pdf = pw.Document();

    final profile = summary.profileSnapshot;
    final name = profile['name'] ?? profile['nameOrNickname'] ?? 'Unknown';
    final age = profile['age'] ?? profile['ageRange'] ?? 'Unknown';
    final bloodType = profile['bloodType'] ?? 'Unknown';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Sparkle Lite', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.purple800)),
                    pw.Text('Doctor Visit Summary', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    pw.Text(DateFormat('MMMM dd, yyyy').format(summary.generatedAt), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, height: 32, color: PdfColors.purple200),
            
            // Patient Profile
            pw.Text('Patient Profile', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildProfileItem('Name', name),
                  _buildProfileItem('Age/Life Stage', age.toString()),
                  _buildProfileItem('Blood Type', bloodType),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            if (summary.medications != null && summary.medications!.isNotEmpty)
              pw.Text('Medications: ${summary.medications}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 24),

            // Symptoms
            pw.Text('Recent Symptoms Logged', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
            pw.SizedBox(height: 8),
            pw.Text('${summary.recentSymptomLogs?.length ?? 0} symptoms logged in the selected timeframe.', style: const pw.TextStyle(color: PdfColors.black)),
            pw.SizedBox(height: 24),

            // Records
            pw.Text('Recent Health Records', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
            pw.SizedBox(height: 8),
            pw.Text('${summary.recentRecords?.length ?? 0} records attached.', style: const pw.TextStyle(color: PdfColors.black)),
            pw.SizedBox(height: 24),

            // Questions
            if (summary.questionsToAsk.isNotEmpty) ...[
              pw.Text('Questions to Ask', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
              pw.SizedBox(height: 8),
              ...summary.questionsToAsk.map((q) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $q'),
              )),
            ],
            
            // Footer
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text('Generated privately and securely by Sparkle Lite', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildProfileItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
