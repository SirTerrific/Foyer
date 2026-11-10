# Foyer — changements vs Arc Launcher

### Contrôle parental (nouveau)
- **Code D-pad** : combinaison de flèches (haut/bas/gauche/droite) et chiffres, validée par OK. 4 symboles minimum. Compatible télécommande, comme Projectivy.
- **Apps protégées au choix** : appui long sur une app pour la protéger ou non. Les apps protégées demandent le code au lancement.
- **Watch Next** : les programmes de la carte « Watch Next » sont aussi bloqués quand leur app est protégée, ou inconnue.
- **Désinstaller / Infos app** : protégés par le code.
- **Réglages protégés** : une fois un code défini, l'accès aux réglages demande le code (option désactivable).
- **Code toujours demandé** : plus de période déverrouillée. Chaque lancement d'une app protégée et chaque entrée dans les réglages demandent le code. L'icône réseau, « Infos de l'app » et « Désinstaller » le demandent aussi tant que les réglages du launcher sont protégés. Sur la version GitHub, la garde d'accessibilité le redemande si on rejoint une app protégée depuis les récentes ou une autre app ; un écran système (permission, choix de compte) par-dessus une app déverrouillée ne le redemande pas.
- **Blocage hors de Foyer** (version GitHub) : un service d'accessibilité, à activer une fois dans Paramètres > Accessibilité, demande le code même quand l'app protégée s'ouvre depuis les applis récentes, une autre app ou l'assistant vocal. Il ne lit que le nom de l'app à l'écran. Avec « Protéger les paramètres », les Paramètres Android demandent aussi le code (forcer l'arrêt, désactiver le service). Option : `adb shell pm grant com.sirterrific.foyer android.permission.WRITE_SECURE_SETTINGS` une fois, et Foyer réactive lui-même le service, y compris après un arrêt forcé.
- **Anti-force brute** : 5 erreurs, puis blocage 30 s, doublé à chaque nouvelle série, plafonné à 15 min.
- **Code de secours** : 12 flèches, affiché une fois à la création du code (ou via Contrôle parental > Nouveau code de secours). Saisi à la place d'un code oublié, il permet d'en choisir un nouveau. Usage unique, un nouveau est affiché aussitôt.
- **Plage horaire** : option pour ne protéger que sur une plage de la journée (08:00–20:00 par défaut, passe minuit).
- **Stockage** : code jamais gardé en clair (SHA-256 salé, comparaison à temps constant).
- **Langues** : textes en français, anglais, espagnol, turc, vietnamien, chinois.

### Fond d'écran Bing (nouveau)
- **Image du jour Bing** : suivie automatiquement (vérifiée toutes les heures) ou image fixée parmi les 8 dernières, avec aperçus.
- **Région** au choix (Auto, FR, CA, US, etc.), crédit photo affiché à l'écran, image gardée en cache hors ligne.

### Rebrand
- Nouveau nom **Foyer**, icône redessinée (maison, cheminée et âtre lumineux en dégradé), bannière TV et palette ambre / terracotta sur fond sombre.
- README réécrit, liens et mises à jour pointent vers ce fork (`SirTerrific/Foyer`).

### Correctifs et robustesse (audit du code)
- URI Watch Next durcies, appels natifs asynchrones, écouteurs réseau/téléphone bien libérés.
- Sauvegarde Android désactivée.
- Tri « dernières utilisées » corrigé, vidéo de fond qui ne redémarre plus en boucle.
- Cache des affiches plafonné, délais d'attente sur Reddit.
- Corrections base de données (lots et migration).
- Tick de l'horloge économisé.

### Technique
- Workflow CI (`flutter analyze` + tests), testé avec `act`.
- Wiki OpenWiki et `AGENTS.md` ajoutés.
- APK signés : universel, `arm64-v8a`, `armeabi-v7a`.
- Nouvel identifiant `com.sirterrific.foyer` : projet distinct, s'installe à côté d'Arc Launcher (données séparées).

---

# Arc Launcher (original)

### Features
* Allow users to customize the date widget format, making it possible to display the [date, time](https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html), and any arbitrary text, or to hide it completely.
* Choose what the back button does while being in the launcher: Nothing, Show a fullscreen clock, Show screensaver (a.k.a Ambient Mode).
* Show the active network status next to the date widget.
* Allow users to hide the application category titles.
* Clicking or tapping on an application card now opens it.
* Ability to disable the navigation keys sound.
* The app bar can now hide automatically while not focused.
* Map "Escape" key to the "Back" action.
* Translate to Spanish.

### Removals
* Firebase analytics and crashlytics services.
* Unsplash integration.

### Misc
* Upgrade Flutter version from 3.7.5 to 3.24.5.
* Replace Kotlin code with Java.
* Set new language versions: Java (17), Dart (greater than or equal to 3.4.3).
* Change versioning scheme to \<year>.\<month>.\<monthly release number>
