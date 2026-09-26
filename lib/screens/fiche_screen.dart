import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/troupeau_provider.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

/// ============================================================
/// STRUCTURE EXACTE DE LA FICHE PAPIER (source unique de vérité,
/// utilisée pour l'écran, le PDF et l'Excel afin de garantir des
/// colonnes rigoureusement identiques partout).
/// ============================================================
class _ColSpec {
  final String group; // '' si la colonne n'appartient à aucun groupe
  final String label;
  final double width;
  const _ColSpec(this.group, this.label, this.width);
}

const List<_ColSpec> _cols = [
  _ColSpec('', 'DATE', 62),
  _ColSpec('', 'PROPRIET.', 88),
  _ColSpec('PERTES', 'T', 30),
  _ColSpec('PERTES', 'G', 30),
  _ColSpec('PERTES', 'V', 30),
  _ColSpec('PERTES', 'VM', 32),
  _ColSpec('PERTES', 'VF', 32),
  _ColSpec('VENTE', 'T', 30),
  _ColSpec('VENTE', 'G', 30),
  _ColSpec('VENTE', 'V', 30),
  _ColSpec('ACHAT', 'T', 30),
  _ColSpec('ACHAT', 'G', 30),
  _ColSpec('NAIS', 'M', 30),
  _ColSpec('NAIS', 'F', 30),
  _ColSpec('', 'BILA', 42),
  _ColSpec('SITUATION A DATE', 'T', 32),
  _ColSpec('SITUATION A DATE', 'G', 32),
  _ColSpec('SITUATION A DATE', 'V', 32),
  _ColSpec('SITUATION A DATE', 'VM', 34),
  _ColSpec('SITUATION A DATE', 'VF', 34),
  _ColSpec('SITUATION A DATE', 'TOT', 44),
  _ColSpec('PROJECTIONS', 'GEST', 42),
  _ColSpec('PROJECTIONS', 'DATE', 58),
  _ColSpec('PROJECTIONS', 'NOM.', 42),
  _ColSpec('', 'OBSERVATIONS', 170),
];

List<String> _headerGroupeLigne() {
  final result = <String>[];
  String? dernierGroupe;
  for (final c in _cols) {
    if (c.group.isEmpty) {
      result.add(c.label);
      dernierGroupe = null;
    } else if (c.group != dernierGroupe) {
      result.add(c.group);
      dernierGroupe = c.group;
    } else {
      result.add('');
    }
  }
  return result;
}

List<String> _headerSousLigne() => _cols.map((c) => c.group.isEmpty ? '' : c.label).toList();

