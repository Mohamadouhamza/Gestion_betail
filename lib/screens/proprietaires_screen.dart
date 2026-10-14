import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/carte_situation.dart';

/// Onglet "Propriétaire" (remplace l'ancien onglet "Historique", redondant
/// car déjà accessible via l'icône dans l'en-tête de l'accueil).
/// Permet de : voir la liste des propriétaires, en ajouter un NOUVEAU avec
/// son cheptel existant en une seule fois, et consulter la situation
/// (effectif par catégorie) propre à UN propriétaire donné — distincte de la
/// situation générale affichée à l'accueil.
class ProprietairesScreen extends StatelessWidget {
  const ProprietairesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondEcran,
      appBar: AppBar(
        title: Text('Propriétaires', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.vertPrincipal,
        icon: const Icon(Icons.person_add),
        label: Text('Nouveau propriétaire', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        onPressed: () => _showAjouterProprietaire(context),
      ),
      body: Consumer<TroupeauProvider>(
        builder: (context, provider, child) {
          if (provider.proprietaires.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucun propriétaire pour l\'instant.\nAjoutez-en un avec le bouton ci-dessous.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
            itemCount: provider.proprietaires.length,
            itemBuilder: (context, index) {
              final p = provider.proprietaires[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.vertPrincipal.withOpacity(0.15),
                    child: Text(
                      p.nom.isNotEmpty ? p.nom[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.vertPrincipal, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(p.nom, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    provider.definirProprietaireParDefaut(p);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProprietaireDetailScreen(proprietaire: p)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAjouterProprietaire(BuildContext context) {
    final nomCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final quantiteCtrls = {for (final c in CategorieAnimal.values) c: TextEditingController(text: '0')};
    final provider = context.read<TroupeauProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nouveau propriétaire', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nomCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
                  ),
                  const SizedBox(height: 20),
                  Text('Cheptel existant (optionnel)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Text(
                    'Ajouté directement au troupeau "${provider.troupeauSelectionne?.nom ?? '-'}" comme solde d\'ouverture (REPORT).',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: CategorieAnimal.values.map((cat) {
                      return SizedBox(
                        width: 130,
                        child: TextFormField(
                          controller: quantiteCtrls[cat],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '${cat.code} – ${cat.label}',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          validator: (v) {
                            final n = int.tryParse(v?.trim().isEmpty ?? true ? '0' : v!.trim());
                            if (n == null || n < 0) return 'Invalide';
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vertPrincipal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        final cheptel = <CategorieAnimal, int>{
                          for (final c in CategorieAnimal.values) c: int.tryParse(quantiteCtrls[c]!.text.trim()) ?? 0,
                        };
                        provider.ajouterProprietaireAvecCheptel(nomCtrl.text.trim(), cheptel: cheptel);
                        Navigator.pop(ctx);
                      },
                      child: Text('Ajouter', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Situation d'UN propriétaire précis, pour le troupeau actuellement
/// sélectionné (indépendante de la situation générale de l'accueil).
class ProprietaireDetailScreen extends StatefulWidget {
  final Proprietaire proprietaire;
  const ProprietaireDetailScreen({super.key, required this.proprietaire});

  @override
  State<ProprietaireDetailScreen> createState() => _ProprietaireDetailScreenState();
}

class _ProprietaireDetailScreenState extends State<ProprietaireDetailScreen> {
  late Future<Situation> _future;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    _future = context.read<TroupeauProvider>().getSituationPourProprietaire(widget.proprietaire.id!);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TroupeauProvider>();
    return Scaffold(
      backgroundColor: AppColors.fondEcran,
      appBar: AppBar(
        title: Text(widget.proprietaire.nom, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_charger),
          ),
        ],
      ),
      body: FutureBuilder<Situation>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Situation chez ${widget.proprietaire.nom} – Troupeau : ${provider.troupeauSelectionne?.nom ?? '-'}',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  CarteSituation(titre: 'Taurions', valeur: s.taurions, icon: AppIcons.taurion, couleur: AppColors.taurion, sousTitre: 'T'),
                  CarteSituation(titre: 'Génisses', valeur: s.genisses, icon: AppIcons.genisse, couleur: AppColors.genisse, sousTitre: 'G'),
                  CarteSituation(titre: 'Vaches', valeur: s.vaches, icon: AppIcons.vache, couleur: AppColors.vache, sousTitre: 'V'),
                  CarteSituation(titre: 'Veaux mâles', valeur: s.veauxMales, icon: AppIcons.veauMale, couleur: AppColors.veauMale, sousTitre: 'VM'),
                  CarteSituation(titre: 'Veaux femelles', valeur: s.veauxFemelles, icon: AppIcons.veauFemelle, couleur: AppColors.veauFemelle, sousTitre: 'VF'),
                  CarteSituation(titre: 'Total', valeur: s.total, icon: AppIcons.total, couleur: AppColors.total, sousTitre: 'TOT'),
                ],
              ),
              const SizedBox(height: 16),
              CarteGestation(valeur: s.gestation),
            ],
          );
        },
      ),
    );
  }
}
