import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/troupeau_provider.dart';

class FicheScreen extends StatelessWidget {
  const FicheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche de suivi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Exporter PDF', onPressed: () => _exportPDF(context)),
          IconButton(icon: const Icon(Icons.table_chart), tooltip: 'Exporter Excel', onPressed: () => _exportExcel(context)),
        ],
      ),
      body: Consumer<TroupeauProvider>(
        builder: (context, provider, child) {
          final mouvements = provider.mouvementsRecents..sort((a, b) => a.date.compareTo(b.date));
          final situation = provider.situation;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'} | Propriétaire : ${provider.proprietaireSelectionne?.nom ?? '-'}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.brown.shade100),
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columns: const [DataColumn(label: Text('DATE')), DataColumn(label: Text('MOUVEMENT')), DataColumn(label: Text('CAT.')), DataColumn(label: Text('QTÉ'), numeric: true), DataColumn(label: Text('SENS')), DataColumn(label: Text('OBS'))],
                      rows: [
                        DataRow(color: MaterialStateProperty.all(Colors.green.shade50), cells: [DataCell(Text(DateFormat('dd/MM/yy').format(DateTime.now()))), const DataCell(Text('SITUATION ACTUELLE', style: TextStyle(fontWeight: FontWeight.bold))), const DataCell(Text('TOT')), DataCell(Text('${situation.total}', style: const TextStyle(fontWeight: FontWeight.bold))), const DataCell(Text('–')), const DataCell(Text('Stock actuel'))]),
                        ...mouvements.map((m) => DataRow(cells: [
                          DataCell(Text(DateFormat('dd/MM/yy').format(m.date))),
                          DataCell(Text(m.type.label)),
                          DataCell(Text(m.categorie.code)),
                          DataCell(Text('${m.quantite}')),
                          DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: m.type.sens == 'entree' ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(4)), child: Text(m.type.sens == 'entree' ? '+' : '–', style: TextStyle(color: m.type.sens == 'entree' ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold)))),
                          DataCell(Text(m.notes ?? '')),
                        ])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('SITUATION PAR CATÉGORIE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildResumeCard('T', situation.taurions, Colors.brown),
                      _buildResumeCard('G', situation.genisses, Colors.orange),
                      _buildResumeCard('V', situation.vaches, Colors.green),
                      _buildResumeCard('VM', situation.veauxMales, Colors.blue),
                      _buildResumeCard('VF', situation.veauxFemelles, Colors.purple),
                      _buildResumeCard('GEST', situation.gestation, Colors.pink),
                      _buildResumeCard('TOT', situation.total, Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumeCard(String code, int valeur, Color couleur) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: couleur.withOpacity(0.1), border: Border.all(color: couleur), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [Text(code, style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 18)), Text('$valeur', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: couleur.withOpacity(0.8)))]),
    );
  }

  void _exportPDF(BuildContext context) async {
    try {
      final provider = context.read<TroupeauProvider>();
      final mouvements = provider.mouvementsRecents..sort((a, b) => a.date.compareTo(b.date));
      final situation = provider.situation;

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'} | Propriétaire : ${provider.proprietaireSelectionne?.nom ?? '-'}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8D4C0')),
                    children: [pw.Text('DATE'), pw.Text('MOUVEMENT'), pw.Text('CAT.'), pw.Text('QTÉ'), pw.Text('SENS'), pw.Text('OBS')].map((t) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: t)).toList(),
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9')),
                    children: [
                      pw.Text(DateFormat('dd/MM/yy').format(DateTime.now())),
                      pw.Text('SITUATION ACTUELLE'),
                      pw.Text('TOT'),
                      pw.Text('${situation.total}'),
                      pw.Text('–'),
                      pw.Text('Stock actuel'),
                    ].map((t) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: t)).toList(),
                  ),
                  ...mouvements.map((m) => pw.TableRow(
                    children: [
                      pw.Text(DateFormat('dd/MM/yy').format(m.date)),
                      pw.Text(m.type.label),
                      pw.Text(m.categorie.code),
                      pw.Text('${m.quantite}'),
                      pw.Text(m.type.sens == 'entree' ? '+' : '–'),
                      pw.Text(m.notes ?? ''),
                    ].map((t) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: t)).toList(),
                  )),
                ],
              ),
            ],
          ),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filename = 'Fiche_${provider.troupeauSelectionne?.nom ?? 'betail'}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF sauvegardé : $filename')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  void _exportExcel(BuildContext context) async {
    try {
      final provider = context.read<TroupeauProvider>();
      final mouvements = provider.mouvementsRecents..sort((a, b) => a.date.compareTo(b.date));
      final situation = provider.situation;

      var excelSheet = excel.Excel.createExcel();
      var sheet = excelSheet['Fiche'];

      sheet.appendRow(['FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL']);
      sheet.appendRow(['Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}', 'Propriétaire : ${provider.proprietaireSelectionne?.nom ?? '-'}']);
      sheet.appendRow([]);

      sheet.appendRow(['DATE', 'MOUVEMENT', 'CAT.', 'QTÉ', 'SENS', 'OBS']);
      sheet.appendRow([
        DateFormat('dd/MM/yy').format(DateTime.now()),
        'SITUATION ACTUELLE',
        'TOT',
        situation.total,
        '–',
        'Stock actuel',
      ]);

      for (var m in mouvements) {
        sheet.appendRow([
          DateFormat('dd/MM/yy').format(m.date),
          m.type.label,
          m.categorie.code,
          m.quantite,
          m.type.sens == 'entree' ? '+' : '–',
          m.notes ?? '',
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow(['SITUATION PAR CATÉGORIE']);
      sheet.appendRow(['T', 'G', 'V', 'VM', 'VF', 'GEST', 'TOT']);
      sheet.appendRow([situation.taurions, situation.genisses, situation.vaches, situation.veauxMales, situation.veauxFemelles, situation.gestation, situation.total]);

      final directory = await getApplicationDocumentsDirectory();
      final filename = 'Fiche_${provider.troupeauSelectionne?.nom ?? 'betail'}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(excelSheet.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel sauvegardé : $filename')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }
}
