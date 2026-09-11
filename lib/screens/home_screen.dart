import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/troupeau_provider.dart';
import '../widgets/carte_situation.dart';
import '../models/enums.dart';
import 'mouvement_screen.dart';
import 'inventaire_screen.dart';
import 'historique_screen.dart';
import 'fiche_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Consumer<TroupeauProvider>(builder: (context, provider, child) {
        if (provider.isLoading && provider.proprietaires.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Fiche du bétail', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              background: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight))),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.table_chart), tooltip: 'Fiche papier', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FicheScreen()))),
              IconButton(icon: const Icon(Icons.history), tooltip: 'Historique', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriqueScreen()))),
            ],
          ),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Row(children: [Icon(Icons.person, color: Colors.green.shade700), const SizedBox(width: 12), Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<Proprietaire>(isExpanded: true, value: provider.proprietaireSelectionne, items: provider.proprietaires.map((p) => DropdownMenuItem(value: p, child: Text(p.nom, style: GoogleFonts.poppins()))).toList(), onChanged: (p) { if (p != null) provider.selectionnerProprietaire(p); }))), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _showAjouterProprietaire(context))])),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Row(children: [Icon(Icons.groups, color: Colors.green.shade700), const SizedBox(width: 12), Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<Troupeau>(isExpanded: true, value: provider.troupeauSelectionne, items: provider.troupeaux.map((t) => DropdownMenuItem(value: t, child: Text('${t.nom} ${t.code != null ? "(${t.code})" : ""}', style: GoogleFonts.poppins()))).toList(), onChanged: (t) { if (t != null) provider.selectionnerTroupeau(t); }))), IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _showAjouterTroupeau(context))]))
          ]))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Situation au ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)), IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.rafraichirDonnees())]))),
          SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverGrid(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 12, mainAxisSpacing: 12), delegate: SliverChildListDelegate([
            CarteSituation(titre: 'Taurions', valeur: provider.situation.taurions, icon: Icons.male, couleur: Colors.brown.shade600, sousTitre: 'T', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventaireScreen(categorie: CategorieAnimal.taurion)))),
            CarteSituation(titre: 'Génisses', valeur: provider.situation.genisses, icon: Icons.female, couleur: Colors.orange.shade600, sousTitre: 'G', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventaireScreen(categorie: CategorieAnimal.genisse)))),
            CarteSituation(titre: 'Vaches', valeur: provider.situation.vaches, icon: Icons.female, couleur: Colors.green.shade600, sousTitre: 'V', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventaireScreen(categorie: CategorieAnimal.vache)))),
            CarteSituation(titre: 'Veaux mâles', valeur: provider.situation.veauxMales, icon: Icons.male_outlined, couleur: Colors.blue.shade600, sousTitre: 'VM'),
            CarteSituation(titre: 'Veaux femelles', valeur: provider.situation.veauxFemelles, icon: Icons.female_outlined, couleur: Colors.purple.shade400, sousTitre: 'VF'),
            CarteSituation(titre: 'Total', valeur: provider.situation.total, icon: Icons.pets, couleur: Colors.teal.shade700, sousTitre: 'TOT'),
          ]))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: CarteGestation(valeur: provider.situation.gestation))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildResumeItem('Veaux total', provider.situation.veauxTotal, Icons.add_circle), Container(height: 40, width: 1, color: Colors.grey.shade300), _buildResumeItem('En gestation', provider.situation.gestation, Icons.pregnant_woman)]))))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Derniers mouvements', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)))),
          SliverList(delegate: SliverChildBuilderDelegate((context, index) { final mouv = provider.mouvementsRecents[index]; return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: ListTile(leading: CircleAvatar(backgroundColor: mouv.type.sens == 'entree' ? Colors.green.shade100 : mouv.type.sens == 'sortie' ? Colors.red.shade100 : Colors.blue.shade100, child: Icon(mouv.type.sens == 'entree' ? Icons.arrow_downward : mouv.type.sens == 'sortie' ? Icons.arrow_upward : Icons.folder_open, color: mouv.type.sens == 'entree' ? Colors.green : mouv.type.sens == 'sortie' ? Colors.red : Colors.blue)), title: Text('${mouv.type.label} – ${mouv.categorie.label}', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)), subtitle: Text('${mouv.quantite} tête(s) – ${DateFormat('dd/MM/yyyy').format(mouv.date)}', style: GoogleFonts.poppins(fontSize: 12)), trailing: mouv.prix != null ? Text('${mouv.prix!.toStringAsFixed(0)} F', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)) : null)); }, childCount: provider.mouvementsRecents.length > 5 ? 5 : provider.mouvementsRecents.length)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ]);
      }),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MouvementScreen())), icon: const Icon(Icons.add), label: const Text('Mouvement'), backgroundColor: Colors.green.shade700),
    );
  }

  Widget _buildResumeItem(String label, int value, IconData icon) => Column(children: [Icon(icon, color: Colors.grey.shade600), const SizedBox(height: 4), Text('$value', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600))]);

  void _showAjouterProprietaire(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('Nouveau propriétaire', style: GoogleFonts.poppins()), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nom')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')), ElevatedButton(onPressed: () { if (ctrl.text.isNotEmpty) { context.read<TroupeauProvider>().ajouterProprietaire(ctrl.text); Navigator.pop(ctx); } }, child: const Text('Ajouter'))]));
  }

  void _showAjouterTroupeau(BuildContext context) {
    final nomCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('Nouveau troupeau', style: GoogleFonts.poppins()), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom')), TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (ex : AH)'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')), ElevatedButton(onPressed: () { if (nomCtrl.text.isNotEmpty) { context.read<TroupeauProvider>().ajouterTroupeau(nomCtrl.text, code: codeCtrl.text); Navigator.pop(ctx); } }, child: const Text('Ajouter'))]));
  }
}
