# Foyer — changements vs Arc Launcher

### Contrôle parental (nouveau)
- **Code D-pad** : combinaison de flèches (haut/bas/gauche/droite) et chiffres, validée par OK. 4 symboles minimum. Compatible télécommande, comme Projectivy.
- **Apps protégées au choix** : appui long sur une app pour la protéger ou non. Les apps protégées demandent le code au lancement.
- **Watch Next** : les programmes de la carte « Watch Next » sont aussi bloqués quand leur app est protégée, ou inconnue.
- **Désinstaller / Infos app** : protégés par le code.
- **Réglages protégés** : une fois un code défini, l'accès aux réglages demande le code (option désactivable).
- **Délai de grâce** : après un bon code, 15 min sans redemander.
- **Anti-force brute** : 5 erreurs, puis blocage 30 s, doublé à chaque nouvelle série, plafonné à 15 min.
- **Plage horaire** : option pour ne protéger que sur une plage de la journée (08:00–20:00 par défaut, passe minuit).
- **Stockage** : code jamais gardé en clair (SHA-256 salé, comparaison à temps constant).
- **Langues** : textes en français, anglais, espagnol, turc, vietnamien, chinois.

### Rebrand
- Nouveau nom **Foyer**, nouvelle icône, bannière TV et palette ambre / terracotta sur fond sombre.
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
