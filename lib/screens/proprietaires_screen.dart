import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/carte_situation.dart';
import 'ajouter_cheptel_screen.dart';
import 'nouveau_proprietaire_screen.dart';

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
      // Le bouton est dans un Stack (et non dans Scaffold.floatingActionButton) :
      // ce Scaffold est imbriqué dans celui de la navigation, dont la barre
      // flottante est dessinée PAR-DESSUS le corps (extendBody) — le FAB
      // standard se retrouvait caché derrière elle. Ici il est ancré au-dessus
      // de la barre, quelle que soit la taille de l'écran.
      body: Stack(
        children: [
          Positioned.fill(child: _liste()),
          Positioned(
            right: 16,
            bottom: _decalageAuDessusDeLaNavbar(context),
            child: FloatingActionButton.extended(
              heroTag: null,
              backgroundColor: AppColors.vertPrincipal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: Text('Nouveau propriétaire', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NouveauProprietaireScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Distance entre le bas de l'écran et le bas du bouton flottant : hauteur
  /// de la barre de navigation flottante (68) + sa marge basse (au moins 14,
  /// ou la zone de gestes du système si elle est plus grande) + un espace.
  static double _decalageAuDessusDeLaNavbar(BuildContext context) {
    final bas = MediaQuery.of(context).viewPadding.bottom;
    return (bas > 14 ? bas : 14) + 68 + 14;
  }

  Widget _liste() {
    return Consumer<TroupeauProvider>(
        builder: (context, provider, child) {
          if (provider.proprietaires.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucun propriétaire pour l\'instant.\nAjoutez-en un avec le bouton vert « Nouveau propriétaire ».',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 200),
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
                    (p.telephone != null && p.telephone!.isNotEmpty) ? p.telephone! : 'Appuyez pour voir sa situation',
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

  Future<void> _ajouterCheptel() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AjouterCheptelScreen(proprietaireFixe: widget.proprietaire)),
    );
    if (ok == true && mounted) setState(_charger);
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _ajouterCheptel,
                icon: const Icon(Icons.add_circle_outline),
                label: Text('Ajouter du cheptel dans un troupeau', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vertPrincipal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
