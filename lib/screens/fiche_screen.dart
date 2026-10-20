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

/// true si cette fiche a besoin d'une 3e ligne d'en-tête (dès qu'un
/// sous-groupe existe, ex. VO).
bool get _aUnSousGroupe => _cols.any((c) => c.subgroup.isNotEmpty);

/// Nombre de lignes d'en-tête (3 avec VO, sinon 2).
int get _nbLignesEntete => _aUnSousGroupe ? 3 : 2;

/// Une cellule d'en-tête FUSIONNÉE, positionnée sur la grille des colonnes
/// et des lignes d'en-tête (comme le tableau papier : "PERTES" couvre ses 5
/// colonnes, "VO" couvre VM+VF, "DATE"/"PROPRIET."/"BILA"/"OBSERVATIONS"
/// couvrent toute la hauteur de l'en-tête...).
class _EnteteCell {
  final int col;
  final int colSpan;
  final int row;
  final int rowSpan;
  final String text;
  const _EnteteCell(this.col, this.colSpan, this.row, this.rowSpan, this.text);
}

List<_EnteteCell> _enteteCells() {
  final cells = <_EnteteCell>[];
  final nb = _nbLignesEntete;
  var i = 0;
  while (i < _cols.length) {
    final c = _cols[i];
    if (c.group.isEmpty) {
      // Colonne isolée : fusion verticale sur toute la hauteur.
      cells.add(_EnteteCell(i, 1, 0, nb, c.label));
      i++;
      continue;
    }
    // Groupe : titre fusionné sur ses colonnes (ligne 0).
    var fin = i;
    while (fin + 1 < _cols.length && _cols[fin + 1].group == c.group) {
      fin++;
    }
    cells.add(_EnteteCell(i, fin - i + 1, 0, 1, c.group));

    var j = i;
    while (j <= fin) {
      final cj = _cols[j];
      if (cj.subgroup.isEmpty) {
        // Libellé final : fusionné sur les lignes restantes.
        cells.add(_EnteteCell(j, 1, 1, nb - 1, cj.label));
        j++;
      } else {
        var finSous = j;
        while (finSous + 1 <= fin && _cols[finSous + 1].subgroup == cj.subgroup) {
          finSous++;
        }
        cells.add(_EnteteCell(j, finSous - j + 1, 1, 1, cj.subgroup));
        for (var k = j; k <= finSous; k++) {
          cells.add(_EnteteCell(k, 1, 2, 1, _cols[k].label));
        }
        j = finSous + 1;
      }
    }
    i = fin + 1;
  }
  return cells;
}

double _xDe(int col) {
  var x = 0.0;
  for (var i = 0; i < col; i++) {
    x += _cols[i].width;
  }
  return x;
}

double _largeurSpan(int col, int span) {
  var w = 0.0;
  for (var i = col; i < col + span; i++) {
    w += _cols[i].width;
  }
  return w;
}

double get _largeurTotale => _largeurSpan(0, _cols.length);

