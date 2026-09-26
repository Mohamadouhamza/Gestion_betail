import '../models/models.dart';
import '../models/enums.dart';

/// Reconstruit la fiche de suivi EXACTEMENT comme le registre papier :
/// une ligne par DATE x PROPRIÉTAIRE, plus une ligne TOTAL par date,
/// avec les colonnes PERTES / VENTE / ACHAT / NAIS / BILA / SITUATION / PROJECTIONS.
class FicheLedgerService {
  /// [mouvements] doit être trié chronologiquement (ASC) et filtré sur UN troupeau.
  /// [proprietaires] = tous les propriétaires ayant un mouvement dans ce troupeau.
  /// [lotsActuels] = état actuel des lots (pour les projections de gestation).
  static List<FicheLigne> construire({
    required List<Mouvement> mouvements,
    required List<Proprietaire> proprietaires,
    required List<LotAnimal> lotsActuels,
  }) {
    if (mouvements.isEmpty) return [];

    // Running stock : proprietaireId -> code categorie -> quantité
    final Map<int, Map<String, int>> stock = {
      for (final p in proprietaires) p.id!: {'T': 0, 'G': 0, 'V': 0, 'VM': 0, 'VF': 0}
    };

    // Regroupe les mouvements par jour (date sans l'heure)
    final Map<DateTime, List<Mouvement>> parDate = {};
    for (final m in mouvements) {
      final jour = DateTime(m.date.year, m.date.month, m.date.day);
      parDate.putIfAbsent(jour, () => []).add(m);
    }
    final dates = parDate.keys.toList()..sort();

    final lignes = <FicheLigne>[];

    for (var i = 0; i < dates.length; i++) {
      final jour = dates[i];
      final estDerniereDate = i == dates.length - 1;
      final mouvementsJour = parDate[jour]!;

      // Regroupe les mouvements du jour par propriétaire
      final Map<int, List<Mouvement>> parProprietaire = {};
      for (final m in mouvementsJour) {
        parProprietaire.putIfAbsent(m.proprietaireId, () => []).add(m);
      }

      // Totaux du jour (pour la ligne TOTAL)
      var tPerteT = 0, tPerteG = 0, tPerteV = 0, tPerteVM = 0, tPerteVF = 0;
      var tVenteT = 0, tVenteG = 0, tVenteV = 0;
      var tAchatT = 0, tAchatG = 0;
      var tNaisM = 0, tNaisF = 0;
      var tSitT = 0, tSitG = 0, tSitV = 0, tSitVM = 0, tSitVF = 0;
      var tGest = 0;

      for (final p in proprietaires) {
        final mvts = parProprietaire[p.id] ?? [];

        int perteT = 0, perteG = 0, perteV = 0, perteVM = 0, perteVF = 0;
        int venteT = 0, venteG = 0, venteV = 0;
        int achatT = 0, achatG = 0;
        int naisM = 0, naisF = 0;
        final observationsJour = <String>[];

        for (final m in mvts) {
          final qte = m.quantite;
          if (m.notes != null && m.notes!.trim().isNotEmpty) {
            observationsJour.add(m.notes!.trim());
          }
          switch (m.type) {
            case TypeMouvement.perte:
              switch (m.categorie) {
                case CategorieAnimal.taurion: perteT += qte; break;
                case CategorieAnimal.genisse: perteG += qte; break;
                case CategorieAnimal.vache: perteV += qte; break;
                case CategorieAnimal.veauMale: perteVM += qte; break;
                case CategorieAnimal.veauFemelle: perteVF += qte; break;
              }
              break;
            case TypeMouvement.vente:
              switch (m.categorie) {
                case CategorieAnimal.taurion: venteT += qte; break;
                case CategorieAnimal.genisse: venteG += qte; break;
                case CategorieAnimal.vache: venteV += qte; break;
                default: break; // VM/VF non ventilés (comme sur la fiche papier)
              }
              break;
            case TypeMouvement.achat:
              switch (m.categorie) {
                case CategorieAnimal.taurion: achatT += qte; break;
                case CategorieAnimal.genisse: achatG += qte; break;
                default: break; // V/VM/VF non ventilés (comme sur la fiche papier)
              }
              break;
            case TypeMouvement.naissance:
              switch (m.categorie) {
                case CategorieAnimal.veauMale: naisM += qte; break;
                case CategorieAnimal.veauFemelle: naisF += qte; break;
                default: break;
              }
              break;
            case TypeMouvement.report:
              // Le report initialise le stock directement (voir plus bas) ;
              // il n'a pas de colonne dédiée dans le tableau des mouvements.
              break;
          }

          // Applique la variation au stock courant (report = entrée initiale)
          final estEntree = m.type.sens == 'entree' || m.type.sens == 'ouverture';
          final delta = estEntree ? qte : -qte;
          final s = stock[p.id]!;
          s[m.categorie.code] = (s[m.categorie.code] ?? 0) + delta;
        }

        final s = stock[p.id]!;
        final sitT = s['T'] ?? 0;
        final sitG = s['G'] ?? 0;
        final sitV = s['V'] ?? 0;
        final sitVM = s['VM'] ?? 0;
        final sitVF = s['VF'] ?? 0;

        // Projections : uniquement sur le dernier bloc de date (état courant réel)
        int gest = 0;
        DateTime? dateProjection;
        if (estDerniereDate) {
          final lotsGestants = lotsActuels.where(
            (l) => l.proprietaireId == p.id && l.categorie == CategorieAnimal.vache && l.enGestation,
          );
          gest = lotsGestants.fold(0, (sum, l) => sum + l.quantite);
          final termes = lotsGestants.map((l) => l.dateTermeGestation).whereType<DateTime>().toList();
          if (termes.isNotEmpty) {
            termes.sort();
            dateProjection = termes.first;
          }
        }

        // N'ajoute la ligne que si ce propriétaire a un mouvement ce jour-là,
        // OU si c'est le dernier bloc (pour afficher l'état courant complet)
        if (mvts.isNotEmpty || estDerniereDate) {
          lignes.add(FicheLigne(
            date: jour,
            proprietaire: p.nom,
            perteT: perteT, perteG: perteG, perteV: perteV, perteVM: perteVM, perteVF: perteVF,
            venteT: venteT, venteG: venteG, venteV: venteV,
            achatT: achatT, achatG: achatG,
            naisM: naisM, naisF: naisF,
            sitT: sitT, sitG: sitG, sitV: sitV, sitVM: sitVM, sitVF: sitVF,
            gest: gest,
            dateProjection: dateProjection,
            observations: observationsJour.join(' ; '),
          ));
        }

        tPerteT += perteT; tPerteG += perteG; tPerteV += perteV; tPerteVM += perteVM; tPerteVF += perteVF;
        tVenteT += venteT; tVenteG += venteG; tVenteV += venteV;
        tAchatT += achatT; tAchatG += achatG;
        tNaisM += naisM; tNaisF += naisF;
        tSitT += sitT; tSitG += sitG; tSitV += sitV; tSitVM += sitVM; tSitVF += sitVF;
        tGest += gest;
      }

      final bila = (tAchatT + tAchatG + tNaisM + tNaisF) - (tPerteT + tPerteG + tPerteV + tPerteVM + tPerteVF + tVenteT + tVenteG + tVenteV);

      lignes.add(FicheLigne(
        date: jour,
        proprietaire: 'TOTAL',
        estTotal: true,
        perteT: tPerteT, perteG: tPerteG, perteV: tPerteV, perteVM: tPerteVM, perteVF: tPerteVF,
        venteT: tVenteT, venteG: tVenteG, venteV: tVenteV,
        achatT: tAchatT, achatG: tAchatG,
        naisM: tNaisM, naisF: tNaisF,
        bila: bila,
        sitT: tSitT, sitG: tSitG, sitV: tSitV, sitVM: tSitVM, sitVF: tSitVF,
        gest: tGest,
      ));
    }

    return lignes;
  }
}
