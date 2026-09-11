import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/troupeau_provider.dart';

class HistoriqueScreen extends StatelessWidget {
  const HistoriqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historique', style: GoogleFonts.poppins()), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
      body: Consumer<TroupeauProvider>(
        builder: (context, provider, child) {
          if (provider.mouvementsRecents.isEmpty) return const Center(child: Text('Aucun mouvement'));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.mouvementsRecents.length,
            itemBuilder: (context, index) {
              final mouv = provider.mouvementsRecents[index];
              return Dismissible(
                key: Key(mouv.id.toString()),
                onDismissed: (_) => provider.supprimerMouvement(mouv.id!),
                background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: mouv.type.sens == 'entree' ? Colors.green.shade100 : mouv.type.sens == 'sortie' ? Colors.red.shade100 : Colors.blue.shade100,
                      child: Text(mouv.categorie.code, style: TextStyle(color: mouv.type.sens == 'entree' ? Colors.green.shade800 : mouv.type.sens == 'sortie' ? Colors.red.shade800 : Colors.blue.shade800, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${mouv.type.label} – ${mouv.categorie.label}', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text('${mouv.quantite} tête(s) • ${DateFormat('dd/MM/yyyy').format(mouv.date)}'),
                    trailing: mouv.prix != null ? Chip(label: Text('${mouv.prix!.toStringAsFixed(0)} F'), backgroundColor: Colors.amber.shade100) : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
