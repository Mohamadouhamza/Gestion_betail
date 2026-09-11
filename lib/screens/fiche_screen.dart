import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/troupeau_provider.dart';

class FicheScreen extends StatelessWidget {
  const FicheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fiche de suivi', style: GoogleFonts.poppins()), backgroundColor: Colors.brown.shade700, foregroundColor: Colors.white),
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
}
