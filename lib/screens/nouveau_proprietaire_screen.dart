import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/cheptel_champs.dart';

/// "Nouveau propriétaire" : nom + liste répétable de blocs
/// "troupeau + cheptel" (un propriétaire peut avoir du bétail dans plusieurs
/// troupeaux). Zéro bloc = propriétaire créé sans cheptel. Le cheptel saisi
/// est enregistré comme solde d'ouverture ("REPORT" sur la fiche).
class NouveauProprietaireScreen extends StatefulWidget {
  const NouveauProprietaireScreen({super.key});

  @override
  State<NouveauProprietaireScreen> createState() => _NouveauProprietaireScreenState();
}

class _BlocTroupeau {
  final Key key = UniqueKey();
  Troupeau? troupeau;
  final CheptelControleurs cheptel = CheptelControleurs();
}

class _NouveauProprietaireScreenState extends State<NouveauProprietaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final List<_BlocTroupeau> _blocs = [];
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TroupeauProvider>();
      if (provider.troupeauSelectionne != null && _blocs.isEmpty) {
        setState(() => _blocs.add(_BlocTroupeau()..troupeau = provider.troupeauSelectionne));
      }
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    for (final b in _blocs) {
      b.cheptel.dispose();
    }
    super.dispose();
  }

  void _supprimerBloc(_BlocTroupeau b) {
    setState(() => _blocs.remove(b));
    b.cheptel.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TroupeauProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouveau propriétaire', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
              TextFormField(
                controller: _nomCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: 'Nom *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Téléphone (optionnel)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 24),
              Text('Cheptel existant par troupeau (optionnel)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(
                'Enregistré comme solde d\'ouverture (REPORT) dans chaque troupeau choisi.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              if (provider.troupeaux.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    'Aucun troupeau n\'existe encore : le propriétaire sera créé sans cheptel.',
                    style: GoogleFonts.poppins(color: Colors.orange.shade800),
                  ),
                )
              else ...[
                ..._blocs.asMap().entries.map((e) => _construireBloc(provider, e.key, e.value)),
                OutlinedButton.icon(
                  onPressed: _blocs.length >= provider.troupeaux.length ? null : () => setState(() => _blocs.add(_BlocTroupeau())),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un troupeau'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.vertPrincipal,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
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
                      : Text('AJOUTER LE PROPRIÉTAIRE', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construireBloc(TroupeauProvider provider, int index, _BlocTroupeau bloc) {
    final dejaChoisis = _blocs.where((b) => b != bloc && b.troupeau != null).map((b) => b.troupeau!.id).toSet();
    final disponibles = provider.troupeaux.where((t) => !dejaChoisis.contains(t.id)).toList();
    final valeur = bloc.troupeau == null
        ? null
        : disponibles.cast<Troupeau?>().firstWhere((t) => t!.id == bloc.troupeau!.id, orElse: () => null);
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
                Text('Troupeau ${index + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.vertPrincipal)),
                const Spacer(),
                IconButton(
                  tooltip: 'Retirer ce troupeau',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _supprimerBloc(bloc),
                ),
              ],
            ),
            DropdownButtonFormField<Troupeau>(
              value: valeur,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'Troupeau *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: disponibles.map((t) => DropdownMenuItem(value: t, child: Text(t.nom, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (t) => setState(() => bloc.troupeau = t),
              validator: (t) => t == null ? 'Sélectionnez un troupeau' : null,
            ),
            const SizedBox(height: 14),
            CheptelChamps(controleurs: bloc.cheptel),
          ],
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enregistrementEnCours = true);
    final blocs = _blocs.map((b) => BlocTroupeauCheptel(b.troupeau!.id!, b.cheptel.valeurs())).toList();
    try {
      await context.read<TroupeauProvider>().ajouterProprietaireAvecCheptels(
            _nomCtrl.text.trim(),
            telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
            blocs: blocs,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Propriétaire ajouté')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }
}
