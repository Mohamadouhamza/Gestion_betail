import 'enums.dart';

class Proprietaire {
  final int? id;
  final String nom;
  final String? prenom;
  final String? telephone;

  Proprietaire({this.id, required this.nom, this.prenom, this.telephone});

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'telephone': telephone,
  };

  factory Proprietaire.fromMap(Map<String, dynamic> map) => Proprietaire(
    id: map['id'] as int?,
    nom: map['nom'] as String,
    prenom: map['prenom'] as String?,
    telephone: map['telephone'] as String?,
  );
}

class Troupeau {
  final int? id;
  final String nom;
  final String? code;

  Troupeau({this.id, required this.nom, this.code});

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'code': code,
  };

  factory Troupeau.fromMap(Map<String, dynamic> map) => Troupeau(
    id: map['id'] as int?,
    nom: map['nom'] as String,
    code: map['code'] as String?,
  );
}

class LotAnimal {
  final int? id;
  final int troupeauId;
  final int proprietaireId;
  final CategorieAnimal categorie;
  final int quantite;
  final DateTime dateNaissance;
  final bool enGestation;
  final DateTime? dateGestation;
  final String? notes;

  // Durée de gestation moyenne d'une vache : ~283 jours (9 mois et 9 jours)
  static const int dureeGestationJours = 283;

  LotAnimal({
    this.id,
    required this.troupeauId,
    required this.proprietaireId,
    required this.categorie,
    required this.quantite,
    required this.dateNaissance,
    this.enGestation = false,
    this.dateGestation,
    this.notes,
  });

  int get ageEnMois {
    final now = DateTime.now();
    return (now.year - dateNaissance.year) * 12 + now.month - dateNaissance.month;
  }

  String get ageAffichage {
    final mois = ageEnMois;
    if (mois < 12) return '$mois mois';
    final annees = mois ~/ 12;
    final reste = mois % 12;
    if (reste == 0) return '$annees an${annees > 1 ? 's' : ''}';
    return '$annees an${annees > 1 ? 's' : ''} $reste mois';
  }

  /// Date de terme prévue (accouchement) si en gestation
  DateTime? get dateTermeGestation {
    if (dateGestation == null) return null;
    return dateGestation!.add(const Duration(days: dureeGestationJours));
  }

  /// Nombre de mois de gestation écoulés depuis le début
  int? get moisGestationEcoules {
    if (dateGestation == null) return null;
    final now = DateTime.now();
    var mois = (now.year - dateGestation!.year) * 12 + now.month - dateGestation!.month;
    if (mois < 0) mois = 0;
    return mois;
  }

  /// Nombre de jours restants avant le terme (peut être négatif si dépassé)
  int? get joursRestantsGestation {
    final terme = dateTermeGestation;
    if (terme == null) return null;
    return terme.difference(DateTime.now()).inDays;
  }

  /// Affichage lisible : "6 mois (terme dans 45 j)" ou "Terme dépassé de 3 j"
  String get gestationAffichage {
    if (!enGestation || dateGestation == null) return '';
    final mois = moisGestationEcoules ?? 0;
    final joursRestants = joursRestantsGestation ?? 0;
    if (joursRestants < 0) {
      return '$mois mois – terme dépassé de ${-joursRestants} j';
    }
    return '$mois mois – terme dans $joursRestants j';
  }

  /// Vrai si le terme de gestation est atteint ou dépassé (à clôturer automatiquement)
  bool get gestationTerminee {
    if (!enGestation || dateGestation == null) return false;
    return DateTime.now().isAfter(dateTermeGestation!);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'troupeauId': troupeauId,
    'proprietaireId': proprietaireId,
    'categorie': categorie.code,
    'quantite': quantite,
    'dateNaissance': dateNaissance.toIso8601String(),
    'enGestation': enGestation ? 1 : 0,
    'dateGestation': dateGestation?.toIso8601String(),
    'notes': notes,
  };

  factory LotAnimal.fromMap(Map<String, dynamic> map) => LotAnimal(
    id: map['id'] as int?,
    troupeauId: map['troupeauId'] as int,
    proprietaireId: map['proprietaireId'] as int,
    categorie: CategorieAnimal.values.firstWhere((e) => e.code == map['categorie']),
    quantite: map['quantite'] as int,
    dateNaissance: DateTime.parse(map['dateNaissance'] as String),
    enGestation: map['enGestation'] == 1,
    dateGestation: map['dateGestation'] != null ? DateTime.parse(map['dateGestation'] as String) : null,
    notes: map['notes'] as String?,
  );
}

