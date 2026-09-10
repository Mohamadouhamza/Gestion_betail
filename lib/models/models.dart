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
