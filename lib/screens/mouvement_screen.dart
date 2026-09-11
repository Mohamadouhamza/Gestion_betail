import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../providers/troupeau_provider.dart';

class MouvementScreen extends StatefulWidget {
  const MouvementScreen({super.key});
  @override
  State<MouvementScreen> createState() => _MouvementScreenState();
}

class _MouvementScreenState extends State<MouvementScreen> {
  TypeMouvement _type = TypeMouvement.achat;
  CategorieAnimal _categorie = CategorieAnimal.vache;
  final _quantiteCtrl = TextEditingController(text: '1');
  final _prixCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _nouveauLot = true;
  DateTime _dateNaissance = DateTime.now();
  bool _enGestation = false;

  final List<TypeMouvement> _typesDisponibles = [TypeMouvement.report, TypeMouvement.achat, TypeMouvement.vente, TypeMouvement.perte, TypeMouvement.naissance];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TroupeauProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Nouveau mouvement', style: GoogleFonts.poppins()), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(color: Colors.green.shade50, child: ListTile(leading: const Icon(Icons.info, color: Colors.green), title: Text('${provider.proprietaireSelectionne?.nom ?? '-'} – ${provider.troupeauSelectionne?.nom ?? '-'}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), subtitle: const Text('Ce mouvement sera enregistré pour ce propriétaire et ce troupeau.'))),
            const SizedBox(height: 16),
            Text('Type de mouvement', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _typesDisponibles.map((type) { final isSelected = _type == type; return ChoiceChip(label: Text(type.label), selected: isSelected, selectedColor: type.sens == 'entree' ? Colors.green.shade100 : type.sens == 'sortie' ? Colors.red.shade100 : Colors.blue.shade100, onSelected: (_) => setState(() => _type = type)); }).toList()),
            const SizedBox(height: 24),
            Text('Catégorie', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: CategorieAnimal.values.map((cat) => ChoiceChip(label: Text('${cat.code} – ${cat.label}'), selected: _categorie == cat, onSelected: (_) => setState(() => _categorie = cat))).toList()),
            const SizedBox(height: 24),
            TextField(controller: _quantiteCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantité', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.format_list_numbered))),
            const SizedBox(height: 16),
            ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), tileColor: Colors.grey.shade100, leading: const Icon(Icons.calendar_today), title: Text(DateFormat('dd/MM/yyyy').format(_date)), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () async { final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2018), lastDate: DateTime.now()); if (picked != null) setState(() => _date = picked); }),
            const SizedBox(height: 16),
            TextField(controller: _prixCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Prix (optionnel)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.attach_money))),
            const SizedBox(height: 16),
            if (_type.sens == 'entree') ...[
              CheckboxListTile(title: Text('Créer un nouveau lot', style: GoogleFonts.poppins()), value: _nouveauLot, onChanged: (v) => setState(() => _nouveauLot = v!)),
              if (_nouveauLot) ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), tileColor: Colors.grey.shade100, leading: const Icon(Icons.cake), title: Text('Date naissance : ${DateFormat('dd/MM/yyyy').format(_dateNaissance)}'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () async { final picked = await showDatePicker(context: context, initialDate: _dateNaissance, firstDate: DateTime(2015), lastDate: DateTime.now()); if (picked != null) setState(() => _dateNaissance = picked); }),
              if (_categorie == CategorieAnimal.vache) CheckboxListTile(title: Text('Vache en gestation ?', style: GoogleFonts.poppins()), value: _enGestation, onChanged: (v) => setState(() => _enGestation = v!)),
            ],
            TextField(controller: _notesCtrl, maxLines: 2, decoration: InputDecoration(labelText: 'Observations', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.notes))),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: _enregistrer, icon: const Icon(Icons.save), label: Text('ENREGISTRER', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
          ],
        ),
      ),
    );
  }

  void _enregistrer() {
    final provider = context.read<TroupeauProvider>();
    if (provider.troupeauSelectionne == null || provider.proprietaireSelectionne == null) return;
    final quantite = int.tryParse(_quantiteCtrl.text) ?? 0;
    if (quantite <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantité invalide'))); return; }
    final mouvement = Mouvement(troupeauId: provider.troupeauSelectionne!.id!, proprietaireId: provider.proprietaireSelectionne!.id!, type: _type, categorie: _categorie, quantite: quantite, date: _date, prix: double.tryParse(_prixCtrl.text), notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text);
    LotAnimal? lot;
    if (_type.sens == 'entree' && _nouveauLot) {
      lot = LotAnimal(troupeauId: provider.troupeauSelectionne!.id!, proprietaireId: provider.proprietaireSelectionne!.id!, categorie: _categorie, quantite: quantite, dateNaissance: _dateNaissance, enGestation: _categorie == CategorieAnimal.vache && _enGestation, dateGestation: _enGestation ? _date : null);
    }
    provider.ajouterMouvement(mouvement, nouveauLot: lot).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mouvement enregistré')));
    });
  }
}
