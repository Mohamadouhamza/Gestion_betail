# Gestion Bétail – Application Flutter

Application mobile de gestion du cheptel pour bergers et éleveurs.  
Elle permet de suivre, par propriétaire et par troupeau, l'évolution du bétail à travers les mouvements (achats, ventes, pertes, naissances) et de consulter la situation en temps réel.

---

## Fonctionnalités

- **Propriétaires** : gestion de plusieurs propriétaires (ex. : ABDOUL, ALI) au sein d'un même troupeau.
- **Troupeaux** : chaque troupeau possède un nom et un code (ex. : AH, VF).
- **Situation en temps réel** : nombre de taurions, génisses, vaches, veaux mâles, veaux femelles, total et gestation.
- **Filtre par âge** : pour les taurions, possibilité de filtrer par tranche d'âge (< 1 an, 1 – 2 ans, > 2 ans).
- **Mouvements** : enregistrement des entrées (report, achat, naissance) et des sorties (vente, perte).
- **Gestation** : suivi des vaches en gestation avec date de début.
- **Fiche de suivi** : tableau récapitulatif inspiré de la fiche papier, consultable à l'écran.
- **Hors ligne** : toutes les données sont stockées localement dans SQLite (`sqflite`).

---

## Légende

| Code | Signification |
|------|---------------|
| T    | Taurion       |
| G    | Génisse       |
| V    | Vache         |
| VM   | Veau mâle     |
| VF   | Veau femelle  |
| TOT  | Total         |
| GEST | Gestation     |
