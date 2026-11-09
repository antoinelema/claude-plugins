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

(chemin relatif au dossier de cette skill). Le script lit `crap` dans `.claude/nabc.json`, lance la commande de chaque source (suite de tests avec couverture : compter plusieurs minutes), fusionne les rapports et écrit `.metrics/crap.json`. Sortie 2 : au moins une entrée au-dessus du seuil.

Sources :

- `clover` — rapport Clover de PHPUnit, qui calcule lui-même complexité et CRAP par méthode. Demande un pilote de couverture (PCOV).
- `crapper` — [unclebob/crapper](https://github.com/unclebob/crapper), épinglé par commit : TypeScript/JavaScript, Python, Go, Java, Rust, Clojure. Il lance lui-même la couverture (Vitest, c8, coverage.py…).

Dart/Flutter et Astro (`.astro`) ne sont pas couverts.

Rapport à Antoine :

1. La ligne de synthèse et les 10 pires entrées, telles que le script les sort.
2. Pour chaque entrée au-dessus du seuil, l'action du script :
   - **couvrir ≥ N %** : la complexité est acceptable, il manque des tests. Point d'entrée pour `nabc-dev:test-writer`.
   - **découper** : la complexité seule dépasse le seuil, aucun test ne suffira. Point d'entrée pour `nabc-dev:code-refactorer`, **après** couverture (on ne refactore jamais du code non couvert).
3. Les faux positifs probables, à signaler sans les cacher : un `match` / `switch` de table de correspondance (enum `label()`) compte une branche par bras ; une commande ou un script d'exploitation rarement testé.

Ne lance aucune correction : c'est une mesure. Une source en échec (tests rouges, outil absent) est rapportée ; sa couverture est alors fausse.
