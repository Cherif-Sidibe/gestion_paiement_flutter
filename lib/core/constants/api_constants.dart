/// Adresse du back BadWallet. Une seule constante a changer selon la cible.
///
/// iOS Simulator : localhost atteint le Mac hote -> 'http://localhost:8080'.
/// Emulateur Android : utiliser 'http://10.0.2.2:8080'.
/// Device physique : utiliser l'IP du Mac sur le reseau local, ex 'http://192.168.1.10:8080'.
const String apiBaseUrl = 'http://localhost:8080';

/// Prefixes des ressources exposees par le back.
const String walletsPath = '/api/wallets';
const String externalFacturesPath = '/api/external/factures';
