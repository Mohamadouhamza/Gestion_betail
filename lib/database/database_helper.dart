import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';
import '../models/enums.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gestion_betail.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''\
      CREATE TABLE proprietaires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT,
        telephone TEXT
      )
    ''');

    await db.execute('''\
      CREATE TABLE troupeaux (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        code TEXT
      )
    ''');

    await db.execute('''\
      CREATE TABLE lots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        troupeauId INTEGER NOT NULL,
        proprietaireId INTEGER NOT NULL,
        categorie TEXT NOT NULL,
        quantite INTEGER NOT NULL,
        dateNaissance TEXT NOT NULL,
        enGestation INTEGER DEFAULT 0,
        dateGestation TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''\
      CREATE TABLE mouvements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        troupeauId INTEGER NOT NULL,
        proprietaireId INTEGER NOT NULL,
        type TEXT NOT NULL,
        categorie TEXT NOT NULL,
        quantite INTEGER NOT NULL,
        date TEXT NOT NULL,
        prix REAL,
        notes TEXT
      )
    ''');

    // Données de test
    await db.insert('proprietaires', {'nom': 'ABDOUL'});
    await db.insert('proprietaires', {'nom': 'ALI'});
    await db.insert('troupeaux', {'nom': 'Troupeau AH', 'code': 'AH'});
    await db.insert('troupeaux', {'nom': 'Troupeau VF', 'code': 'VF'});

    final abdoul = (await db.query('proprietaires', where: 'nom = ?', whereArgs: ['ABDOUL'])).first;
    final ali = (await db.query('proprietaires', where: 'nom = ?', whereArgs: ['ALI'])).first;
    final troupeauAh = (await db.query('troupeaux', where: 'code = ?', whereArgs: ['AH'])).first;

    await db.insert('lots', {
      'troupeauId': troupeauAh['id'],
      'proprietaireId': abdoul['id'],
      'categorie': 'T',
      'quantite': 5,
      'dateNaissance': DateTime(2018, 6).toIso8601String(),
    });
    await db.insert('lots', {
      'troupeauId': troupeauAh['id'],
      'proprietaireId': abdoul['id'],
      'categorie': 'G',
      'quantite': 3,
      'dateNaissance': DateTime(2019, 1).toIso8601String(),
    });
    await db.insert('lots', {
      'troupeauId': troupeauAh['id'],
      'proprietaireId': ali['id'],
      'categorie': 'V',
      'quantite': 2,
      'dateNaissance': DateTime(2016, 3).toIso8601String(),
      'enGestation': 1,
      'dateGestation': DateTime(2023, 10).toIso8601String(),
    });
  }

  Future<List<Proprietaire>> getProprietaires() async {
    final db = await database;
    final maps = await db.query('proprietaires');
    return maps.map((e) => Proprietaire.fromMap(e)).toList();
  }

  Future<int> insertProprietaire(Proprietaire p) async {
    final db = await database;
    return await db.insert('proprietaires', p.toMap());
  }

  Future<List<Troupeau>> getTroupeaux() async {
    final db = await database;
    final maps = await db.query('troupeaux');
    return maps.map((e) => Troupeau.fromMap(e)).toList();
  }

  Future<int> insertTroupeau(Troupeau t) async {
    final db = await database;
    return await db.insert('troupeaux', t.toMap());
  }

  Future<int> insertLot(LotAnimal lot) async {
    final db = await database;
    return await db.insert('lots', lot.toMap());
  }

  Future<void> updateLotQuantite(int lotId, int nouvelleQuantite) async {
    final db = await database;
    await db.update('lots', {'quantite': nouvelleQuantite}, where: 'id = ?', whereArgs: [lotId]);
  }

  Future<void> deleteLot(int lotId) async {
    final db = await database;
    await db.delete('lots', where: 'id = ?', whereArgs: [lotId]);
  }

  Future<void> updateLotGestation(int lotId, bool enGestation, DateTime? dateGestation) async {
    final db = await database;
    await db.update('lots', {
      'enGestation': enGestation ? 1 : 0,
      'dateGestation': dateGestation?.toIso8601String(),
    }, where: 'id = ?', whereArgs: [lotId]);
  }

  Future<List<LotAnimal>> getLots({
    int? troupeauId,
    int? proprietaireId,
    CategorieAnimal? categorie,
    FiltreAge? filtreAge,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (troupeauId != null) {
      conditions.add('troupeauId = ?');
      args.add(troupeauId);
    }
    if (proprietaireId != null) {
      conditions.add('proprietaireId = ?');
      args.add(proprietaireId);
    }
    if (categorie != null) {
      conditions.add('categorie = ?');
      args.add(categorie.code);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    final maps = await db.query('lots', where: whereClause, whereArgs: args.isNotEmpty ? args : null);
    var lots = maps.map((e) => LotAnimal.fromMap(e)).toList();

    if (filtreAge != null && filtreAge != FiltreAge.tous && categorie == CategorieAnimal.taurion) {
      lots = lots.where((lot) {
        final mois = lot.ageEnMois;
        switch (filtreAge) {
          case FiltreAge.moins1an: return mois < 12;
          case FiltreAge.entre1et2: return mois >= 12 && mois <= 24;
          case FiltreAge.plus2ans: return mois > 24;
          default: return true;
        }
      }).toList();
    }
    return lots;
  }

  Future<int> insertMouvement(Mouvement mouvement) async {
    final db = await database;
    return await db.insert('mouvements', mouvement.toMap());
  }

  Future<void> deleteMouvement(int id) async {
    final db = await database;
    await db.delete('mouvements', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Mouvement>> getMouvements({
    int? troupeauId,
    int? proprietaireId,
    int limit = 100,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (troupeauId != null) {
      conditions.add('troupeauId = ?');
      args.add(troupeauId);
    }
    if (proprietaireId != null) {
      conditions.add('proprietaireId = ?');
      args.add(proprietaireId);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    final maps = await db.query(
      'mouvements',
      where: whereClause,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((e) => Mouvement.fromMap(e)).toList();
  }

  Future<Situation> getSituation({int? troupeauId, int? proprietaireId}) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (troupeauId != null) {
      conditions.add('troupeauId = ?');
      args.add(troupeauId);
    }
    if (proprietaireId != null) {
      conditions.add('proprietaireId = ?');
      args.add(proprietaireId);
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final maps = await db.rawQuery('''\
      SELECT categorie, SUM(quantite) as total 
      FROM lots 
      $whereClause
      GROUP BY categorie
    ''', args);

    int t = 0, g = 0, v = 0, vm = 0, vf = 0, gest = 0;
    for (var row in maps) {
      final cat = row['categorie'] as String;
      final total = (row['total'] as num?)?.toInt() ?? 0;
      switch (cat) {
        case 'T': t = total; break;
        case 'G': g = total; break;
        case 'V': v = total; break;
        case 'VM': vm = total; break;
        case 'VF': vf = total; break;
      }
    }

    final gestConditions = <String>[];
    final gestArgs = <dynamic>[];
    if (troupeauId != null) {
      gestConditions.add('troupeauId = ?');
      gestArgs.add(troupeauId);
    }
    if (proprietaireId != null) {
      gestConditions.add('proprietaireId = ?');
      gestArgs.add(proprietaireId);
    }
    gestConditions.add("categorie = 'V'");
    gestConditions.add('enGestation = 1');

    final gestMaps = await db.rawQuery('''\
      SELECT SUM(quantite) as total 
      FROM lots 
      WHERE ${gestConditions.join(' AND ')}\
    ''', gestArgs);
    gest = (gestMaps.first['total'] as num?)?.toInt() ?? 0;

    return Situation(
      taurions: t,
      genisses: g,
      vaches: v,
      veauxMales: vm,
      veauxFemelles: vf,
      gestation: gest,
      date: DateTime.now(),
    );
  }
}
