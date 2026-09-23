import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../providers/troupeau_provider.dart';

class FicheScreen extends StatelessWidget {
  const FicheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fiche de suivi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter PDF',
            onPressed: () => _exportPDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Exporter Excel',
            onPressed: () => _exportExcel(context),
          ),
        ],
      ),
      body: Consumer<TroupeauProvider>(
        builder: (context, provider, child) {
          final mouvements = [...provider.mouvementsRecents]
            ..sort((a, b) => a.date.compareTo(b.date));

          final situation = provider.situation;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'} | '
                    'Propriétaire : ${provider.proprietaireSelectionne?.nom ?? '-'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DataTable(
                      headingRowColor:
                          MaterialStateProperty.all(Colors.brown.shade100),
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                      ),
                      columns: const [
                        DataColumn(label: Text('DATE')),
                        DataColumn(label: Text('MOUVEMENT')),
                        DataColumn(label: Text('CAT.')),
                        DataColumn(
                          label: Text('QTÉ'),
                          numeric: true,
                        ),
                        DataColumn(label: Text('SENS')),
                        DataColumn(label: Text('OBS')),
                      ],
                      rows: [
                        DataRow(
                          color: MaterialStateProperty.all(
                            Colors.green.shade50,
                          ),
                          cells: [
                            DataCell(
                              Text(
                                DateFormat('dd/MM/yy')
                                    .format(DateTime.now()),
                              ),
                            ),
                            const DataCell(
                              Text(
                                'SITUATION ACTUELLE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const DataCell(Text('TOT')),
                            DataCell(
                              Text(
                                '${situation.total}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const DataCell(Text('–')),
                            const DataCell(Text('Stock actuel')),
                          ],
                        ),
                        ...mouvements.map(
                          (m) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  DateFormat('dd/MM/yy').format(m.date),
                                ),
                              ),
                              DataCell(Text(m.type.label)),
                              DataCell(Text(m.categorie.code)),
                              DataCell(Text('${m.quantite}')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: m.type.sens == 'entree'
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    m.type.sens == 'entree' ? '+' : '–',
                                    style: TextStyle(
                                      color: m.type.sens == 'entree'
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(m.notes ?? '')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SITUATION PAR CATÉGORIE',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildResumeCard(
                        'T',
                        situation.taurions,
                        Colors.brown,
                      ),
                      _buildResumeCard(
                        'G',
                        situation.genisses,
                        Colors.orange,
                      ),
                      _buildResumeCard(
                        'V',
                        situation.vaches,
                        Colors.green,
                      ),
                      _buildResumeCard(
                        'VM',
                        situation.veauxMales,
                        Colors.blue,
                      ),
                      _buildResumeCard(
                        'VF',
                        situation.veauxFemelles,
                        Colors.purple,
                      ),
                      _buildResumeCard(
                        'GEST',
                        situation.gestation,
                        Colors.pink,
                      ),
                      _buildResumeCard(
                        'TOT',
                        situation.total,
                        Colors.teal,
                      ),
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

  Widget _buildResumeCard(
    String code,
    int valeur,
    Color couleur,
  ) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        border: Border.all(color: couleur),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            code,
            style: TextStyle(
              color: couleur,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            '$valeur',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: couleur.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPDF(BuildContext context) async {
    try {
      final provider = context.read<TroupeauProvider>();

      final mouvements = [...provider.mouvementsRecents]
        ..sort((a, b) => a.date.compareTo(b.date));

      final situation = provider.situation;
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'} | '
                  'Propriétaire : '
                  '${provider.proprietaireSelectionne?.nom ?? '-'}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E8D4C0'),
                      ),
                      children: [
                        _pdfCell('DATE'),
                        _pdfCell('MOUVEMENT'),
                        _pdfCell('CAT.'),
                        _pdfCell('QTÉ'),
                        _pdfCell('SENS'),
                        _pdfCell('OBS'),
                      ],
                    ),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E8F5E9'),
                      ),
                      children: [
                        _pdfCell(
                          DateFormat('dd/MM/yy').format(DateTime.now()),
                        ),
                        _pdfCell('SITUATION ACTUELLE'),
                        _pdfCell('TOT'),
                        _pdfCell('${situation.total}'),
                        _pdfCell('–'),
                        _pdfCell('Stock actuel'),
                      ],
                    ),
                    ...mouvements.map(
                      (m) => pw.TableRow(
                        children: [
                          _pdfCell(
                            DateFormat('dd/MM/yy').format(m.date),
                          ),
                          _pdfCell(m.type.label),
                          _pdfCell(m.categorie.code),
                          _pdfCell('${m.quantite}'),
                          _pdfCell(
                            m.type.sens == 'entree' ? '+' : '–',
                          ),
                          _pdfCell(m.notes ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'SITUATION PAR CATÉGORIE',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        _pdfCell('T'),
                        _pdfCell('G'),
                        _pdfCell('V'),
                        _pdfCell('VM'),
                        _pdfCell('VF'),
                        _pdfCell('GEST'),
                        _pdfCell('TOT'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _pdfCell('${situation.taurions}'),
                        _pdfCell('${situation.genisses}'),
                        _pdfCell('${situation.vaches}'),
                        _pdfCell('${situation.veauxMales}'),
                        _pdfCell('${situation.veauxFemelles}'),
                        _pdfCell('${situation.gestation}'),
                        _pdfCell('${situation.total}'),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();

      final filename =
          'Fiche_${provider.troupeauSelectionne?.nom ?? 'betail'}_'
          '${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';

      final file = File('${directory.path}/$filename');

      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF sauvegardé : $filename'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF : $e'),
          ),
        );
      }
    }
  }

  pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text),
    );
  }

    /*
   * Convertit une valeur Dart en CellValue compatible avec
   * excel: 4.0.6.
   */
  excel.CellValue _toExcelCellValue(Object? value) {
    if (value == null) {
      return excel.TextCellValue('');
    }

    if (value is int) {
      return excel.IntCellValue(value);
    }

    if (value is double) {
      return excel.DoubleCellValue(value);
    }

    if (value is bool) {
      return excel.BoolCellValue(value);
    }

    return excel.TextCellValue(value.toString());
  }

  /*
   * Transforme une ligne Dart en ligne Excel compatible avec
   * excel: 4.0.6.
   */
  List<excel.CellValue> _excelRow(List<Object?> values) {
    return values.map(_toExcelCellValue).toList();
  }

  Future<void> _exportExcel(BuildContext context) async {
    try {
      final provider = context.read<TroupeauProvider>();

      final mouvements = [...provider.mouvementsRecents]
        ..sort((a, b) => a.date.compareTo(b.date));

      final situation = provider.situation;

      final excelFile = excel.Excel.createExcel();

      excelFile.rename('Sheet1', 'Fiche');

      final sheet = excelFile['Fiche'];

      // Titre
      sheet.insertRowIterables(
        _excelRow([
          'FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL',
        ]),
        0,
      );

      // Informations générales
      sheet.insertRowIterables(
        _excelRow([
          'Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}',
          'Propriétaire : '
              '${provider.proprietaireSelectionne?.nom ?? '-'}',
        ]),
        1,
      );

      // Ligne vide
      sheet.insertRowIterables(
        _excelRow([]),
        2,
      );

      // En-têtes du tableau
      sheet.insertRowIterables(
        _excelRow([
          'DATE',
          'MOUVEMENT',
          'CAT.',
          'QTÉ',
          'SENS',
          'OBS',
        ]),
        3,
      );

      // Situation actuelle
      sheet.insertRowIterables(
        _excelRow([
          DateFormat('dd/MM/yy').format(DateTime.now()),
          'SITUATION ACTUELLE',
          'TOT',
          situation.total,
          '–',
          'Stock actuel',
        ]),
        4,
      );

      // Mouvements
      var rowIndex = 5;

      for (final mouvement in mouvements) {
        sheet.insertRowIterables(
          _excelRow([
            DateFormat('dd/MM/yy').format(mouvement.date),
            mouvement.type.label,
            mouvement.categorie.code,
            mouvement.quantite,
            mouvement.type.sens == 'entree' ? '+' : '–',
            mouvement.notes ?? '',
          ]),
          rowIndex,
        );

        rowIndex++;
      }

      // Espace avant le résumé
      rowIndex++;

      // Titre du résumé
      sheet.insertRowIterables(
        _excelRow([
          'SITUATION PAR CATÉGORIE',
        ]),
        rowIndex,
      );

      rowIndex++;

      // En-têtes du résumé
      sheet.insertRowIterables(
        _excelRow([
          'T',
          'G',
          'V',
          'VM',
          'VF',
          'GEST',
          'TOT',
        ]),
        rowIndex,
      );

      rowIndex++;

      // Valeurs du résumé
      sheet.insertRowIterables(
        _excelRow([
          situation.taurions,
          situation.genisses,
          situation.vaches,
          situation.veauxMales,
          situation.veauxFemelles,
          situation.gestation,
          situation.total,
        ]),
        rowIndex,
      );

      final directory = await getApplicationDocumentsDirectory();

      final filename =
          'Fiche_${provider.troupeauSelectionne?.nom ?? 'betail'}_'
          '${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx';

      final file = File('${directory.path}/$filename');

      final bytes = excelFile.encode();

      if (bytes == null) {
        throw Exception('Impossible de générer le fichier Excel.');
      }

      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel sauvegardé : $filename'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Excel : $e'),
          ),
        );
      }
    }
  }
}