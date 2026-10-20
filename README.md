# Gestion Bétail

Application Flutter (Android) de suivi de cheptel, hors ligne (SQLite), calquée sur la
**fiche papier « FICHE DE SUIVI DE L'ÉVOLUTION DU BÉTAIL — TROUPEAU »**.

**Version : 1.3.0 (Round 3)** — voir `CORRECTIONS.md` pour le détail de chaque version.

## Concepts

- **Troupeau** : un groupe d'animaux suivi sur une fiche (ex. « AH »).
- **Propriétaire** : un même troupeau peut contenir le bétail de **plusieurs propriétaires**
  (ex. ABDOUL et ALI dans le troupeau AH), et un propriétaire peut avoir du bétail dans
  **plusieurs troupeaux**.
- **Catégories** : T (taurion), G (génisse), V (vache), VM (veau mâle), VF (veau femelle),
  + gestation des vaches (terme automatique à +283 jours).
- **REPORT** : cheptel initial / solde d'ouverture (création d'un propriétaire ou d'un
  troupeau, scission). Ce n'est pas un mouvement Achat/Vente/Perte/Naissance.

## Écrans

| Onglet / écran | Contenu |
|---|---|
| **Accueil** | Situation **générale** du troupeau (tous propriétaires), sélecteur de troupeau, bouton « + » : *Nouveau troupeau*, *Scinder un troupeau existant*, *Ajouter un propriétaire à ce troupeau*. Icône Historique dans l'en-tête. |
| **Mouvement** | Achat / Vente / Perte / Naissance pour un propriétaire choisi (naissances ≤ vaches en gestation de ce propriétaire). |
| **Inventaire** | Lots par catégorie, filtres d'âge des taurions, gestation. |
| **Propriétaire** | Liste des propriétaires, situation de chacun, bouton flottant **Nouveau propriétaire** (toujours au-dessus de la barre de navigation), *Ajouter du cheptel dans un troupeau*. |
| **Fiche** | Tableau identique à la fiche papier + export PDF (A3 paysage) et Excel. |

### Création

- **Nouveau troupeau** : nom, code, puis une liste répétable de blocs *propriétaire + cheptel*
  (zéro, un ou plusieurs ; création rapide d'un propriétaire possible depuis le bloc).
- **Scinder un troupeau existant** : choix du troupeau source, puis quantités à prélever
  **par propriétaire** (plafonnées au stock réel de chacun dans ce troupeau), en une opération.
- **Nouveau propriétaire** : nom + liste répétable de blocs *troupeau + cheptel*.
- **Ajouter un propriétaire à un troupeau existant** : depuis l'accueil (troupeau imposé) ou depuis
  la fiche d'un propriétaire (propriétaire imposé).

## Fiche (structure fidèle au papier)

- En-tête sur 3 niveaux, **cellules fusionnées** : PERTES (T G V VM VF), VENTE (T G V),
  ACHAT (T G), NAIS (M F), BILA, SITUATION A DATE (T G V, **VO** coiffant VM/VF, TOT),
  PROJECTIONS (GEST DATE NOM.), OBSERVATIONS.
- Pour chaque date : une ligne par propriétaire + une ligne **TOTAL** (somme des propriétaires,
  BILA uniquement sur TOTAL). La cellule **DATE est une seule cellule fusionnée** sur tout le
  bloc (écran, PDF et Excel). « REPORT » à la place de la date pour un solde d'ouverture.
- Les projections ne sont calculées que sur le dernier bloc de dates (état courant).

## Export

Fichiers `Fiche_Troupeau_jj-mm-aaaa.pdf` / `.xlsx`, écrits dans le dossier public
**Téléchargements** (MediaStore, séquence `IS_PENDING`, sans permission sur Android 10+),
avec bouton **PARTAGER**. Si l'écriture échoue, une fenêtre affiche l'**erreur technique exacte**
(copiable) : à me transmettre pour corriger précisément.

## Build avec GitHub Actions

1. Remplace le contenu de ton dépôt par celui de ce ZIP (le workflow
   `.github/workflows/build.yml` n'a pas changé).
2. `git add . && git commit -m "Round 3" && git push`
3. Onglet **Actions** → télécharge l'artefact `app-release.apk` → installe-le.

## Stack

Flutter 3.13.0, Dart 3, Provider, sqflite, google_fonts (Poppins), intl, pdf, excel ^4.0.6,
share_plus ^7.2.1, path_provider. Aucune dépendance ajoutée au Round 3.
`open_file` est volontairement absent (conflit de classes Kotlin stdlib).

## Limites connues

- Une scission déplace les lots sans écrire de « Perte » dans la fiche du troupeau source
  (son tableau papier reste celui de l'historique de ses mouvements).
- Projections de gestation : dernier bloc de dates uniquement.
