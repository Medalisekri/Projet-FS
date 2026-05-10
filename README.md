

## 📋 Table des matières

- [À propos du projet](#-à-propos-du-projet)
- [Fonctionnalités](#-fonctionnalités)
- [Stack technique](#-stack-technique)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Exécution](#-exécution)
- [Tests](#-tests)
- [Déploiement](#-déploiement)
- [Contribuer](#-contribuer)

---

## 🧭 À propos du projet

**ReFound** est une application mobile multiplateforme (Android & iOS) qui centralise le signalement des objets perdus et trouvés. Elle répond aux limites des solutions existantes (groupes Facebook, services SNCF/RATP, apps génériques) en proposant :

- 📍 Un signalement géolocalisé rapide depuis un smartphone
- 🗺️ Une carte interactive des signalements en temps réel
- 💬 Une messagerie sécurisée entre propriétaires et inventeurs
- 🔒 Une conformité RGPD avec anonymisation des données privées

---

## ✨ Fonctionnalités

| Fonctionnalité | Description |
|---|---|
| **Authentification** | Inscription/Connexion par email ou compte Google (Firebase Auth / OAuth 2.0) |
| **Déclaration d'objets** | Formulaire avec catégorie, photo, description, horodatage et géolocalisation |
| **Carte interactive** | Marqueurs colorés (🔴 Perdu / 🟢 Trouvé) avec clustering et filtres dynamiques |
| **Messagerie instantanée** | Chat en temps réel via Firestore Streams, avec suppression auto après 90 jours |
| **Gestion du profil** | Modification du nom, numéro de téléphone et paramètres personnels |
| **Administration** | Modération des annonces, gestion des utilisateurs et statistiques de la plateforme |

---

## 🛠️ Stack technique

| Couche | Technologie |
|---|---|
| **Frontend / Mobile** | [Flutter](https://flutter.dev/) (Dart) — iOS & Android |
| **Authentification** | [Firebase Authentication](https://firebase.google.com/products/auth) (OAuth 2.0, Google Sign-In) |
| **Base de données** | [Cloud Firestore](https://firebase.google.com/products/firestore) (temps réel) |
| **Hébergement des médias** | [ImgBB API](https://api.imgbb.com/) |
| **Cartographie** | [OpenStreetMap](https://www.openstreetmap.org/) via `flutter_map` |
| **IDE recommandé** | Visual Studio Code + extensions Flutter/Dart |

---

## ✅ Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **>= 3.0.0**
- [Dart SDK](https://dart.dev/get-dart) **>= 3.0.0** (inclus avec Flutter)
- [Android Studio](https://developer.android.com/studio) ou [Xcode](https://developer.apple.com/xcode/) (pour les émulateurs)
- [Visual Studio Code](https://code.visualstudio.com/) avec les extensions **Flutter** et **Dart**
- Un compte [Firebase](https://console.firebase.google.com/)
- Un compte [ImgBB](https://imgbb.com/) pour la clé API d'hébergement des images
- [Git](https://git-scm.com/)

Vérifier que Flutter est correctement installé :

```bash
flutter doctor
```

Toutes les cases doivent être cochées ✅ avant de continuer.

---

## 🚀 Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/<votre-username>/refound.git
cd refound
```

### 2. Installer les dépendances Flutter

```bash
flutter pub get
```

### 3. Configurer Firebase

#### a) Créer un projet Firebase

1. Rendez-vous sur la [console Firebase](https://console.firebase.google.com/)
2. Créez un nouveau projet : **ReFound**
3. Activez les services suivants :
   - **Authentication** → Email/Mot de passe + Google Sign-In
   - **Cloud Firestore** → démarrer en mode test
   - **Storage** (optionnel si vous utilisez ImgBB)

#### b) Ajouter l'application Android

1. Dans Firebase Console → Paramètres du projet → Ajouter une application Android
2. Renseignez le `Package Name` (ex: `com.votreusername.refound`)
3. Téléchargez le fichier `google-services.json`
4. Placez-le dans :

```
android/app/google-services.json
```

#### c) Ajouter l'application iOS (optionnel)

1. Dans Firebase Console → Paramètres du projet → Ajouter une application iOS
2. Téléchargez le fichier `GoogleService-Info.plist`
3. Placez-le dans :

```
ios/Runner/GoogleService-Info.plist
```

---

## ⚙️ Configuration

### Variables d'environnement

Créez un fichier `.env` à la racine du projet (ne jamais le committer) :

```env
IMGBB_API_KEY=votre_cle_imgbb_ici
```

> ⚠️ **Sécurité :** Ne jamais exposer vos clés API dans le code source. Utilisez le package [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) pour les charger.

### Chargement du `.env` dans `main.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

### Configuration du `.gitignore`

Assurez-vous que les fichiers sensibles sont bien ignorés :

```gitignore
# Firebase
android/app/google-services.json
ios/Runner/GoogleService-Info.plist

# Variables d'environnement
.env

# Flutter
.dart_tool/
build/
*.g.dart
```

### Règles Firestore

Dans la console Firebase, configurez les règles de sécurité Firestore :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Annonces : lecture publique, écriture authentifiée
    match /items/{itemId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    // Messages : accès uniquement aux participants
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth.uid in resource.data.participants;
    }
    // Profils utilisateurs
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

---

## ▶️ Exécution

### Lancer sur un émulateur ou appareil physique

Lister les appareils disponibles :

```bash
flutter devices
```

Lancer l'application en mode debug :

```bash
flutter run
```

Lancer sur un appareil spécifique :

```bash
flutter run -d <device_id>
```

### Modes de lancement

| Commande | Description |
|---|---|
| `flutter run` | Mode debug (hot reload activé) |
| `flutter run --release` | Mode release (performances optimisées) |
| `flutter run --profile` | Mode profil (analyse des performances) |

### Hot Reload & Hot Restart

Pendant l'exécution en mode debug dans le terminal :
- `r` → Hot Reload (recharge l'UI sans redémarrer)
- `R` → Hot Restart (redémarre l'application)
- `q` → Quitter

---

## 🧪 Tests

### Structure des tests

```
test/
├── unit/           # Tests unitaires (logique métier)
├── widget/         # Tests de widgets Flutter
└── integration/    # Tests d'intégration end-to-end
```

### Lancer tous les tests

```bash
flutter test
```

### Tests unitaires uniquement

```bash
flutter test test/unit/
```

### Tests de widgets

```bash
flutter test test/widget/
```

### Tests d'intégration (sur appareil ou émulateur)

```bash
flutter test integration_test/
```

### Exemple de test unitaire

```dart
// test/unit/item_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:refound/models/item_model.dart';

void main() {
  group('ItemModel', () {
    test('should create a valid lost item', () {
      final item = ItemModel(
        title: 'Clés de voiture',
        type: ItemType.lost,
        category: 'Clefs',
        latitude: 48.8566,
        longitude: 2.3522,
      );
      expect(item.type, ItemType.lost);
      expect(item.category, 'Clefs');
    });
  });
}
```

### Exemple de test de widget

```dart
// test/widget/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refound/screens/login_screen.dart';

void main() {
  testWidgets('Login screen displays email and password fields', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
```

### Rapport de couverture

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```



## 📦 Déploiement

### Générer un APK Android (release)

```bash
flutter build apk --release
```

Le fichier APK est généré dans :
```
build/app/outputs/flutter-apk/app-release.apk
```

### Générer un App Bundle Android (Play Store)

```bash
flutter build appbundle --release
```

### Générer l'application iOS (release)

```bash
flutter build ios --release
```

> Nécessite un Mac avec Xcode et un compte Apple Developer.

---

## 🤝 Contribuer

1. Forkez le projet
2. Créez votre branche feature : `git checkout -b feature/nouvelle-fonctionnalite`
3. Commitez vos changements : `git commit -m 'feat: ajout de la nouvelle fonctionnalité'`
4. Pushez vers la branche : `git push origin feature/nouvelle-fonctionnalite`
5. Ouvrez une Pull Request

---

## 📅 Planification du projet

| Livrable | Semaine |
|---|---|
| Cahier des charges | Semaine 1 |
| Setup projet + authentification | Semaine 2 |
| Déclarations & upload photos (ImgBB) | Semaines 3–4 |
| Carte & géolocalisation | Semaine 5 |
| Notifications | Semaines 6–7 |
| Chat & messagerie | Semaine 8 |
| Tests, corrections et déploiement | Semaine 9 |




