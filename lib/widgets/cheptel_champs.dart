import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../providers/troupeau_provider.dart';

/// Les 5 champs de quantité (T, G, V, VM, VF) d'un bloc de cheptel.
class CheptelControleurs {
  final Map<CategorieAnimal, TextEditingController> ctrls = {
    for (final c in CategorieAnimal.values) c: TextEditingController(text: '0'),
  };

  Map<CategorieAnimal, int> valeurs() => {
        for (final c in CategorieAnimal.values) c: int.tryParse(ctrls[c]!.text.trim()) ?? 0,
      };

  int get total => valeurs().values.fold(0, (a, b) => a + b);

  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
  }
}

/// Grille des 5 quantités. Si [plafonds] est fourni (scission), chaque
/// champ est limité à la quantité réellement disponible.
class CheptelChamps extends StatelessWidget {
  final CheptelControleurs controleurs;
  final Map<CategorieAnimal, int>? plafonds;

  const CheptelChamps({super.key, required this.controleurs, this.plafonds});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: CategorieAnimal.values.map((cat) {
        final plafond = plafonds?[cat];
        return SizedBox(
          width: 150,
          child: TextFormField(
            controller: controleurs.ctrls[cat],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${cat.code} – ${cat.label}',
              helperText: plafond == null ? null : 'Disponible : $plafond',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            validator: (v) {
              final texte = (v ?? '').trim();
              final n = int.tryParse(texte.isEmpty ? '0' : texte);
              if (n == null || n < 0) return 'Invalide';
              if (plafond != null && n > plafond) return 'Max $plafond';
              return null;
            },
          ),
        );
      }).toList(),
    );
  }
}

/// Petit formulaire modal de création rapide d'un propriétaire (sans
/// cheptel). Renvoie le propriétaire créé, ou null si annulé.
Future<Proprietaire?> demanderNouveauProprietaire(BuildContext context) {
  final nomCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<Proprietaire>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Nouveau propriétaire', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final p = await context.read<TroupeauProvider>().ajouterProprietaire(
                    nomCtrl.text.trim(),
                    telephone: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext, p);
            },
            child: const Text('Créer'),
          ),
        ],
      );
    },
  );
}
