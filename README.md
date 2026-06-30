# BadWallet — Application mobile Consumer

Application mobile **Flutter** de paiement et de transfert d'argent, dans l'esprit
des portefeuilles électroniques type **Wave / Orange Money**. Elle consomme l'API
backend **BadWallet** : consultation du solde, transferts entre comptes, paiement
de factures et historique des transactions.

## Prérequis

- **Flutter SDK** (Dart `^3.12.0`) installé et configuré (`flutter doctor`).
- Un **device physique** ou un **émulateur/simulateur** (Android ou iOS).
- Le **backend BadWallet lancé en local**, indispensable au fonctionnement de l'app :
  - **badwallet-api** sur le port **8080** (auth, solde, transactions, transferts) ;
  - **payment-service** sur le port **8081** (nécessaire pour les **factures**).

> Sans backend démarré, l'app affiche des erreurs de connexion (« Impossible de
> joindre le serveur »).

## Configuration de l'URL backend

L'adresse du backend est centralisée dans **une seule constante** :
`lib/core/constants/api_constants.dart` → `apiBaseUrl`.

Adaptez-la selon la cible d'exécution :

| Cible                  | Valeur de `apiBaseUrl`            |
| ---------------------- | --------------------------------- |
| **iOS Simulator**      | `http://localhost:8080`           |
| **Émulateur Android**  | `http://10.0.2.2:8080`            |
| **Device physique**    | `http://192.168.x.x:8080` (IP locale de la machine qui héberge le back) |

```dart
// lib/core/constants/api_constants.dart
const String apiBaseUrl = 'http://localhost:8080';
```

> Sur un téléphone réel, `localhost` désigne le téléphone lui-même : il faut
> renseigner l'**IP locale** de votre Mac/PC sur le même réseau Wi-Fi.

## Installation

```bash
cd gestion_paiement_flutter
flutter pub get
```

## Lancement

```bash
flutter run                 # device par défaut
flutter run -d <device_id>  # cibler un device précis (cf. flutter devices)
```

## Utilisation

À l'écran d'authentification, saisissez un **numéro de téléphone existant côté
backend** (créé par le seed). Exemple : **`+221770000003`**, qui dispose d'un
solde, de transactions et de factures.

## Fonctionnalités

- **Authentification** — saisie du numéro de téléphone + vérification de son
  existence côté backend.
- **Dashboard** — solde **masquable**, **5 dernières transactions** et raccourcis
  d'actions.
- **Transfert** — flux en 2 étapes : choix du destinataire (avec validation) puis
  saisie du montant sur un **pavé numérique** custom.
- **Factures** — consultation des factures impayées et **paiement en lot** via des
  **cases à cocher**.
- **Historique** — liste des transactions avec **filtres par type et par date** et
  **codes couleur**.

## Build APK

```bash
flutter build apk --release
```

APK généré dans :

```
build/app/outputs/flutter-apk/app-release.apk
```

> L'APK pointe par défaut sur `localhost:8080`. Pour le tester sur un **vrai
> téléphone**, lancez le backend et renseignez l'**IP locale** de la machine hôte
> dans `api_constants.dart` avant de builder.

## Stack technique

Flutter · Dart · `http` · `provider` · `intl` · `google_fonts` ·
`flutter_secure_storage` · `flutter_localizations`

## Structure du projet (feature-first)

```
lib/
├── core/                 # socle transverse
│   ├── constants/        # api_constants.dart (apiBaseUrl)
│   ├── network/          # ApiClient, WalletApiService, BillingApiService, ApiException
│   ├── state/            # ViewState (Loading / Loaded / Error)
│   ├── storage/          # SessionStorage (flutter_secure_storage)
│   ├── theme/            # AppTheme
│   └── utils/            # formatters
├── models/               # Wallet, Transaction, Facture
├── features/             # un dossier par domaine
│   ├── auth/             # provider + écrans (splash, auth)
│   ├── dashboard/        # solde + transactions
│   ├── transfers/        # transfert + pavé numérique
│   ├── bills/            # factures
│   └── history/          # historique
└── main.dart             # bootstrap + MultiProvider
```
