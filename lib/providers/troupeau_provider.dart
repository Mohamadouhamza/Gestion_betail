import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../models/enums.dart';

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

  List<Proprietaire> get proprietaires => _proprietaires;
  List<Troupeau> get troupeaux => _troupeaux;
  Proprietaire? get proprietaireSelectionne => _proprietaireSelectionne;
  Troupeau? get troupeauSelectionne => _troupeauSelectionne;
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
    await rafraichirDonnees();
    _setLoading(false);
  }

  Future<void> selectionnerProprietaire(Proprietaire p) async {
    _proprietaireSelectionne = p;
    await rafraichirDonnees();
    notifyListeners();
  }

  Future<void> selectionnerTroupeau(Troupeau t) async {
    _troupeauSelectionne = t;
    await rafraichirDonnees();
    notifyListeners();
  }

  Future<void> rafraichirDonnees() async {
    if (_troupeauSelectionne == null) return;
    _setLoading(true);
    _situation = await _db.getSituation(
      troupeauId: _troupeauSelectionne!.id,
      proprietaireId: _proprietaireSelectionne?.id,
    );
    _mouvementsRecents = await _db.getMouvements(
      troupeauId: _troupeauSelectionne!.id,
      proprietaireId: _proprietaireSelectionne?.id,
      limit: 50,
    );
    await chargerLots();
    _setLoading(false);
  }

  Future<void> chargerLots() async {
    if (_troupeauSelectionne == null) return;
    _lots = await _db.getLots(
      troupeauId: _troupeauSelectionne!.id,
      proprietaireId: _proprietaireSelectionne?.id,
      filtreAge: _filtreAgeTaurions,
    );
    notifyListeners();
  }

  void setFiltreAge(FiltreAge filtre) {
    _filtreAgeTaurions = filtre;
    chargerLots();
  }

  Future<void> ajouterMouvement(Mouvement mouvement, {LotAnimal? nouveauLot}) async {
    await _db.insertMouvement(mouvement);
    if (mouvement.type.sens == 'entree') {
      if (nouveauLot != null) {
        await _db.insertLot(nouveauLot);
      } else {
        final lotsExistants = await _db.getLots(
          troupeauId: mouvement.troupeauId,
          proprietaireId: mouvement.proprietaireId,
          categorie: mouvement.categorie,
        );
        if (lotsExistants.isNotEmpty) {
          final lot = lotsExistants.first;
          await _db.updateLotQuantite(lot.id!, lot.quantite + mouvement.quantite);
        } else {
          await _db.insertLot(LotAnimal(
            troupeauId: mouvement.troupeauId,
            proprietaireId: mouvement.proprietaireId,
            categorie: mouvement.categorie,
            quantite: mouvement.quantite,
            dateNaissance: mouvement.date,
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

  Future<void> ajouterProprietaire(String nom, {String? prenom, String? telephone}) async {
    final id = await _db.insertProprietaire(Proprietaire(nom: nom, prenom: prenom, telephone: telephone));
    _proprietaires = await _db.getProprietaires();
    _proprietaireSelectionne = _proprietaires.firstWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> ajouterTroupeau(String nom, {String? code}) async {
    final id = await _db.insertTroupeau(Troupeau(nom: nom, code: code));
    _troupeaux = await _db.getTroupeaux();
    _troupeauSelectionne = _troupeaux.firstWhere((t) => t.id == id);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
