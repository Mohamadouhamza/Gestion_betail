import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';

class MouvementScreen extends StatefulWidget {
  const MouvementScreen({super.key});
  @override
  State<MouvementScreen> createState() => _MouvementScreenState();
}

class _MouvementScreenState extends State<MouvementScreen> {
  final _formKey = GlobalKey<FormState>();

  TypeMouvement _type = TypeMouvement.achat;
  CategorieAnimal _categorie = CategorieAnimal.vache;
  final _quantiteCtrl = TextEditingController(text: '1');
  final _prixCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _nouveauLot = true;
  DateTime _dateNaissance = DateTime.now();
  bool _enGestation = false;
  bool _enregistrementEnCours = false;

  final List<TypeMouvement> _typesDisponibles = [
    TypeMouvement.report,
    TypeMouvement.achat,
    TypeMouvement.vente,
    TypeMouvement.perte,
    TypeMouvement.naissance,
  ];

  /// La naissance ne concerne que les veaux : on restreint les catégories
  /// proposées pour éviter une saisie incohérente (impossible de "naître"
  /// directement Taurion, Génisse ou Vache).
  List<CategorieAnimal> get _categoriesDisponibles {
    if (_type == TypeMouvement.naissance) {
      return [CategorieAnimal.veauMale, CategorieAnimal.veauFemelle];
    }
    return CategorieAnimal.values;
  }

  void _changerType(TypeMouvement type) {
    setState(() {
      _type = type;
      if (!_categoriesDisponibles.contains(_categorie)) {
        _categorie = _categoriesDisponibles.first;
      }
    });
  }

  @override
  void dispose() {
    _quantiteCtrl.dispose();
    _prixCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TroupeauProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouveau mouvement', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.info, color: AppColors.vertPrincipal),
                  title: Text(
                    '${provider.proprietaireSelectionne?.nom ?? '-'} – ${provider.troupeauSelectionne?.nom ?? '-'}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Ce mouvement sera enregistré pour ce propriétaire et ce troupeau.'),
                ),
              ),
              const SizedBox(height: 16),
              Text('Type de mouvement', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _typesDisponibles.map((type) {
                  final isSelected = _type == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: isSelected,
                    selectedColor: type.sens == 'entree'
                        ? Colors.green.shade100
                        : type.sens == 'sortie'
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                    onSelected: (_) => _changerType(type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Catégorie', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categoriesDisponibles
                    .map((cat) => ChoiceChip(
                          label: Text('${cat.code} – ${cat.label}'),
                          selected: _categorie == cat,
                          onSelected: (_) => setState(() => _categorie = cat),
                        ))
                    .toList(),
              ),
              if (_type == TypeMouvement.naissance)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Une naissance ne peut concerner qu\'un veau mâle ou femelle.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _quantiteCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.format_list_numbered),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'La quantité est obligatoire';
                  final n = int.tryParse(v);
                  if (n == null) return 'Entrez un nombre entier valide';
                  if (n <= 0) return 'La quantité doit être supérieure à 0';
                  if (_type.sens == 'sortie') {
                    final dispo = provider.situation.getByCategorie(_categorie);
                    if (n > dispo) {
                      return 'Stock insuffisant : $dispo ${_categorie.code} disponible(s)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                tileColor: Colors.grey.shade100,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date du mouvement'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2018),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Prix (optionnel)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null; // optionnel
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null) return 'Prix invalide';
                  if (n < 0) return 'Le prix ne peut pas être négatif';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_type.sens == 'entree') ...[
                CheckboxListTile(
                  title: Text('Créer un nouveau lot', style: GoogleFonts.poppins()),
                  value: _nouveauLot,
                  onChanged: (v) => setState(() => _nouveauLot = v!),
                ),
                if (_nouveauLot)
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                    tileColor: Colors.grey.shade100,
                    leading: const Icon(Icons.cake),
                    title: const Text('Date de naissance du lot'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_dateNaissance), style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateNaissance,
                        firstDate: DateTime(2015),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dateNaissance = picked);
                    },
                  ),
                if (_categorie == CategorieAnimal.vache) ...[
                  CheckboxListTile(
                    title: Text('Vache en gestation ?', style: GoogleFonts.poppins()),
                    subtitle: const Text('Le terme (≈ 9 mois) sera calculé et clôturé automatiquement.'),
                    value: _enGestation,
                    onChanged: (v) => setState(() => _enGestation = v!),
                  ),
                ],
              ],
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Observations',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _enregistrementEnCours ? null : _enregistrer,
                  icon: _enregistrementEnCours
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text('ENREGISTRER', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    final provider = context.read<TroupeauProvider>();

    if (provider.troupeauSelectionne == null || provider.proprietaireSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un propriétaire et un troupeau avant d\'enregistrer.')),
      );
      return;
    }

    final formValide = _formKey.currentState?.validate() ?? false;
    if (!formValide) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrigez les champs en rouge avant d\'enregistrer.')),
      );
      return;
    }

    setState(() => _enregistrementEnCours = true);

    final quantite = int.parse(_quantiteCtrl.text.trim());
    final prixTexte = _prixCtrl.text.trim().replaceAll(',', '.');

    final mouvement = Mouvement(
      troupeauId: provider.troupeauSelectionne!.id!,
      proprietaireId: provider.proprietaireSelectionne!.id!,
      type: _type,
      categorie: _categorie,
      quantite: quantite,
      date: _date,
      prix: prixTexte.isEmpty ? null : double.parse(prixTexte),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    LotAnimal? lot;
    if (_type.sens == 'entree' && _nouveauLot) {
      lot = LotAnimal(
        troupeauId: provider.troupeauSelectionne!.id!,
        proprietaireId: provider.proprietaireSelectionne!.id!,
        categorie: _categorie,
        quantite: quantite,
        dateNaissance: _dateNaissance,
        enGestation: _categorie == CategorieAnimal.vache && _enGestation,
        dateGestation: _enGestation ? _date : null,
      );
    }

    try {
      await provider.ajouterMouvement(mouvement, nouveauLot: lot);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mouvement enregistré')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }
}
