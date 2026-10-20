import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/cheptel_champs.dart';

/// Ajoute du cheptel (solde d'ouverture, "REPORT" sur la fiche) d'UN
/// propriétaire dans UN troupeau DÉJÀ existant. Deux points d'entrée :
///  - depuis l'accueil ("Ajouter un propriétaire à ce troupeau") : le
///    troupeau est imposé ([troupeauFixe]) et on choisit/crée le propriétaire ;
///  - depuis la fiche d'un propriétaire ("Ajouter du cheptel dans un
///    troupeau") : le propriétaire est imposé ([proprietaireFixe]) et on
///    choisit le troupeau.
class AjouterCheptelScreen extends StatefulWidget {
  final Troupeau? troupeauFixe;
  final Proprietaire? proprietaireFixe;

  const AjouterCheptelScreen({super.key, this.troupeauFixe, this.proprietaireFixe})
      : assert(troupeauFixe != null || proprietaireFixe != null);

  @override
  State<AjouterCheptelScreen> createState() => _AjouterCheptelScreenState();
}

class _AjouterCheptelScreenState extends State<AjouterCheptelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cheptel = CheptelControleurs();
  Troupeau? _troupeau;
  Proprietaire? _proprietaire;
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    _troupeau = widget.troupeauFixe;
    _proprietaire = widget.proprietaireFixe;
    if (_troupeau == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<TroupeauProvider>();
        if (provider.troupeaux.isNotEmpty) {
          setState(() => _troupeau = provider.troupeauSelectionne ?? provider.troupeaux.first);
        }
      });
    }
  }

  @override
  void dispose() {
    _cheptel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TroupeauProvider>();
    final titre = widget.troupeauFixe != null
        ? 'Ajouter un propriétaire'
        : 'Ajouter du cheptel';
    return Scaffold(
      appBar: AppBar(
        title: Text(titre, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.vertPrincipal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.troupeauFixe != null
                              ? 'Ce propriétaire rejoint le troupeau « ${widget.troupeauFixe!.nom} » avec le cheptel saisi (REPORT). Le reste du troupeau n\'est pas modifié.'
                              : 'Ce cheptel est ajouté à « ${widget.proprietaireFixe!.nom} » dans le troupeau choisi (REPORT). Les autres troupeaux ne sont pas modifiés.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.troupeauFixe == null)
                DropdownButtonFormField<Troupeau>(
                  value: _troupeau == null ? null : provider.troupeaux.cast<Troupeau?>().firstWhere((t) => t!.id == _troupeau!.id, orElse: () => null),
                  isExpanded: true,
                  decoration: InputDecoration(labelText: 'Troupeau *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: provider.troupeaux.map((t) => DropdownMenuItem(value: t, child: Text(t.nom, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (t) => setState(() => _troupeau = t),
                  validator: (t) => t == null ? 'Sélectionnez un troupeau' : null,
                ),
              if (widget.proprietaireFixe == null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Proprietaire>(
                        key: ValueKey('prop-${_proprietaire?.id}'),
                        value: _proprietaire == null ? null : provider.proprietaires.cast<Proprietaire?>().firstWhere((p) => p!.id == _proprietaire!.id, orElse: () => null),
                        isExpanded: true,
                        decoration: InputDecoration(labelText: 'Propriétaire *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        items: provider.proprietaires.map((p) => DropdownMenuItem(value: p, child: Text(p.nom, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (p) => setState(() => _proprietaire = p),
                        validator: (p) => p == null ? 'Sélectionnez un propriétaire' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton.filledTonal(
                        tooltip: 'Nouveau propriétaire',
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final p = await demanderNouveauProprietaire(context);
                          if (p != null && mounted) setState(() => _proprietaire = p);
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Text('Cheptel à ajouter', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CheptelChamps(controleurs: _cheptel),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _enregistrementEnCours ? null : _enregistrer,
                  child: _enregistrementEnCours
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('AJOUTER', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cheptel = _cheptel.valeurs();
    if (cheptel.values.every((q) => q == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez au moins une quantité.')),
      );
      return;
    }
    setState(() => _enregistrementEnCours = true);
    try {
      await context.read<TroupeauProvider>().attribuerCheptel(
            troupeauId: _troupeau!.id!,
            proprietaireId: _proprietaire!.id!,
            cheptel: cheptel,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cheptel ajouté')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }
}
