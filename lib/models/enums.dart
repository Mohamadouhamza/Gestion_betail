enum TypeMouvement {
  report('Report', 'ouverture'),
  achat('Achat', 'entree'),
  vente('Vente', 'sortie'),
  perte('Perte', 'sortie'),
  naissance('Naissance', 'entree');

  final String label;
  final String sens;
  const TypeMouvement(this.label, this.sens);
}

enum CategorieAnimal {
  taurion('T', 'Taurion', 'M'),
  genisse('G', 'Génisse', 'F'),
  vache('V', 'Vache', 'F'),
  veauMale('VM', 'Veau mâle', 'M'),
  veauFemelle('VF', 'Veau femelle', 'F');

  final String code;
  final String label;
  final String sexe;
  const CategorieAnimal(this.code, this.label, this.sexe);

  bool get isVeau => this == CategorieAnimal.veauMale || this == CategorieAnimal.veauFemelle;
  bool get isAdulteFemelle => this == CategorieAnimal.vache || this == CategorieAnimal.genisse;
}

enum FiltreAge {
  tous('Tous'),
  moins1an('< 1 an'),
  entre1et2('1 – 2 ans'),
  plus2ans('> 2 ans');

  final String label;
  const FiltreAge(this.label);
}