class Mouvement {
  final int? id;
  final int troupeauId;
  final int proprietaireId;
  final TypeMouvement type;
  final CategorieAnimal categorie;
  final int quantite;
  final DateTime date;
  final double? prix;
  final String? notes;

  Mouvement({
    this.id,
    required this.troupeauId,
    required this.proprietaireId,
    required this.type,
    required this.categorie,
    required this.quantite,
    required this.date,
    this.prix,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'troupeauId': troupeauId,
    'proprietaireId': proprietaireId,
    'type': type.name,
    'categorie': categorie.code,
    'quantite': quantite,
    'date': date.toIso8601String(),
    'prix': prix,
    'notes': notes,
  };

  factory Mouvement.fromMap(Map<String, dynamic> map) => Mouvement(
    id: map['id'] as int?,
    troupeauId: map['troupeauId'] as int,
    proprietaireId: map['proprietaireId'] as int,
    type: TypeMouvement.values.firstWhere((e) => e.name == map['type']),
    categorie: CategorieAnimal.values.firstWhere((e) => e.code == map['categorie']),
    quantite: map['quantite'] as int,
    date: DateTime.parse(map['date'] as String),
    prix: map['prix'] as double?,
    notes: map['notes'] as String?,
  );
}

class Situation {
  final int taurions;
  final int genisses;
  final int vaches;
  final int veauxMales;
  final int veauxFemelles;
  final int gestation;
  final DateTime date;

  const Situation({
    required this.taurions,
    required this.genisses,
    required this.vaches,
    required this.veauxMales,
    required this.veauxFemelles,
    required this.gestation,
    required this.date,
  });

  int get total => taurions + genisses + vaches + veauxMales + veauxFemelles;
  int get veauxTotal => veauxMales + veauxFemelles;

  int getByCategorie(CategorieAnimal cat) {
    switch (cat) {
      case CategorieAnimal.taurion: return taurions;
      case CategorieAnimal.genisse: return genisses;
      case CategorieAnimal.vache: return vaches;
      case CategorieAnimal.veauMale: return veauxMales;
      case CategorieAnimal.veauFemelle: return veauxFemelles;
    }
  }
}

/// Représente UNE ligne de la fiche papier (une date + un propriétaire, ou la ligne TOTAL)
/// Reproduit exactement la structure : DATE | PROPRIET | PERTES(T,G,V,VM,VF) | VENTE(T,G,V)
/// | ACHAT(T,G) | NAIS(M,F) | BILA | SITUATION(T,G,V,VM,VF,TOT) | GEST | DATE proj | NOM | OBS
class FicheLigne {
  final DateTime date;
  final String proprietaire; // nom, ou "TOTAL"
  final bool estTotal;
  final bool estReport;

  // MOUVEMENTS > PERTES
  final int perteT, perteG, perteV, perteVM, perteVF;
  // MOUVEMENTS > VENTE
  final int venteT, venteG, venteV;
  // MOUVEMENTS > ACHAT
  final int achatT, achatG;
  // MOUVEMENTS > NAIS
  final int naisM, naisF;
  // BILA (vérification : achats+naissances - pertes-ventes)
  final int? bila;
  // SITUATION A DATE
  final int sitT, sitG, sitV, sitVM, sitVF;
  // PROJECTIONS
  final int gest;
  final DateTime? dateProjection;
  final int nom; // total projeté = TOT + GEST
  final String observations;

  FicheLigne({
    required this.date,
    required this.proprietaire,
    this.estTotal = false,
    this.estReport = false,
    this.perteT = 0, this.perteG = 0, this.perteV = 0, this.perteVM = 0, this.perteVF = 0,
    this.venteT = 0, this.venteG = 0, this.venteV = 0,
    this.achatT = 0, this.achatG = 0,
    this.naisM = 0, this.naisF = 0,
    this.bila,
    required this.sitT, required this.sitG, required this.sitV, required this.sitVM, required this.sitVF,
    this.gest = 0,
    this.dateProjection,
    int? nom,
    this.observations = '',
  }) : nom = nom ?? (sitT + sitG + sitV + sitVM + sitVF + gest);

  int get sitTotal => sitT + sitG + sitV + sitVM + sitVF;
  int get totalPertes => perteT + perteG + perteV + perteVM + perteVF;
  int get totalVentes => venteT + venteG + venteV;
  int get totalAchats => achatT + achatG;
  int get totalNaissances => naisM + naisF;
}
