# Rapport technique — BadWallet (app mobile Consumer)

## Architecture feature-first

Le code est organisé par **domaine fonctionnel** plutôt que par couche technique.
`lib/core/` regroupe le **socle transverse** réutilisé partout : `network/`
(client HTTP et services d'API), `state/` (le pattern `ViewState`), `storage/`
(persistance sécurisée), `constants/` (`apiBaseUrl`), `theme/` et `utils/`.
`lib/features/` contient un dossier **autonome par fonctionnalité** — `auth`,
`dashboard`, `transfers`, `bills`, `history` — chacun avec son `provider/`
(logique + état) et ses `screens/`/`widgets/` (UI). Les modèles partagés
(`Wallet`, `Transaction`, `Facture`) vivent dans `lib/models/`. Cette séparation
rend chaque feature isolable et l'app facile à étendre.

## Gestion d'état (state management)

L'app utilise **Provider** avec un **`MultiProvider`** initialisé dans `main.dart`.
Chaque domaine possède son propre `ChangeNotifierProvider` : **AuthProvider**,
**BalanceProvider**, **TransactionsProvider**, **TransferProvider** et
**BillsProvider**. Tous suivent le même pattern **Loading / Loaded / Error** via
l'enum `ViewState { initial, loading, loaded, error }` : l'UI réagit à l'état
courant (spinner, contenu, ou message d'erreur), ce qui uniformise la gestion des
chargements et des échecs réseau sur tous les écrans.

## Couche réseau

Un **`ApiClient` unique** centralise les appels HTTP (`http`) vers le back. Deux
services métier s'appuient dessus : **`WalletApiService`** (solde, transactions,
transfert, paiement de factures sur `/api/wallets`) et **`BillingApiService`**
(factures impayées via `/api/external/factures`, relai du payment-service). Le
back renvoie deux formes : l'enveloppe **`RestResponse`** (la donnée utile est
dans `body`, extraite par `unwrapBody`) et **`PageResponse`** (listing renvoyé tel
quel). Le **`+`** des numéros de téléphone est encodé par segment de path
(`Uri.encodeComponent`) pour ne pas casser l'URL. Sur un status ≥ 400, le message
métier FR du back est extrait et relevé via **`ApiException`**, prêt à afficher en
SnackBar ou état Error.

## Authentification simulée

Pas de mot de passe : l'utilisateur **saisit son numéro de téléphone**, dont
l'**existence est vérifiée via l'API** (récupération du wallet). En cas de succès,
la session est **persistée avec `flutter_secure_storage`** (`SessionStorage`), ce
qui permet un **auto-login au splash** : au lancement, si une session est trouvée,
l'utilisateur est dirigé directement vers le dashboard, sinon vers l'écran d'auth.

## Difficultés rencontrées et solutions

1. **Double clavier sur le transfert** — l'écran de transfert ouvrait le clavier
   système en plus du pavé custom. Refonte en **flux à 2 étapes** : d'abord la
   saisie/validation du **destinataire**, puis le **montant** sur un **pavé
   numérique** maison, supprimant tout conflit de focus.
2. **Crash `LocaleDataException`** — le formatage des dates en français plantait au
   premier affichage. Résolu par `initializeDateFormatting('fr_FR')` dans `main()`
   et l'ajout de **`flutter_localizations`** (delegates + locale `fr_FR`).
3. **Lien téléphone → walletCode pour les factures** — le proxy factures attend le
   **code wallet** (`WLT-...`), pas le numéro de téléphone. On résout d'abord le
   wallet de l'utilisateur pour récupérer son `walletCode`, ensuite utilisé pour
   interroger `/api/external/factures/.../current`.
4. **URL backend selon la plateforme** — `localhost` ne pointe pas au même endroit
   selon la cible. Centralisé dans **une seule constante** `apiBaseUrl` :
   `localhost:8080` (iOS Simulator), `10.0.2.2:8080` (émulateur Android), IP locale
   de la machine hôte (device physique).
