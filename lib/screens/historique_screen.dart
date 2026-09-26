import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/troupeau_provider.dart';
import '../theme/app_colors.dart';

class HistoriqueScreen extends StatelessWidget {
  const HistoriqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondEcran,
      appBar: AppBar(
        title: Text('Historique', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<TroupeauProvider>(
        builder: (context, provider, child) {
          if (provider.mouvementsRecents.isEmpty) {
            return Center(
              child: Text('Aucun mouvement', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 110),
            itemCount: provider.mouvementsRecents.length,
            itemBuilder: (context, index) {
              final mouv = provider.mouvementsRecents[index];
              return Dismissible(
                key: Key(mouv.id.toString()),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  final confirme = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer ce mouvement ?'),
                      content: Text(
                        '${mouv.type.label} – ${mouv.categorie.label} (${mouv.quantite} tête(s)) du '
                        '${DateFormat('dd/MM/yyyy').format(mouv.date)} sera définitivement supprimé.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  return confirme ?? false;
                },
                onDismissed: (_) => provider.supprimerMouvement(mouv.id!),
                background: Container(
                  decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: mouv.type.sens == 'entree'
                          ? Colors.green.shade100
                          : mouv.type.sens == 'sortie'
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                      child: Text(
                        mouv.categorie.code,
                        style: TextStyle(
                          color: mouv.type.sens == 'entree'
                              ? Colors.green.shade800
                              : mouv.type.sens == 'sortie'
                                  ? Colors.red.shade800
                                  : Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('${mouv.type.label} – ${mouv.categorie.label}', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text('${mouv.quantite} tête(s) • ${DateFormat('dd/MM/yyyy').format(mouv.date)}'
                        '${mouv.notes != null && mouv.notes!.isNotEmpty ? '\n${mouv.notes}' : ''}'),
                    isThreeLine: mouv.notes != null && mouv.notes!.isNotEmpty,
                    trailing: mouv.prix != null
                        ? Chip(label: Text('${mouv.prix!.toStringAsFixed(0)} F'), backgroundColor: Colors.amber.shade100)
                        : null,
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