String _moisAnneeCourt(DateTime d) {
  const mois = ['jan', 'fév', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'];
  final yy = (d.year % 100).toString().padLeft(2, '0');
  return '${mois[d.month - 1]}-$yy';
}

List<String> _valeurs(FicheLigne l, {required bool afficherDate}) {
  String s(int v) => v == 0 ? '' : '$v';
  return [
    afficherDate ? DateFormat('dd/MM/yy').format(l.date) : '',
    l.proprietaire,
    s(l.perteT), s(l.perteG), s(l.perteV), s(l.perteVM), s(l.perteVF),
    s(l.venteT), s(l.venteG), s(l.venteV),
    s(l.achatT), s(l.achatG),
    s(l.naisM), s(l.naisF),
    (l.estTotal && l.bila != null) ? '${l.bila}' : '',
    '${l.sitT}', '${l.sitG}', '${l.sitV}', '${l.sitVM}', '${l.sitVF}', '${l.sitTotal}',
    l.gest == 0 ? '' : '${l.gest}',
    l.dateProjection != null ? _moisAnneeCourt(l.dateProjection!) : '',
    '${l.nom}',
    l.observations,
  ];
}

class FicheScreen extends StatefulWidget {
  const FicheScreen({super.key});

  @override
  State<FicheScreen> createState() => _FicheScreenState();
}

class _FicheScreenState extends State<FicheScreen> {
  Future<List<FicheLigne>>? _future;
  Object? _signature;
  bool _exportEnCours = false;

  void _assurerChargement(TroupeauProvider provider) {
    final sig = Object.hash(provider.troupeauSelectionne?.id, provider.mouvementsRecents.length, provider.lots.length);
    if (_signature != sig) {
      _signature = sig;
      _future = provider.genererFicheLedger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TroupeauProvider>();
    _assurerChargement(provider);
    final situation = provider.situation;

    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche de suivi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _exportEnCours
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter PDF',
            onPressed: _exportEnCours ? null : () => _exportPDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Exporter Excel',
            onPressed: _exportEnCours ? null : () => _exportExcel(context),
          ),
        ],
      ),
      body: FutureBuilder<List<FicheLigne>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lignes = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(
                  'Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                if (lignes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'Aucun mouvement enregistré pour ce troupeau.\nAjoutez un mouvement pour voir la fiche se remplir.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildTable(lignes),
                  ),
                const SizedBox(height: 24),
                Text('SITUATION ACTUELLE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildResumeCard('T', situation.taurions, AppColors.taurion),
                    _buildResumeCard('G', situation.genisses, AppColors.genisse),
                    _buildResumeCard('V', situation.vaches, AppColors.vache),
                    _buildResumeCard('VM', situation.veauxMales, AppColors.veauMale),
                    _buildResumeCard('VF', situation.veauxFemelles, AppColors.veauFemelle),
                    _buildResumeCard('GEST', situation.gestation, AppColors.gestation),
                    _buildResumeCard('TOT', situation.total, AppColors.total),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // TABLEAU (mêmes colonnes que le PDF/Excel : _cols / _valeurs)
  // ---------------------------------------------------------------
  Widget _buildTable(List<FicheLigne> lignes) {
    final groupeLigne = _headerGroupeLigne();
    final sousLigne = _headerSousLigne();

    DateTime? dernierDateAffichee;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
      child: Column(
        children: [
          _buildEnteteRow(groupeLigne, bg: const Color(0xFFE8D4C0), bold: true),
          _buildEnteteRow(sousLigne, bg: const Color(0xFFF2E8DC), bold: true),
          ...lignes.map((l) {
            final showDate = dernierDateAffichee != l.date;
            if (showDate) dernierDateAffichee = l.date;
            final valeurs = _valeurs(l, afficherDate: showDate);
            return _buildDonneeRow(valeurs, estTotal: l.estTotal);
          }),
        ],
      ),
    );
  }

  Widget _buildEnteteRow(List<String> valeurs, {required Color bg, bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_cols.length, (i) {
        return Container(
          width: _cols[i].width,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, border: Border.all(color: Colors.grey.shade400, width: 0.5)),
          child: Text(
            valeurs[i],
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    );
  }

  Widget _buildDonneeRow(List<String> valeurs, {required bool estTotal}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_cols.length, (i) {
        return Container(
          width: _cols[i].width,
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: estTotal ? const Color(0xFFE8F5E9) : Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Text(
            valeurs[i],
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: estTotal ? FontWeight.bold : FontWeight.normal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    );
  }

  Widget _buildResumeCard(String code, int valeur, Color couleur) {
    return Container(
      width: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: couleur.withOpacity(0.1), border: Border.all(color: couleur), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(code, style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('$valeur', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: couleur.withOpacity(0.85))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // EXPORT PDF
  // ---------------------------------------------------------------
  Future<void> _exportPDF(BuildContext context) async {
    setState(() => _exportEnCours = true);
    try {
      final provider = context.read<TroupeauProvider>();
      final lignes = await provider.genererFicheLedger();
      final groupeLigne = _headerGroupeLigne();
      final sousLigne = _headerSousLigne();

      final pdf = pw.Document();

      pw.Widget cell(String text, double width, {bool bold = false, PdfColor? bg}) {
        return pw.Container(
          width: width,
          padding: const pw.EdgeInsets.all(2),
          decoration: pw.BoxDecoration(color: bg, border: pw.Border.all(color: PdfColors.grey400, width: 0.4)),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 6.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: pw.TextAlign.center),
        );
      }

      pw.Widget entete(List<String> valeurs, PdfColor bg) {
        return pw.Row(
          children: List.generate(_cols.length, (i) => cell(valeurs[i], _cols[i].width, bold: true, bg: bg)),
        );
      }

      DateTime? dernierDateAffichee;
      final lignesWidgets = <pw.Widget>[];
      for (final l in lignes) {
        final showDate = dernierDateAffichee != l.date;
        if (showDate) dernierDateAffichee = l.date;
        final valeurs = _valeurs(l, afficherDate: showDate);
        lignesWidgets.add(pw.Row(
          children: List.generate(
            _cols.length,
            (i) => cell(valeurs[i], _cols[i].width, bold: l.estTotal, bg: l.estTotal ? PdfColors.green50 : null),
          ),
        ));
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) => [
            pw.Text('FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            entete(groupeLigne, PdfColors.orange100),
            entete(sousLigne, PdfColors.orange50),
            ...lignesWidgets,
          ],
        ),
      );

      final bytes = await pdf.save();
      if (!context.mounted) return;
      await _sauvegarderEtOuvrir(context, bytes, 'pdf', 'Fiche');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur PDF : $e')));
      }
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  // ---------------------------------------------------------------
  // EXPORT EXCEL (excel ^4.0.6 : chaque valeur doit être un CellValue)
  // ---------------------------------------------------------------
  Future<void> _exportExcel(BuildContext context) async {
    setState(() => _exportEnCours = true);
    try {
      final provider = context.read<TroupeauProvider>();
      final lignes = await provider.genererFicheLedger();

      var excelDoc = xls.Excel.createExcel();
      excelDoc.rename('Sheet1', 'Fiche');
      final sheet = excelDoc['Fiche'];

      List<xls.CellValue?> versLigne(List<String> valeurs) =>
          valeurs.map<xls.CellValue?>((v) => xls.TextCellValue(v)).toList();

      var rowIndex = 0;
      sheet.insertRowIterables(versLigne(['FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL']), rowIndex++);
      sheet.insertRowIterables(versLigne(['Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}']), rowIndex++);
      rowIndex++; // ligne vide

      sheet.insertRowIterables(versLigne(_headerGroupeLigne()), rowIndex++);
      sheet.insertRowIterables(versLigne(_headerSousLigne()), rowIndex++);

      DateTime? dernierDateAffichee;
      for (final l in lignes) {
        final showDate = dernierDateAffichee != l.date;
        if (showDate) dernierDateAffichee = l.date;
        sheet.insertRowIterables(versLigne(_valeurs(l, afficherDate: showDate)), rowIndex++);
      }

      rowIndex++;
      sheet.insertRowIterables(versLigne(['SITUATION ACTUELLE']), rowIndex++);
      sheet.insertRowIterables(versLigne(['T', 'G', 'V', 'VM', 'VF', 'GEST', 'TOT']), rowIndex++);
      final s = provider.situation;
      sheet.insertRowIterables(
        versLigne(['${s.taurions}', '${s.genisses}', '${s.vaches}', '${s.veauxMales}', '${s.veauxFemelles}', '${s.gestation}', '${s.total}']),
        rowIndex++,
      );

      final bytes = excelDoc.encode();
      if (bytes == null) throw Exception('Échec de la génération du fichier Excel');
      if (!context.mounted) return;
      await _sauvegarderEtOuvrir(context, Uint8List.fromList(bytes), 'xlsx', 'Fiche');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Excel : $e')));
      }
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  // ---------------------------------------------------------------
  // SAUVEGARDE + OUVERTURE RÉELLE DU FICHIER (+ partage en secours)
  // ---------------------------------------------------------------
  Future<void> _sauvegarderEtOuvrir(BuildContext context, Uint8List bytes, String extension, String prefixe) async {
    final provider = context.read<TroupeauProvider>();
    final nomTroupeau = (provider.troupeauSelectionne?.nom ?? 'betail').replaceAll(RegExp(r'\s+'), '_');
    final horodatage = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final filename = '${prefixe}_${nomTroupeau}_$horodatage.$extension';

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    if (!context.mounted) return;

    OpenResult? resultat;
    try {
      resultat = await OpenFile.open(file.path);
    } catch (_) {
      resultat = null;
    }

    if (!context.mounted) return;

    final ouvertureReussie = resultat != null && resultat.type == ResultType.done;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ouvertureReussie
              ? '$filename généré et ouvert'
              : '$filename généré. Appuie sur PARTAGER pour l\'enregistrer ou l\'ouvrir.',
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'PARTAGER',
          onPressed: () => Share.shareXFiles([XFile(file.path)], text: filename),
        ),
      ),
    );
  }
}
