import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../services/fiche_ledger_service.dart';

class TroupeauProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Proprietaire> _proprietaires = [];
  List<Troupeau> _troupeaux = [];
  Proprietaire? _proprietaireSelectionne;
  Troupeau? _troupeauSelectionne;
  Situation _situation = Situation(taurions: 0, genisses: 0, vaches: 0, veauxMales: 0, veauxFemelles: 0, gestation: 0, date: DateTime.now());
  List<Mouvement> _mouvementsRecents = [];
  List<LotAnimal> _lots = [];
  FiltreAge _filtreAgeTaurions = FiltreAge.tous;
  bool _isLoading = false;
  Timer? _timerGestation;

  List<Proprietaire> get proprietaires => _proprietaires;
  List<Troupeau> get troupeaux => _troupeaux;

  /// Propriétaire "par défaut" (pré-sélectionné dans les formulaires, ex :
  /// nouveau mouvement). Depuis la refonte de la navigation, ce n'est PLUS
  /// un filtre appliqué à la situation affichée à l'accueil (qui est toujours
  /// générale, tous propriétaires confondus) : voir [situation].
  Proprietaire? get proprietaireSelectionne => _proprietaireSelectionne;
  Troupeau? get troupeauSelectionne => _troupeauSelectionne;

  /// Situation GÉNÉRALE du troupeau sélectionné (tous propriétaires confondus).
  Situation get situation => _situation;
  List<Mouvement> get mouvementsRecents => _mouvementsRecents;
  List<LotAnimal> get lots => _lots;
  FiltreAge get filtreAgeTaurions => _filtreAgeTaurions;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _setLoading(true);
    _proprietaires = await _db.getProprietaires();
    _troupeaux = await _db.getTroupeaux();
    if (_proprietaires.isNotEmpty) _proprietaireSelectionne = _proprietaires.first;
    if (_troupeaux.isNotEmpty) _troupeauSelectionne = _troupeaux.first;
    await _db.cloturerGestationsTerminees();
    await rafraichirDonnees();
    _setLoading(false);

    // Vérifie automatiquement les gestations arrivées à terme toutes les heures
    // tant que l'application reste ouverte (en plus de la vérification à chaque action).
    _timerGestation?.cancel();
    _timerGestation = Timer.periodic(const Duration(hours: 1), (_) async {
      final nb = await _db.cloturerGestationsTerminees();
      if (nb > 0) await rafraichirDonnees();
    });
  }

  @override
  void dispose() {
    _timerGestation?.cancel();
    super.dispose();
  }

  /// Change uniquement le propriétaire "par défaut" proposé dans les
  /// formulaires (ex : nouveau mouvement). N'affecte plus la situation
  /// générale affichée à l'accueil.
  void definirProprietaireParDefaut(Proprietaire p) {
    _proprietaireSelectionne = p;
    notifyListeners();
  }

  Future<void> selectionnerTroupeau(Troupeau t) async {
    _troupeauSelectionne = t;
    await rafraichirDonnees();
    notifyListeners();
  }

  /// Recharge la situation GÉNÉRALE (tous propriétaires) du troupeau courant,
  /// les derniers mouvements (tous propriétaires) et les lots (tous
  /// propriétaires). La vue par propriétaire se charge séparément via
  /// [getSituationPourProprietaire].
  Future<void> rafraichirDonnees() async {
    if (_troupeauSelectionne == null) return;
    _setLoading(true);
    await _db.cloturerGestationsTerminees();
    _situation = await _db.getSituation(
      troupeauId: _troupeauSelectionne!.id,
      proprietaireId: null,
    );
    _mouvementsRecents = await _db.getMouvements(
      troupeauId: _troupeauSelectionne!.id,
      proprietaireId: null,
      limit: 50,
    );
    await chargerLots();
    _setLoading(false);
  }

  /// Situation d'UN propriétaire précis pour le troupeau actuellement
  /// sélectionné (utilisé par l'onglet "Propriétaire").
  Future<Situation> getSituationPourProprietaire(int proprietaireId) async {
    if (_troupeauSelectionne == null) {
      return Situation(taurions: 0, genisses: 0, vaches: 0, veauxMales: 0, veauxFemelles: 0, gestation: 0, date: DateTime.now());
    }
    return _db.getSituation(troupeauId: _troupeauSelectionne!.id, proprietaireId: proprietaireId);
  }

  /// Nombre de vaches actuellement en gestation pour un propriétaire donné,
  /// dans le troupeau sélectionné (utilisé pour limiter les naissances).
  Future<int> getNombreGestationsPourProprietaire(int proprietaireId) async {
    if (_troupeauSelectionne == null) return 0;
    final s = await _db.getSituation(troupeauId: _troupeauSelectionne!.id, proprietaireId: proprietaireId);
    return s.gestation;
  }

  /// Identifiants des propriétaires ayant du stock dans un troupeau donné
  /// (utilisé pour la scission d'un troupeau existant).
  Future<List<int>> getProprietaireIdsAvecStock(int troupeauId) => _db.getProprietaireIdsAvecStock(troupeauId);

  /// Reconstruit la fiche de suivi complète (grand-livre), avec les colonnes
  /// exactes de la fiche papier : PERTES / VENTE / ACHAT / NAIS / BILA / SITUATION / PROJECTIONS.
  Future<List<FicheLigne>> genererFicheLedger() async {
    if (_troupeauSelectionne == null) return [];
    final tousMouvements = await _db.getTousMouvementsPourFiche(
      troupeauId: _troupeauSelectionne?.id ?? 0, // Utilise 0 si null
    );
    final proprietairesDuTroupeau = _proprietaires
        .where((p) => tousMouvements.any((m) => m.proprietaireId == p.id))
        .toList();
    final lotsActuels = await _db.getLots(troupeauId: _troupeauSelectionne!.id);
    return FicheLedgerService.construire(
      mouvements: tousMouvements,
      proprietaires: proprietairesDuTroupeau,
      lotsActuels: lotsActuels,
    );
  }

  Future<void> chargerLots() async {
    if (_troupeauSelectionne == null) return;
    _lots = await _db.getLots(
      troupeauId: _troupeauSelectionne!.id,
      proprietaireId: null,
      filtreAge: _filtreAgeTaurions,
    );
    notifyListeners();
  }

  void setFiltreAge(FiltreAge filtre) {
    _filtreAgeTaurions = filtre;
    chargerLots();
  }

  /// Enregistre un mouvement et met à jour les lots en conséquence.
  ///
  /// Règle de regroupement des lots (entrées) : fusion automatique dans un
  /// lot existant de la même catégorie, SAUF si [enGestation] est vrai — dans
  /// ce cas un nouveau lot est TOUJOURS créé séparément, pour ne jamais
  /// perdre l'information de gestation (c'était la cause du bug où une vache
  /// ajoutée "en gestation" ne l'était plus : son entrée se fusionnait dans
  /// un lot existant non-gestant et l'info était silencieusement écrasée).
  Future<void> ajouterMouvement(
    Mouvement mouvement, {
    DateTime? dateNaissanceLot,
    bool enGestation = false,
    DateTime? dateGestation,
  }) async {
    await _db.insertMouvement(mouvement);
    if (mouvement.type.sens == 'entree' || mouvement.type.sens == 'ouverture') {
      if (enGestation) {
        await _db.insertLot(LotAnimal(
          troupeauId: mouvement.troupeauId,
          proprietaireId: mouvement.proprietaireId,
          categorie: mouvement.categorie,
          quantite: mouvement.quantite,
          dateNaissance: dateNaissanceLot ?? mouvement.date,
          enGestation: true,
          dateGestation: dateGestation ?? mouvement.date,
        ));
      } else {
        final lotsExistants = await _db.getLots(
          troupeauId: mouvement.troupeauId,
          proprietaireId: mouvement.proprietaireId,
          categorie: mouvement.categorie,
        );
        // Ne fusionne que dans un lot qui n'est PAS en gestation, pour ne
        // jamais mélanger un effectif "normal" avec un lot gestant existant.
        final lotsFusionnables = lotsExistants.where((l) => !l.enGestation).toList();
        if (lotsFusionnables.isNotEmpty) {
          final lot = lotsFusionnables.first;
          await _db.updateLotQuantite(lot.id!, lot.quantite + mouvement.quantite);
        } else {
          await _db.insertLot(LotAnimal(
            troupeauId: mouvement.troupeauId,
            proprietaireId: mouvement.proprietaireId,
            categorie: mouvement.categorie,
            quantite: mouvement.quantite,
            dateNaissance: dateNaissanceLot ?? mouvement.date,
          ));
        }
      }
    } else if (mouvement.type.sens == 'sortie') {
      var reste = mouvement.quantite;
      final lotsExistants = await _db.getLots(
        troupeauId: mouvement.troupeauId,
        proprietaireId: mouvement.proprietaireId,
        categorie: mouvement.categorie,
      );
      for (var lot in lotsExistants..sort((a, b) => a.dateNaissance.compareTo(b.dateNaissance))) {
        if (reste <= 0) break;
        if (lot.quantite <= reste) {
          reste -= lot.quantite;
          await _db.deleteLot(lot.id!);
        } else {
          await _db.updateLotQuantite(lot.id!, lot.quantite - reste);
          reste = 0;
        }
      }
    }
    await rafraichirDonnees();
  }

  Future<void> toggleGestation(LotAnimal lot, bool value, DateTime? dateGest) async {
    if (lot.categorie != CategorieAnimal.vache) return;
    await _db.updateLotGestation(lot.id!, value, dateGest);
    await rafraichirDonnees();
  }

  Future<void> supprimerMouvement(int mouvementId) async {
    await _db.deleteMouvement(mouvementId);
    await rafraichirDonnees();
  }

  /// Crée un propriétaire (sans cheptel) et le renvoie. Il devient le
  /// propriétaire par défaut des formulaires.
  Future<Proprietaire> ajouterProprietaire(String nom, {String? prenom, String? telephone}) async {
    final id = await _db.insertProprietaire(Proprietaire(nom: nom, prenom: prenom, telephone: telephone));
    _proprietaires = await _db.getProprietaires();
    final cree = _proprietaires.firstWhere((p) => p.id == id);
    _proprietaireSelectionne = cree;
    notifyListeners();
    return cree;
  }

  /// Enregistre un solde d'ouverture ("REPORT" sur la fiche — PAS un
  /// mouvement d'achat/vente/perte/naissance) : un mouvement de type report
  /// + un ajout au lot (fusion dans un lot non gestant de la même catégorie
  /// s'il existe, sinon nouveau lot). Ne rafraîchit pas : à l'appelant.
  Future<void> _ecrireCheptelOuverture({
    required int troupeauId,
    required int proprietaireId,
    required Map<CategorieAnimal, int> cheptel,
    required String note,
  }) async {
    final maintenant = DateTime.now();
    for (final entry in cheptel.entries) {
      if (entry.value <= 0) continue;
      await _db.insertMouvement(Mouvement(
        troupeauId: troupeauId,
        proprietaireId: proprietaireId,
        type: TypeMouvement.report,
        categorie: entry.key,
        quantite: entry.value,
        date: maintenant,
        notes: note,
      ));
      final existants = await _db.getLots(
        troupeauId: troupeauId,
        proprietaireId: proprietaireId,
        categorie: entry.key,
      );
      final fusionnables = existants.where((l) => !l.enGestation).toList();
      if (fusionnables.isNotEmpty) {
        final lot = fusionnables.first;
        await _db.updateLotQuantite(lot.id!, lot.quantite + entry.value);
      } else {
        await _db.insertLot(LotAnimal(
          troupeauId: troupeauId,
          proprietaireId: proprietaireId,
          categorie: entry.key,
          quantite: entry.value,
          dateNaissance: maintenant,
        ));
      }
    }
  }

  /// Création COMPLÈTE d'un propriétaire : un ou plusieurs blocs
  /// "troupeau + cheptel" (un propriétaire peut avoir du bétail dans
  /// plusieurs troupeaux). Zéro bloc = propriétaire créé sans cheptel.
  Future<Proprietaire> ajouterProprietaireAvecCheptels(
    String nom, {
    String? prenom,
    String? telephone,
    List<BlocTroupeauCheptel> blocs = const [],
  }) async {
    final id = await _db.insertProprietaire(Proprietaire(nom: nom, prenom: prenom, telephone: telephone));
    for (final b in blocs) {
      await _ecrireCheptelOuverture(
        troupeauId: b.troupeauId,
        proprietaireId: id,
        cheptel: b.cheptel,
        note: 'Cheptel initial à la création du propriétaire',
      );
    }
    _proprietaires = await _db.getProprietaires();
    final cree = _proprietaires.firstWhere((p) => p.id == id);
    _proprietaireSelectionne = cree;
    await rafraichirDonnees();
    return cree;
  }

  /// Ajoute du cheptel (solde d'ouverture) d'un propriétaire DÉJÀ existant
  /// dans un troupeau DÉJÀ existant. Sert aux deux entrées : "ajouter un
  /// propriétaire à ce troupeau" (depuis l'accueil) et "ajouter du cheptel
  /// dans un troupeau" (depuis la fiche d'un propriétaire).
  Future<void> attribuerCheptel({
    required int troupeauId,
    required int proprietaireId,
    required Map<CategorieAnimal, int> cheptel,
    String note = 'Cheptel ajouté au troupeau',
  }) async {
    await _ecrireCheptelOuverture(
      troupeauId: troupeauId,
      proprietaireId: proprietaireId,
      cheptel: cheptel,
      note: note,
    );
    await rafraichirDonnees();
  }

  Future<void> ajouterTroupeau(String nom, {String? code}) async {
    final id = await _db.insertTroupeau(Troupeau(nom: nom, code: code));
    _troupeaux = await _db.getTroupeaux();
    _troupeauSelectionne = _troupeaux.firstWhere((t) => t.id == id);
    notifyListeners();
  }

  /// "Nouveau troupeau" : un troupeau est créé avec zéro, un ou plusieurs
  /// blocs "propriétaire + cheptel" (un troupeau peut contenir le bétail de
  /// plusieurs propriétaires, comme sur la fiche papier). N'enlève RIEN à
  /// aucun troupeau existant.
  Future<void> ajouterTroupeauAvecProprietaires(
    String nom, {
    String? code,
    List<BlocProprietaireCheptel> blocs = const [],
  }) async {
    final id = await _db.insertTroupeau(Troupeau(nom: nom, code: code));
    for (final b in blocs) {
      await _ecrireCheptelOuverture(
        troupeauId: id,
        proprietaireId: b.proprietaireId,
        cheptel: b.cheptel,
        note: 'Cheptel initial à la création du troupeau',
      );
    }
    _troupeaux = await _db.getTroupeaux();
    _troupeauSelectionne = _troupeaux.firstWhere((t) => t.id == id);
    await rafraichirDonnees();
  }

  /// Situation d'UN propriétaire dans un troupeau PRÉCIS (pas forcément le
  /// troupeau sélectionné) — utilisé pour plafonner les quantités d'une
  /// scission.
  Future<Situation> getSituationDansTroupeau(int troupeauId, int proprietaireId) =>
      _db.getSituation(troupeauId: troupeauId, proprietaireId: proprietaireId);

  /// "Scinder un troupeau existant" : crée un nouveau troupeau en
  /// prélevant, sur le troupeau source, les quantités de UN OU PLUSIEURS
  /// propriétaires en une seule opération ([quantitesParProprietaire] :
  /// proprietaireId -> catégorie -> quantité). Contrairement à "Nouveau
  /// troupeau", ceci RETIRE les quantités du troupeau source. Le transfert
  /// n'est pas comptabilisé comme une "Perte" : les lots sont déplacés et le
  /// nouveau troupeau reçoit un solde d'ouverture ("REPORT").
  Future<void> scinderTroupeau({
    required int troupeauSourceId,
    required String nomNouveauTroupeau,
    String? codeNouveauTroupeau,
    required Map<int, Map<CategorieAnimal, int>> quantitesParProprietaire,
  }) async {
    final nouveauId = await _db.insertTroupeau(Troupeau(nom: nomNouveauTroupeau, code: codeNouveauTroupeau));

    for (final parProp in quantitesParProprietaire.entries) {
      final proprietaireId = parProp.key;
      final prelevement = <CategorieAnimal, int>{};

      for (final entry in parProp.value.entries) {
        final qte = entry.value;
        if (qte <= 0) continue;

        // Retire la quantité du troupeau source (lots les plus anciens d'abord).
        var reste = qte;
        final lotsSource = await _db.getLots(
          troupeauId: troupeauSourceId,
          proprietaireId: proprietaireId,
          categorie: entry.key,
        )
          ..sort((a, b) => a.dateNaissance.compareTo(b.dateNaissance));
        for (final lot in lotsSource) {
          if (reste <= 0) break;
          if (lot.quantite <= reste) {
            reste -= lot.quantite;
            await _db.deleteLot(lot.id!);
          } else {
            await _db.updateLotQuantite(lot.id!, lot.quantite - reste);
            reste = 0;
          }
        }
        prelevement[entry.key] = qte - reste; // réellement prélevé
      }

      await _ecrireCheptelOuverture(
        troupeauId: nouveauId,
        proprietaireId: proprietaireId,
        cheptel: prelevement,
        note: 'Scission depuis un troupeau existant',
      );
    }

    _troupeaux = await _db.getTroupeaux();
    _troupeauSelectionne = _troupeaux.firstWhere((t) => t.id == nouveauId);
    await rafraichirDonnees();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

/// Un bloc "propriétaire + cheptel" saisi à la création d'un troupeau.
class BlocProprietaireCheptel {
  final int proprietaireId;
  final Map<CategorieAnimal, int> cheptel;
  const BlocProprietaireCheptel(this.proprietaireId, this.cheptel);
}

/// Un bloc "troupeau + cheptel" saisi à la création d'un propriétaire.
class BlocTroupeauCheptel {
  final int troupeauId;
  final Map<CategorieAnimal, int> cheptel;
  const BlocTroupeauCheptel(this.troupeauId, this.cheptel);
}
