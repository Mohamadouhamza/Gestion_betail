import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';

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
      backgroundColor: AppColors.fondEcran,
      appBar: AppBar(
        title: Text('Inventaire ${_filtreCategorie?.label ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _filtreCategorie == null,
                      onSelected: (_) {
                        setState(() => _filtreCategorie = null);
                        context.read<TroupeauProvider>().chargerLots();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...CategorieAnimal.values.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat.label),
                            selected: _filtreCategorie == cat,
                            onSelected: (_) {
                              setState(() => _filtreCategorie = cat);
                              context.read<TroupeauProvider>().chargerLots();
                            },
                          ),
                        )),
                  ]),
                ),
                if (_filtreCategorie == CategorieAnimal.taurion) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: FiltreAge.values
                          .map((age) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(age.label),
                                  selected: _filtreAge == age,
                                  onSelected: (_) {
                                    setState(() => _filtreAge = age);
                                    context.read<TroupeauProvider>().setFiltreAge(age);
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Consumer<TroupeauProvider>(
              builder: (context, provider, child) {
                final lots = _filtreCategorie == null
                    ? provider.lots
                    : provider.lots.where((l) => l.categorie == _filtreCategorie).toList();
                if (lots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.inventaireInactif, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Aucun lot', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lots.length,
                  itemBuilder: (context, index) {
                    final lot = lots[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForCategorie(lot.categorie),
                          child: Text(lot.categorie.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('${lot.quantite} ${lot.categorie.label}(s)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Âge : ${lot.ageAffichage}'),
                            if (lot.enGestation)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  lot.gestationAffichage,
                                  style: const TextStyle(color: AppColors.gestation, fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (lot.notes != null) Text('Note : ${lot.notes}', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                        trailing: lot.categorie == CategorieAnimal.vache
                            ? IconButton(
                                icon: GestationIcon(
                                  size: 26,
                                  color: lot.enGestation ? AppColors.gestation : Colors.grey.shade400,
                                ),
                                tooltip: lot.enGestation ? 'En gestation' : 'Marquer en gestation',
                                onPressed: () => _showGestationDialog(context, lot),
                              )
                            : null,
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
      case CategorieAnimal.taurion: return AppColors.taurion;
      case CategorieAnimal.genisse: return AppColors.genisse;
      case CategorieAnimal.vache: return AppColors.vache;
      case CategorieAnimal.veauMale: return AppColors.veauMale;
      case CategorieAnimal.veauFemelle: return AppColors.veauFemelle;
    }
  }

  void _showGestationDialog(BuildContext context, LotAnimal lot) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // État local au dialogue (corrige le bug où le switch/la date ne
            // se mettaient pas à jour visuellement dans la boîte de dialogue).
            bool gest = lot.enGestation;
            DateTime dateDebut = lot.dateGestation ?? DateTime.now();
            final terme = dateDebut.add(const Duration(days: LotAnimal.dureeGestationJours));

            return AlertDialog(
              title: Text('Gestation', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('En gestation'),
                    value: gest,
                    onChanged: (v) => setDialogState(() => gest = v),
                  ),
                  if (gest) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Début de la gestation'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(dateDebut)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dateDebut,
                          firstDate: DateTime.now().subtract(const Duration(days: 300)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => dateDebut = picked);
                      },
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gestation.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Terme calculé automatiquement (≈ 9 mois) :\n'
                        '${DateFormat('dd/MM/yyyy').format(terme)}\n'
                        'La gestation se clôturera toute seule à cette date.',
                        style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.gestation),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () {
                    context.read<TroupeauProvider>().toggleGestation(lot, gest, gest ? dateDebut : null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
