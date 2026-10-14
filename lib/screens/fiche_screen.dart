import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/troupeau_provider.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

/// Canal natif (Kotlin, voir MainActivity.kt) utilisé pour enregistrer
/// directement un fichier dans le dossier public "Téléchargements" de
/// l'appareil (visible immédiatement dans le gestionnaire de fichiers,
/// sans passer par le sélecteur de partage).
const MethodChannel _canalTelechargements = MethodChannel('gestion_betail/downloads');

/// ============================================================
/// STRUCTURE EXACTE DE LA FICHE PAPIER (source unique de vérité,
/// utilisée pour l'écran, le PDF et l'Excel afin de garantir des
/// colonnes rigoureusement identiques partout).
///
/// 3 niveaux d'en-tête, comme sur le papier :
///  - [group]    : grand groupe ("PERTES", "VENTE", "ACHAT", "NAIS",
///                 "SITUATION A DATE", "PROJECTIONS")
///  - [subgroup] : sous-groupe à l'intérieur d'un groupe (seule la paire
///                 VM/VF de "SITUATION A DATE" en a un : "VO", exactement
///                 comme sur la fiche papier où VO coiffe VM et VF)
///  - [label]    : libellé final de la colonne
/// ============================================================
class _ColSpec {
  final String group;
  final String subgroup;
  final String label;
  final double width;
  const _ColSpec(this.group, this.subgroup, this.label, this.width);
}

const List<_ColSpec> _cols = [
  _ColSpec('', '', 'DATE', 60),
  _ColSpec('', '', 'PROPRIET.', 82),
  _ColSpec('PERTES', '', 'T', 28),
  _ColSpec('PERTES', '', 'G', 28),
  _ColSpec('PERTES', '', 'V', 28),
  _ColSpec('PERTES', '', 'VM', 30),
  _ColSpec('PERTES', '', 'VF', 30),
  _ColSpec('VENTE', '', 'T', 28),
  _ColSpec('VENTE', '', 'G', 28),
  _ColSpec('VENTE', '', 'V', 28),
  _ColSpec('ACHAT', '', 'T', 28),
  _ColSpec('ACHAT', '', 'G', 28),
  _ColSpec('NAIS', '', 'M', 28),
  _ColSpec('NAIS', '', 'F', 28),
  _ColSpec('', '', 'BILA', 40),
  _ColSpec('SITUATION A DATE', '', 'T', 30),
  _ColSpec('SITUATION A DATE', '', 'G', 30),
  _ColSpec('SITUATION A DATE', '', 'V', 30),
  _ColSpec('SITUATION A DATE', 'VO', 'VM', 30),
  _ColSpec('SITUATION A DATE', 'VO', 'VF', 30),
  _ColSpec('SITUATION A DATE', '', 'TOT', 40),
  _ColSpec('PROJECTIONS', '', 'GEST', 40),
  _ColSpec('PROJECTIONS', '', 'DATE', 54),
  _ColSpec('PROJECTIONS', '', 'NOM.', 40),
  _ColSpec('', '', 'OBSERVATIONS', 150),
];

/// Hauteur FIXE de chaque ligne du tableau (écran + PDF) : c'est l'absence
/// de hauteur explicite qui faisait "respirer" le tableau selon le contenu
/// (colonnes PROPRIET./OBSERVATIONS en particulier) sur certains appareils.
const double _hauteurLigneEntete = 30;
const double _hauteurLigneDonnee = 26;

/// Tronque un texte pour qu'il tienne sur une seule ligne dans une cellule
/// de largeur fixe, au lieu de forcer la ligne entière à grandir.
String _tronquer(String texte, int maxCaracteres) {
  if (texte.length <= maxCaracteres) return texte;
  return '${texte.substring(0, maxCaracteres - 1)}…';
}

