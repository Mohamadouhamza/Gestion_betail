import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';

/// "Scinder un troupeau existant" : crée un nouveau troupeau en prélevant
/// une partie du cheptel d'un troupeau existant (ex : séparer un troupeau de
/// 50 têtes en deux troupeaux de 25). Contrairement à "Nouveau troupeau",
/// les quantités saisies sont RETIRÉES du troupeau source.
class ScinderTroupeauScreen extends StatefulWidget {
  const ScinderTroupeauScreen({super.key});

  @override
  State<ScinderTroupeauScreen> createState() => _ScinderTroupeauScreenState();
}

class _ScinderTroupeauScreenState extends State<ScinderTroupeauScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  Troupeau? _troupeauSource;
  Proprietaire? _proprietaire;
  List<Proprietaire> _proprietairesAvecStock = [];
  Situation? _stockDisponible;
  bool _chargementStock = false;
  final Map<CategorieAnimal, TextEditingController> _quantiteCtrls = {
    for (final c in CategorieAnimal.values) c: TextEditingController(text: '0'),
  };
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TroupeauProvider>();
      if (provider.troupeaux.isNotEmpty) {
        setState(() => _troupeauSource = provider.troupeauSelectionne ?? provider.troupeaux.first);
        _chargerProprietairesEtStock();
      }
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _codeCtrl.dispose();
    for (final c in _quantiteCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chargerProprietairesEtStock() async {
    if (_troupeauSource?.id == null) return;
    setState(() {
      _chargementStock = true;
      _proprietaire = null;
      _stockDisponible = null;
    });
    final provider = context.read<TroupeauProvider>();
    final ids = await provider.getProprietaireIdsAvecStock(_troupeauSource!.id!);
    final props = provider.proprietaires.where((p) => ids.contains(p.id)).toList();
    if (!mounted) return;
    setState(() {
      _proprietairesAvecStock = props;
      _proprietaire = props.isNotEmpty ? props.first : null;
      _chargementStock = false;
    });
    if (_proprietaire != null) await _chargerStockProprietaire();
  }

  Future<void> _chargerStockProprietaire() async {
    if (_troupeauSource?.id == null || _proprietaire?.id == null) return;
    setState(() => _chargementStock = true);
    final s = await context.read<TroupeauProvider>().getSituationPourProprietaire(_proprietaire!.id!);
    if (!mounted) return;
    setState(() {
      _stockDisponible = s;
      _chargementStock = false;
    });
    _formKey.currentState?.validate();
  }

  int _maxPour(CategorieAnimal cat) => _stockDisponible?.getByCategorie(cat) ?? 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TroupeauProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Scinder un troupeau', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
                color: Colors.orange.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.call_split, color: Colors.deepOrange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Les quantités saisies ci-dessous seront RETIRÉES du troupeau source et transférées au nouveau troupeau.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (provider.troupeaux.isEmpty)
                Text('Aucun troupeau existant à scinder.', style: GoogleFonts.poppins(color: Colors.grey.shade600))
              else
                DropdownButtonFormField<Troupeau>(
                  value: _troupeauSource,
                  decoration: InputDecoration(labelText: 'Troupeau source *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: provider.troupeaux.map((t) => DropdownMenuItem(value: t, child: Text(t.nom))).toList(),
                  onChanged: (t) {
                    setState(() => _troupeauSource = t);
                    _chargerProprietairesEtStock();
                  },
                  validator: (t) => t == null ? 'Sélectionnez un troupeau source' : null,
                ),
              const SizedBox(height: 16),
              if (_chargementStock)
                const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
              else if (_proprietairesAvecStock.isEmpty)
                Text('Ce troupeau n\'a aucun cheptel à scinder.', style: GoogleFonts.poppins(color: Colors.grey.shade600))
              else
                DropdownButtonFormField<Proprietaire>(
                  value: _proprietaire,
                  decoration: InputDecoration(labelText: 'Propriétaire à scinder *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: _proprietairesAvecStock.map((p) => DropdownMenuItem(value: p, child: Text(p.nom))).toList(),
                  onChanged: (p) {
                    setState(() => _proprietaire = p);
                    _chargerStockProprietaire();
                  },
                  validator: (p) => p == null ? 'Sélectionnez un propriétaire' : null,
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomCtrl,
                decoration: InputDecoration(labelText: 'Nom du nouveau troupeau *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeCtrl,
                decoration: InputDecoration(labelText: 'Code (ex : AH2)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              Text('Quantités à prélever', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: CategorieAnimal.values.map((cat) {
                  final max = _maxPour(cat);
                  return SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: _quantiteCtrls[cat],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${cat.code} – ${cat.label}',
                        helperText: 'Dispo : $max',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim().isEmpty ? '0' : v!.trim());
                        if (n == null || n < 0) return 'Invalide';
                        if (n > max) return 'Max $max';
                        return null;
                      },
                    ),
                  );
                }).toList(),
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
                  onPressed: (_enregistrementEnCours || _proprietaire == null) ? null : _enregistrer,
                  child: _enregistrementEnCours
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('SCINDER LE TROUPEAU', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
    final quantites = <CategorieAnimal, int>{
      for (final c in CategorieAnimal.values) c: int.tryParse(_quantiteCtrls[c]!.text.trim()) ?? 0,
    };
    if (quantites.values.every((q) => q == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez au moins une quantité à prélever.')),
      );
      return;
    }
    setState(() => _enregistrementEnCours = true);
    try {
      await context.read<TroupeauProvider>().scinderTroupeau(
            troupeauSourceId: _troupeauSource!.id!,
            proprietaireId: _proprietaire!.id!,
            nomNouveauTroupeau: _nomCtrl.text.trim(),
            codeNouveauTroupeau: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
            quantites: quantites,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Troupeau scindé avec succès')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }
}