String _moisAnneeCourt(DateTime d) {
  const mois = ['jan', 'fév', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'];
  final yy = (d.year % 100).toString().padLeft(2, '0');
  return '${mois[d.month - 1]}-$yy';
}

/// Un bloc = tous les lignes d'une même date (une ligne par propriétaire
/// + la ligne TOTAL). La cellule DATE est UNE SEULE cellule fusionnée sur
/// toute la hauteur du bloc, comme sur la fiche papier.
class _BlocFiche {
  final DateTime date;
  final List<FicheLigne> lignes = [];
  _BlocFiche(this.date);

  /// "REPORT" pour un solde d'ouverture, sinon la date.
  String get dateLabel =>
      (lignes.isNotEmpty && lignes.last.estReport) ? 'REPORT' : DateFormat('dd/MM/yy').format(date);
}

List<_BlocFiche> _grouperEnBlocs(List<FicheLigne> lignes) {
  final blocs = <_BlocFiche>[];
  for (final l in lignes) {
    if (blocs.isEmpty || blocs.last.date != l.date) {
      blocs.add(_BlocFiche(l.date));
    }
    blocs.last.lignes.add(l);
  }
  return blocs;
}

/// Valeurs d'une ligne SANS la colonne DATE (qui est fusionnée par bloc) :
/// PROPRIET. ... OBSERVATIONS, soit `_cols.length - 1` valeurs.
List<String> _valeurs(FicheLigne l) {
  String s(int v) => v == 0 ? '' : '$v';
  return [
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
    final blocs = _grouperEnBlocs(lignes);
    return Container(
      width: _largeurTotale + 2,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEntete(),
          ...blocs.map(_buildBloc),
        ],
      ),
    );
  }

  /// En-tête à cellules VRAIMENT fusionnées (positionnées sur la grille).
  Widget _buildEntete() {
    const couleurs = [Color(0xFFE8D4C0), Color(0xFFEFE0CE), Color(0xFFF2E8DC)];
    return SizedBox(
      width: _largeurTotale,
      height: _nbLignesEntete * _hauteurLigneEntete,
      child: Stack(
        children: _enteteCells().map((h) {
          return Positioned(
            left: _xDe(h.col),
            top: h.row * _hauteurLigneEntete,
            width: _largeurSpan(h.col, h.colSpan),
            height: h.rowSpan * _hauteurLigneEntete,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: couleurs[h.row],
                border: Border.all(color: Colors.grey.shade400, width: 0.5),
              ),
              child: Text(
                h.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Un bloc de date : UNE cellule DATE fusionnée (pas de bordure interne)
  /// à gauche, et les lignes propriétaires + TOTAL à droite.
  Widget _buildBloc(_BlocFiche bloc) {
    final n = bloc.lignes.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _cols[0].width,
          height: n * _hauteurLigneDonnee,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 0.5)),
          child: Text(
            bloc.dateLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: bloc.lignes.map(_buildDonneeRow).toList(),
        ),
      ],
    );
  }

  Widget _buildDonneeRow(FicheLigne l) {
    final valeurs = _valeurs(l);
    final estTotal = l.estTotal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_cols.length - 1, (i) {
        return Container(
          width: _cols[i + 1].width,
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
      final blocs = _grouperEnBlocs(lignes);

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

      // En-tête à cellules fusionnées, positionnées sur la grille.
      final couleursEntete = [PdfColors.orange100, PdfColors.orange50, PdfColors.orange50];
      pw.Widget entete() {
        return pw.SizedBox(
          width: _largeurTotale,
          height: _nbLignesEntete * _hauteurLigneEntete,
          child: pw.Stack(
            children: _enteteCells().map((h) {
              return pw.Positioned(
                left: _xDe(h.col),
                top: h.row * _hauteurLigneEntete,
                child: cell(
                  h.text,
                  _largeurSpan(h.col, h.colSpan),
                  h.rowSpan * _hauteurLigneEntete,
                  bold: true,
                  bg: couleursEntete[h.row],
                ),
              );
            }).toList(),
          ),
        );
      }

      // Un bloc par date : cellule DATE fusionnée sur toute la hauteur.
      pw.Widget bloc(_BlocFiche b) {
        final n = b.lignes.length;
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            cell(b.dateLabel, _cols[0].width, n * _hauteurLigneDonnee, bold: true, bg: PdfColors.white),
            pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: b.lignes.map((l) {
                final valeurs = _valeurs(l);
                return pw.Row(
                  children: List.generate(
                    _cols.length - 1,
                    (i) => cell(valeurs[i], _cols[i + 1].width, _hauteurLigneDonnee, bold: l.estTotal, bg: l.estTotal ? PdfColors.green50 : null),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) => [
            pw.Text('FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            entete(),
            ...blocs.map(bloc),
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
  // EXPORT EXCEL (excel ^4.0.6 : chaque valeur doit être un CellValue).
  // Les cellules d'en-tête et la colonne DATE de chaque bloc sont
  // FUSIONNÉES (sheet.merge), comme sur la fiche papier.
  // ---------------------------------------------------------------
  Future<void> _exportExcel(BuildContext context) async {
    setState(() => _exportEnCours = true);
    try {
      final provider = context.read<TroupeauProvider>();
      final lignes = await provider.genererFicheLedger();
      final blocs = _grouperEnBlocs(lignes);

      var excelDoc = xls.Excel.createExcel();
      excelDoc.rename('Sheet1', 'Fiche');
      final sheet = excelDoc['Fiche'];

      List<xls.CellValue?> versLigne(List<String> valeurs) =>
          valeurs.map<xls.CellValue?>((v) => xls.TextCellValue(v)).toList();

      xls.CellIndex idx(int col, int row) => xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

      var rowIndex = 0;
      sheet.insertRowIterables(versLigne(['FICHE DE SUIVI DE L\'ÉVOLUTION DU BÉTAIL']), rowIndex++);
      sheet.insertRowIterables(versLigne(['Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}']), rowIndex++);
      rowIndex++; // ligne vide

      // En-tête : on écrit le texte dans la cellule en haut à gauche de
      // chaque zone, puis on fusionne la zone.
      final debutEntete = rowIndex;
      final cellulesEntete = _enteteCells();
      final grilleEntete = List.generate(_nbLignesEntete, (_) => List<String>.filled(_cols.length, ''));
      for (final h in cellulesEntete) {
        grilleEntete[h.row][h.col] = h.text;
      }
      for (final ligne in grilleEntete) {
        sheet.insertRowIterables(versLigne(ligne), rowIndex++);
      }
      for (final h in cellulesEntete) {
        if (h.colSpan > 1 || h.rowSpan > 1) {
          sheet.merge(
            idx(h.col, debutEntete + h.row),
            idx(h.col + h.colSpan - 1, debutEntete + h.row + h.rowSpan - 1),
          );
        }
      }

      // Blocs de dates : DATE fusionnée sur toutes les lignes du bloc.
      for (final b in blocs) {
        final debutBloc = rowIndex;
        for (var k = 0; k < b.lignes.length; k++) {
          sheet.insertRowIterables(
            versLigne([k == 0 ? b.dateLabel : '', ..._valeurs(b.lignes[k])]),
            rowIndex++,
          );
        }
        if (b.lignes.length > 1) {
          sheet.merge(idx(0, debutBloc), idx(0, rowIndex - 1));
        }
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
  // écriture DIRECTE dans le dossier public Téléchargements via un canal
  // natif (MainActivity.kt / MediaStore sur Android 10+). En parallèle,
  // une copie est conservée dans le dossier privé de l'app pour permettre
  // le partage natif (bouton "PARTAGER").
  //
  // Si l'écriture native échoue, l'erreur EXACTE est désormais affichée
  // (fenêtre de dialogue copiable) au lieu d'être avalée : elle permet de
  // diagnostiquer précisément la cause sur l'appareil.
  //
  // Note sur le nom de fichier : le format demandé "jj/mm/année" utilise
  // des "/", interdits dans un nom de fichier — remplacés par des "-"
  // (Fiche_Troupeau_13-10-2026.pdf).
  // ---------------------------------------------------------------
  Future<void> _sauvegarderEtOuvrir(BuildContext context, Uint8List bytes, String extension, String mimeType) async {
    final filename = 'Fiche_Troupeau_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.$extension';

    String? emplacementPublic;
    String? erreurNative;
    try {
      final retour = await _canalTelechargements.invokeMethod<String>('saveToDownloads', {
        'fileName': filename,
        'bytes': bytes,
        'mimeType': mimeType,
      });
      emplacementPublic = retour ?? 'Téléchargements/$filename';
      debugPrint('Fichier enregistré : $emplacementPublic');
    } on PlatformException catch (e) {
      erreurNative = 'PlatformException\ncode : ${e.code}\nmessage : ${e.message}\ndétails : ${e.details}';
    } on MissingPluginException catch (e) {
      erreurNative = 'MissingPluginException : le code natif (MainActivity.kt) n\'est pas enregistré dans cette version installée.\n${e.message ?? ''}';
    } catch (e) {
      erreurNative = '${e.runtimeType} : $e';
    }
    if (erreurNative != null) {
      debugPrint('Échec saveToDownloads : $erreurNative');
    }

    // Copie locale (dossier privé de l'app) systématiquement conservée pour
    // le partage natif, que la sauvegarde publique ait réussi ou non.
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    if (!context.mounted) return;

    if (erreurNative == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$filename enregistré dans Téléchargements.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'PARTAGER',
            onPressed: () => Share.shareXFiles([XFile(file.path)], text: filename),
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Enregistrement dans Téléchargements impossible', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$filename n\'a pas pu être écrit dans le dossier Téléchargements. '
                'Il reste disponible via PARTAGER (envoyez-le vers Fichiers, WhatsApp, Drive…).',
              ),
              const SizedBox(height: 12),
              Text('Erreur technique :', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              SelectableText(erreurNative!, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: erreurNative!)),
            child: const Text('COPIER L\'ERREUR'),
          ),
          TextButton(
            onPressed: () => Share.shareXFiles([XFile(file.path)], text: filename),
            child: const Text('PARTAGER'),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('FERMER')),
        ],
      ),
    );
  }
}