List<List<String>> _headerLignes() {
  // Ligne 1 : groupe principal (fusion visuelle par répétition de '')
  final l1 = <String>[];
  String? dernierGroupe;
  for (final c in _cols) {
    if (c.group.isEmpty) {
      l1.add(c.label);
      dernierGroupe = null;
    } else if (c.group != dernierGroupe) {
      l1.add(c.group);
      dernierGroupe = c.group;
    } else {
      l1.add('');
    }
  }

  // Ligne 2 : sous-groupe s'il existe (ex. "VO" pour VM/VF), sinon le
  // libellé final directement (ex. "T", "G", "BILA"...).
  final l2 = <String>[];
  String? dernierSousGroupe;
  for (final c in _cols) {
    if (c.group.isEmpty) {
      l2.add('');
    } else if (c.subgroup.isNotEmpty) {
      if (c.subgroup != dernierSousGroupe) {
        l2.add(c.subgroup);
        dernierSousGroupe = c.subgroup;
      } else {
        l2.add('');
      }
    } else {
      l2.add(c.label);
      dernierSousGroupe = null;
    }
  }

  // Ligne 3 : libellé final uniquement pour les colonnes qui ont un
  // sous-groupe (VM/VF sous VO) ; vide partout ailleurs.
  final l3 = <String>[for (final c in _cols) (c.group.isNotEmpty && c.subgroup.isNotEmpty) ? c.label : ''];

  return [l1, l2, l3];
}

/// true si cette fiche a besoin d'une 3e ligne d'en-tête (dès qu'un
/// sous-groupe existe, ex. VO).
bool get _aUnSousGroupe => _cols.any((c) => c.subgroup.isNotEmpty);

