import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';

/// "Nouveau troupeau" : scénario additif (ex. troupeau reçu en cadeau par un
/// ami, ou simplement un nouveau troupeau à suivre). Le cheptel saisi ici
/// s'AJOUTE, sans rien retirer à aucun troupeau existant.
/// Pour prélever une partie d'un troupeau existant, voir ScinderTroupeauScreen.
class NouveauTroupeauScreen extends StatefulWidget {
  const NouveauTroupeauScreen({super.key});

  @override
  State<NouveauTroupeauScreen> createState() => _NouveauTroupeauScreenState();
}

class _NouveauTroupeauScreenState extends State<NouveauTroupeauScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  Proprietaire? _proprietaire;
  final Map<CategorieAnimal, TextEditingController> _quantiteCtrls = {
    for (final c in CategorieAnimal.values) c: TextEditingController(text: '0'),
  };
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TroupeauProvider>();
      if (provider.proprietaires.isNotEmpty) {
        setState(() => _proprietaire = provider.proprietaireSelectionne ?? provider.proprietaires.first);
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
                          'Ce troupeau est ajouté avec son propre cheptel, sans rien retirer à vos troupeaux existants (ex : troupeau reçu).',
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
              const SizedBox(height: 16),
              if (provider.proprietaires.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    'Aucun propriétaire enregistré. Ajoutez-en un depuis l\'onglet "Propriétaire" avant de créer un troupeau.',
                    style: GoogleFonts.poppins(color: Colors.orange.shade800),
                  ),
                )
              else
                DropdownButtonFormField<Proprietaire>(
                  value: _proprietaire,
                  decoration: InputDecoration(labelText: 'Propriétaire du cheptel *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: provider.proprietaires.map((p) => DropdownMenuItem(value: p, child: Text(p.nom))).toList(),
                  onChanged: (p) => setState(() => _proprietaire = p),
                  validator: (p) => p == null ? 'Sélectionnez un propriétaire' : null,
                ),
              const SizedBox(height: 20),
              Text('Cheptel initial (optionnel)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: CategorieAnimal.values.map((cat) {
                  return SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: _quantiteCtrls[cat],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${cat.code} – ${cat.label}',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim().isEmpty ? '0' : v!.trim());
                        if (n == null || n < 0) return 'Invalide';
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
                  onPressed: (_enregistrementEnCours || provider.proprietaires.isEmpty) ? null : _enregistrer,
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

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enregistrementEnCours = true);
    final cheptel = <CategorieAnimal, int>{
      for (final c in CategorieAnimal.values) c: int.tryParse(_quantiteCtrls[c]!.text.trim()) ?? 0,
    };
    try {
      await context.read<TroupeauProvider>().ajouterTroupeauAvecCheptel(
            _nomCtrl.text.trim(),
            code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
            proprietaireId: _proprietaire!.id!,
            cheptel: cheptel,
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
