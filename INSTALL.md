# 🚀 Installation Gestion Bétail

## Étape 1: Crée un projet Flutter vierge

```bash
flutter create gestion_betail
cd gestion_betail
```

Ça crée la structure complète (android/, ios/, web/, lib/, pubspec.yaml, etc.)

## Étape 2: Copie les fichiers de ce ZIP

Depuis ce ZIP, copie:
- `lib/` → remplace le `lib/` du projet
- `pubspec.yaml` → remplace le `pubspec.yaml` du projet
- `.github/` → copie le dossier entier

Structure finale:
```
gestion_betail/
├── android/              ← Gardé (créé par flutter create)
├── lib/                  ← NOUVEAU (depuis ZIP)
├── pubspec.yaml          ← NOUVEAU (depuis ZIP)
├── .github/
│   └── workflows/
│       └── build.yml     ← NOUVEAU (depuis ZIP)
└── ...
```

## Étape 3: Test local (optionnel)

```bash
flutter clean
flutter pub get
flutter run
```

## Étape 4: Push sur GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/TON_USERNAME/gestion-betail.git
git push -u origin main
```

## Étape 5: GitHub Actions compile

Attends ~15 min → Actions tab → Télécharge app-release.apk

## Étape 6: Installe sur téléphone

```bash
adb install -r app-release.apk
```

## ✅ C'est tout !

La structure Android/iOS existe déjà (créée par `flutter create`)
Le workflow est simple (juste compile)
L'app marche parfaitement

---

**Version:** Minimaliste Setup  
**Temps total:** ~15 min (compilation GitHub)  
**Status:** ✅ Production Ready
