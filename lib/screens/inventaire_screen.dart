import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../providers/troupeau_provider.dart';

class InventaireScreen extends StatefulWidget {
  final CategorieAnimal? categorie;
  const InventaireScreen({super.key, this.categorie});
  @override
  State<InventaireScreen> createState() => _InventaireScreenState();
}

class _InventaireScreenState extends State<InventaireScreen> {
  CategorieAnimal? _filtreCategorie;
  FiltreAge _filtreAge = FiltreAge.tous;

  @override
  void initState() {
    super.initState();
    _filtreCategorie = widget.categorie;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TroupeauProvider>().chargerLots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventaire ${_filtreCategorie?.label ?? ''}', style: GoogleFonts.poppins()), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [FilterChip(label: const Text('Tous'), selected: _filtreCategorie == null, onSelected: (_) { setState(() => _filtreCategorie = null); context.read<TroupeauProvider>().chargerLots(); }), const SizedBox(width: 8), ...CategorieAnimal.values.map((cat) => Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(cat.label), selected: _filtreCategorie == cat, onSelected: (_) { setState(() => _filtreCategorie = cat); context.read<TroupeauProvider>().chargerLots(); })))])),
                if (_filtreCategorie == CategorieAnimal.taurion) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: FiltreAge.values.map((age) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(age.label), selected: _filtreAge == age, onSelected: (_) { setState(() => _filtreAge = age); context.read<TroupeauProvider>().setFiltreAge(age); }))).toList())),
                ],
              ],
            ),
          ),
          Expanded(
            child: Consumer<TroupeauProvider>(
              builder: (context, provider, child) {
                final lots = _filtreCategorie == null ? provider.lots : provider.lots.where((l) => l.categorie == _filtreCategorie).toList();
                if (lots.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), Text('Aucun lot', style: GoogleFonts.poppins(color: Colors.grey.shade600))]));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lots.length,
                  itemBuilder: (context, index) {
                    final lot = lots[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: _getColorForCategorie(lot.categorie), child: Text(lot.categorie.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        title: Text('${lot.quantite} ${lot.categorie.label}(s)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Âge : ${lot.ageAffichage}'), if (lot.notes != null) Text('Note : ${lot.notes}', style: TextStyle(color: Colors.grey.shade600))]),
                        trailing: lot.categorie == CategorieAnimal.vache ? IconButton(icon: Icon(Icons.pregnant_woman, color: lot.enGestation ? Colors.pink : Colors.grey), tooltip: lot.enGestation ? 'En gestation' : 'Marquer', onPressed: () { _showGestationDialog(context, lot); }) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCategorie(CategorieAnimal cat) {
    switch (cat) {
      case CategorieAnimal.taurion: return Colors.brown.shade600;
      case CategorieAnimal.genisse: return Colors.orange.shade600;
      case CategorieAnimal.vache: return Colors.green.shade600;
      case CategorieAnimal.veauMale: return Colors.blue.shade600;
      case CategorieAnimal.veauFemelle: return Colors.purple.shade400;
    }
  }

  void _showGestationDialog(BuildContext context, dynamic lot) {
    showDialog(
      context: context,
      builder: (ctx) {
        DateTime? dateGest = lot.dateGestation ?? DateTime.now();
        bool gest = lot.enGestation;
        return AlertDialog(
          title: Text('Gestation', style: GoogleFonts.poppins()),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SwitchListTile(title: const Text('En gestation'), value: gest, onChanged: (v) => gest = v),
            ListTile(title: Text('Date : ${dateGest.day}/${dateGest.month}/${dateGest.year}'), trailing: const Icon(Icons.calendar_today), onTap: () async { final picked = await showDatePicker(context: ctx, initialDate: dateGest, firstDate: DateTime.now().subtract(const Duration(days: 300)), lastDate: DateTime.now()); if (picked != null) dateGest = picked; }),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(onPressed: () { context.read<TroupeauProvider>().toggleGestation(lot, gest, gest ? dateGest : null); Navigator.pop(ctx); }, child: const Text('Valider')),
          ],
        );
      },
    );
  }
}