String _moisAnneeCourt(DateTime d) {
  const mois = ['jan', 'fév', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'];
  final yy = (d.year % 100).toString().padLeft(2, '0');
  return '${mois[d.month - 1]}-$yy';
}

List<String> _valeurs(FicheLigne l, {required bool afficherDate}) {
  String s(int v) => v == 0 ? '' : '$v';
  final dateAffichee = !afficherDate ? '' : (l.estReport ? 'REPORT' : DateFormat('dd/MM/yy').format(l.date));
  return [
    dateAffichee,
    _tronquer(l.proprietaire, 13),
    s(l.perteT), s(l.perteG), s(l.perteV), s(l.perteVM), s(l.perteVF),
    s(l.venteT), s(l.venteG), s(l.venteV),
    s(l.achatT), s(l.achatG),
    s(l.naisM), s(l.naisF),
    (l.estTotal && l.bila != null) ? '${l.bila}' : '',
    '${l.sitT}', '${l.sitG}', '${l.sitV}', '${l.sitVM}', '${l.sitVF}', '${l.sitTotal}',
    l.gest == 0 ? '' : '${l.gest}',
    l.dateProjection != null ? _moisAnneeCourt(l.dateProjection!) : '',
    '${l.nom}',
    _tronquer(l.observations, 36),
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
    final entetes = _headerLignes();

    DateTime? dernierDateAffichee;

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
      child: Column(
        children: [
          _buildEnteteRow(entetes[0], bg: const Color(0xFFE8D4C0), bold: true),
          _buildEnteteRow(entetes[1], bg: const Color(0xFFEFE0CE), bold: true),
          if (_aUnSousGroupe) _buildEnteteRow(entetes[2], bg: const Color(0xFFF2E8DC), bold: true),
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
          height: _hauteurLigneEntete,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, border: Border.all(color: Colors.grey.shade400, width: 0.5)),
          child: Text(
            valeurs[i],
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            maxLines: 1,
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
          height: _hauteurLigneDonnee,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: estTotal ? const Color(0xFFE8F5E9) : Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Text(
            valeurs[i],
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: estTotal ? FontWeight.bold : FontWeight.normal),
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
  // EXPORT PDF — cellules à taille RIGOUREUSEMENT fixe (largeur ET
  // hauteur) : avant, seule la largeur était imposée, et un texte un
  // peu long (nom de propriétaire, observation) faisait grandir la
  // hauteur de SA ligne uniquement, cassant l'alignement du tableau.
  // Le texte est maintenant tronqué à l'avance (_tronquer) pour tenir
  // sur une seule ligne, et chaque cellule a une hauteur Container
  // explicite + `maxLines: 1` + alignement centré.
  // ---------------------------------------------------------------
  Future<void> _exportPDF(BuildContext context) async {
    setState(() => _exportEnCours = true);
    try {
      final provider = context.read<TroupeauProvider>();
      final lignes = await provider.genererFicheLedger();
      final entetes = _headerLignes();

      final pdf = pw.Document();

      pw.Widget cell(String text, double width, double height, {bool bold = false, PdfColor? bg}) {
        return pw.Container(
          width: width,
          height: height,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 1.5),
          decoration: pw.BoxDecoration(color: bg, border: pw.Border.all(color: PdfColors.grey400, width: 0.4)),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 6.3, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
            textAlign: pw.TextAlign.center,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        );
      }

      pw.Widget entete(List<String> valeurs, PdfColor bg) {
        return pw.Row(
          children: List.generate(_cols.length, (i) => cell(valeurs[i], _cols[i].width, _hauteurLigneEntete, bold: true, bg: bg)),
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
            (i) => cell(valeurs[i], _cols[i].width, _hauteurLigneDonnee, bold: l.estTotal, bg: l.estTotal ? PdfColors.green50 : null),
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
            entete(entetes[0], PdfColors.orange100),
            entete(entetes[1], PdfColors.orange50),
            if (_aUnSousGroupe) entete(entetes[2], PdfColors.orange50),
            ...lignesWidgets,
          ],
        ),
      );

      final bytes = await pdf.save();
      if (!context.mounted) return;
      await _sauvegarderEtOuvrir(context, bytes, 'pdf', 'application/pdf');
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
      final entetes = _headerLignes();

      var excelDoc = xls.Excel.createExcel();
      excelDoc.rename('Sheet1', 'Fiche');
      final sheet = excelDoc['Fiche'];

      List<xls.CellValue?> versLigne(List<String> valeurs) =>
          valeurs.map<xls.CellValue?>((v) => xls.TextCellValue(v)).toList();

      var rowIndex = 0;
      sheet.insertRowIterables(versLigne(['FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL']), rowIndex++);
      sheet.insertRowIterables(versLigne(['Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}']), rowIndex++);
      rowIndex++; // ligne vide

      sheet.insertRowIterables(versLigne(entetes[0]), rowIndex++);
      sheet.insertRowIterables(versLigne(entetes[1]), rowIndex++);
      if (_aUnSousGroupe) sheet.insertRowIterables(versLigne(entetes[2]), rowIndex++);

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
      await _sauvegarderEtOuvrir(
        context,
        Uint8List.fromList(bytes),
        'xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Excel : $e')));
      }
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  // ---------------------------------------------------------------
  // SAUVEGARDE : nom de fichier "Fiche_Troupeau_jj-mm-aaaa.ext" et
  // écriture DIRECTE dans le dossier public Téléchargements (visible
  // immédiatement dans le gestionnaire de fichiers, sans action
  // supplémentaire), via un canal natif (MainActivity.kt / MediaStore
  // sur Android 10+). En parallèle, une copie est conservée dans le
  // dossier privé de l'app pour permettre le partage natif (bouton
  // "PARTAGER").
  //
  // Note sur le nom de fichier : le format demandé "jj/mm/année" utilise
  // des "/", interdits dans un nom de fichier — remplacés par des "-"
  // (Fiche_Troupeau_13-10-2026.pdf).
  // ---------------------------------------------------------------
  Future<void> _sauvegarderEtOuvrir(BuildContext context, Uint8List bytes, String extension, String mimeType) async {
    final filename = 'Fiche_Troupeau_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.$extension';

    bool sauvegardePublique = false;
    try {
      await _canalTelechargements.invokeMethod('saveToDownloads', {
        'fileName': filename,
        'bytes': bytes,
        'mimeType': mimeType,
      });
      sauvegardePublique = true;
    } catch (_) {
      sauvegardePublique = false;
    }

    // Copie locale (dossier privé de l'app) systématiquement conservée pour
    // le partage natif, que la sauvegarde publique ait réussi ou non.
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sauvegardePublique
              ? '$filename enregistré dans Téléchargements.'
              : '$filename enregistré (dossier de l\'application).',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'PARTAGER',
          onPressed: () => Share.shareXFiles([XFile(file.path)], text: filename),
        ),
      ),
    );
  }
}
