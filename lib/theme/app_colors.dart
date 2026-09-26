import 'package:flutter/material.dart';

/// Palette centralisée : toutes les couleurs et icônes de l'app viennent
/// d'ici pour garantir une cohérence visuelle totale (header, navbar, cartes).
class AppColors {
  AppColors._();

  static const Color vertPrincipal = Color(0xFF2E7D32); // vert foncé, lisible en blanc dessus
  static const Color vertClair = Color(0xFF66BB6A);
  static const Color fondEcran = Color(0xFFF4F6F5);

  static const Color taurion = Color(0xFF6D4C41);
  static const Color genisse = Color(0xFFFB8C00);
  static const Color vache = Color(0xFF2E7D32);
  static const Color veauMale = Color(0xFF1E88E5);
  static const Color veauFemelle = Color(0xFF8E24AA);
  static const Color gestation = Color(0xFFD81B60);
  static const Color total = Color(0xFF00796B);
}

/// Icônes cohérentes réutilisées partout dans l'app (mêmes pictogrammes
/// pour désigner la même chose, que ce soit dans la navbar, les cartes,
/// l'inventaire ou la fiche). On n'utilise que des icônes Material de base,
/// garanties disponibles quelle que soit la version de Flutter.
class AppIcons {
  AppIcons._();

  static const IconData accueil = Icons.home;
  static const IconData accueilInactif = Icons.home_outlined;
  static const IconData mouvement = Icons.swap_horiz;
  static const IconData inventaire = Icons.inventory_2;
  static const IconData inventaireInactif = Icons.inventory_2_outlined;
  static const IconData historique = Icons.history;
  static const IconData fiche = Icons.description;
  static const IconData ficheInactif = Icons.description_outlined;

  static const IconData taurion = Icons.male;
  static const IconData genisse = Icons.female;
  static const IconData vache = Icons.female;
  static const IconData veauMale = Icons.male_outlined;
  static const IconData veauFemelle = Icons.female_outlined;
  static const IconData total = Icons.pets;
}

/// Icône composite pour la gestation : PAS de silhouette humaine (l'icône
/// Material "pregnant_woman" ne convient pas à des vaches). On affiche à la
/// place une patte animalière avec un petit cœur, sans risque de dépendre
/// d'une icône Material récente qui pourrait ne pas exister partout.
class GestationIcon extends StatelessWidget {
  final double size;
  final Color color;
  const GestationIcon({super.key, this.size = 24, this.color = AppColors.gestation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.pets, size: size, color: color),
          Positioned(
            right: -size * 0.08,
            top: -size * 0.08,
            child: Icon(Icons.favorite, size: size * 0.48, color: color),
          ),
        ],
      ),
    );
  }
}
