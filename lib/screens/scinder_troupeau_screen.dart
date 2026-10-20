import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/cheptel_champs.dart';

/// "Scinder un troupeau existant" : crée un nouveau troupeau en prélevant
/// une partie du cheptel d'un troupeau existant (ex : séparer un troupeau de
/// 50 têtes en deux troupeaux de 25). On peut prélever chez PLUSIEURS
/// propriétaires du troupeau source en une seule opération ; pour chacun,
/// les quantités sont plafonnées à son stock réel dans ce troupeau.
/// Contrairement à "Nouveau troupeau", les quantités saisies sont RETIRÉES
/// du troupeau source.
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
  List<Proprietaire> _proprietairesAvecStock = [];
  final Map<int, Situation> _stocks = {};
  final Map<int, CheptelControleurs> _saisies = {};
  bool _chargementStock = false;
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TroupeauProvider>();
      if (provider.troupeaux.isNotEmpty) {
        setState(() => _troupeauSource = provider.troupeauSelectionne ?? provider.troupeaux.first);
        _chargerStocks();
      }
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _codeCtrl.dispose();
    for (final c in _saisies.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chargerStocks() async {
    final source = _troupeauSource;
    if (source?.id == null) return;
    setState(() => _chargementStock = true);
    final provider = context.read<TroupeauProvider>();
    final ids = await provider.getProprietaireIdsAvecStock(source!.id!);
    final props = provider.proprietaires.where((p) => ids.contains(p.id)).toList();
    final stocks = <int, Situation>{};
    for (final p in props) {
      stocks[p.id!] = await provider.getSituationDansTroupeau(source.id!, p.id!);
    }
    if (!mounted) return;
    setState(() {
      for (final c in _saisies.values) {
        c.dispose();
      }
      _saisies.clear();
      _stocks
        ..clear()
        ..addAll(stocks);
      for (final p in props) {
        _saisies[p.id!] = CheptelControleurs();
      }
      _proprietairesAvecStock = props;
      _chargementStock = false;
    });
  }

  Map<CategorieAnimal, int> _plafonds(int proprietaireId) {
    final s = _stocks[proprietaireId];
    return {for (final c in CategorieAnimal.values) c: s?.getByCategorie(c) ?? 0};
  }

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
                          'Les quantités saisies seront RETIRÉES du troupeau source et transférées au nouveau troupeau. Vous pouvez prélever chez plusieurs propriétaires à la fois.',
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
                    _chargerStocks();
                  },
                  validator: (t) => t == null ? 'Sélectionnez un troupeau source' : null,
                ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Text('Quantités à prélever, par propriétaire', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_chargementStock)
                const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
              else if (_proprietairesAvecStock.isEmpty)
                Text('Ce troupeau n\'a aucun cheptel à scinder.', style: GoogleFonts.poppins(color: Colors.grey.shade600))
              else
                ..._proprietairesAvecStock.map((p) => Card(
                      key: ValueKey('scission-${_troupeauSource?.id}-${p.id}'),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade300)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nom, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.vertPrincipal)),
                            const SizedBox(height: 10),
                            CheptelChamps(controleurs: _saisies[p.id!]!, plafonds: _plafonds(p.id!)),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (_enregistrementEnCours || _proprietairesAvecStock.isEmpty) ? null : _enregistrer,
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
    final parProprietaire = <int, Map<CategorieAnimal, int>>{
      for (final e in _saisies.entries) e.key: e.value.valeurs(),
    };
    final total = parProprietaire.values.fold<int>(0, (s, m) => s + m.values.fold(0, (a, b) => a + b));
    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez au moins une quantité à prélever.')),
      );
      return;
    }
    setState(() => _enregistrementEnCours = true);
    try {
      await context.read<TroupeauProvider>().scinderTroupeau(
            troupeauSourceId: _troupeauSource!.id!,
            nomNouveauTroupeau: _nomCtrl.text.trim(),
            codeNouveauTroupeau: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
            quantitesParProprietaire: parProprietaire,
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
