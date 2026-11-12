---
name: crap
description: Score CRAP (complexité × manque de couverture) par méthode, pire en tête — tout le projet ou seulement les fichiers modifiés. Dit pour chaque méthode s'il faut la couvrir ou la découper.
argument-hint: [--changed [base]] [--threshold N] [--no-run]
disable-model-invocation: true
---
Arguments : $ARGUMENTS

`CRAP = CC² × (1 − couverture)³ + CC`. Une méthode complexe et peu testée est celle où un changement casse quelque chose sans qu'un test le voie. Repères : < 5 sain, 5–30 à regarder, > 30 à traiter.

Lance, depuis la racine du projet :

```bash
python3 ../../scripts/crap.py $ARGUMENTS
```

(chemin relatif au dossier de cette skill). Le script lit `crap` dans `.claude/nabc.json`, lance la commande de chaque source (suite de tests avec couverture : compter plusieurs minutes), fusionne les rapports et écrit `.metrics/crap.json`. Sorties : 0 sous le seuil ; 2 au moins une entrée au-dessus ; 1 erreur de configuration, source refusée comprise ; 3 une commande de source a modifié `node_modules`.

Sources :

- `clover` — rapport Clover de PHPUnit, qui calcule lui-même complexité et CRAP par méthode. Demande un pilote de couverture (PCOV).
- `crapper` — [unclebob/crapper](https://github.com/unclebob/crapper), épinglé par commit : TypeScript/JavaScript, Python, Go, Java, Rust, Clojure. Il lance lui-même la couverture (Vitest, c8, coverage.py…).

Dart/Flutter et Astro (`.astro`) ne sont pas couverts.

Prérequis Vitest : `@vitest/coverage-v8` déclaré dans `package.json` (devDependency) **à la version exacte de Vitest installée**, et installé (`npm ci`). Sans lui, crapper l'installe lui-même par `npm install --no-save --no-package-lock`, qui re-résout tout `node_modules` hors du verrou sans rien laisser dans `git status` (138 paquets montés de version le 2026-11-10 dans prospecto) : gate, build et E2E tournent ensuite sur d'autres dépendances que la CI et la production. Le script refuse donc la source tant que le paquet manque ou n'a pas la version de Vitest (sortie 1, message qui dit quoi déclarer). Quand Vitest change de version, monter `@vitest/coverage-v8` à la même.

Garde-fou : l'empreinte de `node_modules/.package-lock.json` est comparée avant et après chaque commande de source. Si elle a changé, le script l'écrit (`ATTENTION : la commande a modifié node_modules`) et sort en 3, quel que soit le score. Dans ce cas, le dire à Antoine en tête du rapport et lancer `npm ci` avant toute gate, build ou E2E : une vérification sur ces dépendances ne vaut rien.

Rapport à Antoine :

1. La ligne de synthèse et les 10 pires entrées, telles que le script les sort.
2. Pour chaque entrée au-dessus du seuil, l'action du script :
   - **couvrir ≥ N %** : la complexité est acceptable, il manque des tests. Point d'entrée pour `nabc-dev:test-writer`.
   - **découper** : la complexité seule dépasse le seuil, aucun test ne suffira. Point d'entrée pour `nabc-dev:code-refactorer`, **après** couverture (on ne refactore jamais du code non couvert).
3. Les faux positifs probables, à signaler sans les cacher : un `match` / `switch` de table de correspondance (enum `label()`) compte une branche par bras ; une commande ou un script d'exploitation rarement testé.

Ne lance aucune correction : c'est une mesure. Une source en échec (tests rouges, outil absent) ou refusée est rapportée ; sa couverture est alors fausse ou absente.
