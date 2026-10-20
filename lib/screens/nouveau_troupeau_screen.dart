import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/cheptel_champs.dart';

/// "Nouveau troupeau" : un troupeau peut contenir le bétail de PLUSIEURS
/// propriétaires (comme sur la fiche papier : ABDOUL et ALI dans le même
/// troupeau). On saisit donc une liste répétable de blocs "propriétaire +
/// cheptel" (zéro, un ou plusieurs). Le cheptel saisi s'AJOUTE, sans rien
/// retirer à aucun troupeau existant. Pour prélever une partie d'un
/// troupeau existant, voir ScinderTroupeauScreen.
class NouveauTroupeauScreen extends StatefulWidget {
  const NouveauTroupeauScreen({super.key});

  @override
  State<NouveauTroupeauScreen> createState() => _NouveauTroupeauScreenState();
}

class _BlocProprietaire {
  final Key key = UniqueKey();
  Proprietaire? proprietaire;
  final CheptelControleurs cheptel = CheptelControleurs();
}

class _NouveauTroupeauScreenState extends State<NouveauTroupeauScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final List<_BlocProprietaire> _blocs = [_BlocProprietaire()];
  bool _enregistrementEnCours = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _codeCtrl.dispose();
    for (final b in _blocs) {
      b.cheptel.dispose();
    }
    super.dispose();
  }

  void _ajouterBloc() => setState(() => _blocs.add(_BlocProprietaire()));

  void _supprimerBloc(_BlocProprietaire b) {
    setState(() => _blocs.remove(b));
    b.cheptel.dispose();
  }

  Future<void> _creerProprietairePour(_BlocProprietaire b) async {
    final p = await demanderNouveauProprietaire(context);
    if (p != null && mounted) setState(() => b.proprietaire = p);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TroupeauProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouveau troupeau', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.vertPrincipal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Un troupeau peut réunir le bétail de plusieurs propriétaires. Le cheptel saisi est ajouté sans rien retirer à vos troupeaux existants.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomCtrl,
                autofocus: true,
                decoration: InputDecoration(labelText: 'Nom du troupeau *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeCtrl,
                decoration: InputDecoration(labelText: 'Code (ex : AH)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 24),
              Text('Propriétaires et cheptel (optionnel)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._blocs.asMap().entries.map((e) => _construireBloc(provider, e.key, e.value)),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _ajouterBloc,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Ajouter un propriétaire'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.vertPrincipal,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
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
                      : Text('CRÉER LE TROUPEAU', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construireBloc(TroupeauProvider provider, int index, _BlocProprietaire bloc) {
    // Un propriétaire ne peut figurer qu'une fois dans le même troupeau.
    final dejaChoisis = _blocs.where((b) => b != bloc && b.proprietaire != null).map((b) => b.proprietaire!.id).toSet();
    final disponibles = provider.proprietaires.where((p) => !dejaChoisis.contains(p.id)).toList();
    return Card(
      key: bloc.key,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Propriétaire ${index + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.vertPrincipal)),
                const Spacer(),
                IconButton(
                  tooltip: 'Retirer ce propriétaire',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _supprimerBloc(bloc),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<Proprietaire>(
                    key: ValueKey('prop-${bloc.key}-${bloc.proprietaire?.id}'),
                    value: bloc.proprietaire != null && disponibles.any((p) => p.id == bloc.proprietaire!.id)
                        ? disponibles.firstWhere((p) => p.id == bloc.proprietaire!.id)
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: 'Propriétaire *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: disponibles.map((p) => DropdownMenuItem(value: p, child: Text(p.nom, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (p) => setState(() => bloc.proprietaire = p),
                    validator: (p) => p == null ? 'Sélectionnez un propriétaire' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton.filledTonal(
                    tooltip: 'Nouveau propriétaire',
                    icon: const Icon(Icons.add),
                    onPressed: () => _creerProprietairePour(bloc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Cheptel de ce propriétaire', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            CheptelChamps(controleurs: bloc.cheptel),
          ],
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enregistrementEnCours = true);
    final blocs = _blocs
        .map((b) => BlocProprietaireCheptel(b.proprietaire!.id!, b.cheptel.valeurs()))
        .toList();
    try {
      await context.read<TroupeauProvider>().ajouterTroupeauAvecProprietaires(
            _nomCtrl.text.trim(),
            code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
            blocs: blocs,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Troupeau créé')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }
}
