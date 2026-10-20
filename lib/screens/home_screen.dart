import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/carte_situation.dart';
import 'ajouter_cheptel_screen.dart';
import 'fiche_screen.dart';
import 'historique_screen.dart';
import 'inventaire_screen.dart';
import 'nouveau_troupeau_screen.dart';
import 'scinder_troupeau_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondEcran,
      body: Consumer<TroupeauProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.proprietaires.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return CustomScrollView(
            slivers: [
              // En-tête FIXE : pas de expandedHeight / flexibleSpace / floating,
              // donc il ne rétrécit plus jamais pendant le défilement (hauteur
              // de toolbar standard, toujours la même).
              SliverAppBar(
                pinned: true,
                floating: false,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.vertPrincipal,
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  'Fiche du bétail',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(AppIcons.fiche),
                    tooltip: 'Fiche papier',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FicheScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.historique),
                    tooltip: 'Historique',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoriqueScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.groups,
                          color: AppColors.vertPrincipal,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Troupeau>(
                              isExpanded: true,
                              value: provider.troupeauSelectionne,
                              items: provider.troupeaux
                                  .map<DropdownMenuItem<Troupeau>>(
                                (Troupeau troupeau) {
                                  return DropdownMenuItem<Troupeau>(
                                    value: troupeau,
                                    child: Text(
                                      '${troupeau.nom} ${troupeau.code != null ? "(${troupeau.code})" : ""}',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  );
                                },
                              ).toList(),
                              onChanged: (Troupeau? troupeau) {
                                if (troupeau != null) {
                                  provider.selectionnerTroupeau(troupeau);
                                }
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Nouveau troupeau',
                          onPressed: () {
                            _showOptionsTroupeau(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Situation générale au ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      // Retour visuel explicite pendant le rafraîchissement
                      // (avant : aucun changement visible, l'utilisateur ne
                      // savait pas si l'appui avait été pris en compte).
                      IconButton(
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.vertPrincipal,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        onPressed: provider.isLoading
                            ? null
                            : () {
                                provider.rafraichirDonnees();
                              },
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate(
                    [
                      CarteSituation(
                        titre: 'Taurions',
                        valeur: provider.situation.taurions,
                        icon: AppIcons.taurion,
                        couleur: AppColors.taurion,
                        sousTitre: 'T',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InventaireScreen(
                                categorie: CategorieAnimal.taurion,
                              ),
                            ),
                          );
                        },
                      ),
                      CarteSituation(
                        titre: 'Génisses',
                        valeur: provider.situation.genisses,
                        icon: AppIcons.genisse,
                        couleur: AppColors.genisse,
                        sousTitre: 'G',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InventaireScreen(
                                categorie: CategorieAnimal.genisse,
                              ),
                            ),
                          );
                        },
                      ),
                      CarteSituation(
                        titre: 'Vaches',
                        valeur: provider.situation.vaches,
                        icon: AppIcons.vache,
                        couleur: AppColors.vache,
                        sousTitre: 'V',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InventaireScreen(
                                categorie: CategorieAnimal.vache,
                              ),
                            ),
                          );
                        },
                      ),
                      CarteSituation(
                        titre: 'Veaux mâles',
                        valeur: provider.situation.veauxMales,
                        icon: AppIcons.veauMale,
                        couleur: AppColors.veauMale,
                        sousTitre: 'VM',
                      ),
                      CarteSituation(
                        titre: 'Veaux femelles',
                        valeur: provider.situation.veauxFemelles,
                        icon: AppIcons.veauFemelle,
                        couleur: AppColors.veauFemelle,
                        sousTitre: 'VF',
                      ),
                      CarteSituation(
                        titre: 'Total',
                        valeur: provider.situation.total,
                        icon: AppIcons.total,
                        couleur: AppColors.total,
                        sousTitre: 'TOT',
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CarteGestation(
                    valeur: provider.situation.gestation,
                    detail: _detailProchainTerme(provider),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResumeItem(
                            'Veaux total',
                            provider.situation.veauxTotal,
                            const Icon(Icons.add_circle, color: Colors.grey),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          _buildResumeItem(
                            'En gestation',
                            provider.situation.gestation,
                            const GestationIcon(size: 24, color: AppColors.gestation),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Derniers mouvements',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mouv = provider.mouvementsRecents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: mouv.type.sens == 'entree'
                              ? Colors.green.shade100
                              : mouv.type.sens == 'sortie'
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                          child: Icon(
                            mouv.type.sens == 'entree'
                                ? Icons.arrow_downward
                                : mouv.type.sens == 'sortie'
                                    ? Icons.arrow_upward
                                    : Icons.folder_open,
                            color: mouv.type.sens == 'entree'
                                ? Colors.green
                                : mouv.type.sens == 'sortie'
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                        ),
                        title: Text(
                          '${mouv.type.label} – ${mouv.categorie.label}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${mouv.quantite} tête(s) – ${DateFormat('dd/MM/yyyy').format(mouv.date)}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: mouv.prix != null
                            ? Text(
                                '${mouv.prix!.toStringAsFixed(0)} F',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                  childCount: provider.mouvementsRecents.length > 5
                      ? 5
                      : provider.mouvementsRecents.length,
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 110),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumeItem(
    String label,
    int value,
    Widget icone,
  ) {
    return Column(
      children: [
        icone,
        const SizedBox(height: 4),
        Text(
          '$value',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Calcule la date de terme la plus proche parmi les vaches gestantes,
  /// pour affichage sur la carte "En gestation" (calcul 100% automatique).
  String? _detailProchainTerme(TroupeauProvider provider) {
    final termes = provider.lots
        .where((l) => l.categorie == CategorieAnimal.vache && l.enGestation)
        .map((l) => l.dateTermeGestation)
        .whereType<DateTime>()
        .toList()
      ..sort();
    if (termes.isEmpty) return null;
    final prochain = termes.first;
    final jours = prochain.difference(DateTime.now()).inDays;
    if (jours < 0) return 'Terme dépassé de ${-jours} j – vérifier la gestation';
    if (jours == 0) return 'Terme prévu aujourd\'hui';
    return 'Prochain terme dans $jours j (${DateFormat('dd/MM/yyyy').format(prochain)})';
  }

  /// Propose les deux façons de créer un troupeau :
  /// - "Nouveau troupeau" : ajout net (ex. troupeau reçu), ne retire rien.
  /// - "Scinder un troupeau existant" : prélève une partie d'un troupeau
  ///   existant pour en créer un nouveau.
  void _showOptionsTroupeau(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.vertPrincipal),
                title: Text('Nouveau troupeau', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ajoute un troupeau avec son propre cheptel.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NouveauTroupeauScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_split, color: Colors.deepOrange),
                title: Text('Scinder un troupeau existant', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: const Text('Prélève une partie du cheptel d\'un troupeau existant.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ScinderTroupeauScreen()));
                },
              ),
              if (context.read<TroupeauProvider>().troupeauSelectionne != null)
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                  title: Text('Ajouter un propriétaire à ce troupeau', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text('Ajoute un propriétaire (et son cheptel) au troupeau « ${context.read<TroupeauProvider>().troupeauSelectionne!.nom} ».'),
                  onTap: () {
                    final t = context.read<TroupeauProvider>().troupeauSelectionne!;
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AjouterCheptelScreen(troupeauFixe: t)));
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
