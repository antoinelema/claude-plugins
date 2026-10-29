---
name: context-audit
description: Audit mensuel du contexte d'un projet — CLAUDE.md, agents et skills du projet — pour retirer chiffres, cartes du code et chemins morts.
disable-model-invocation: true
---
Parcours `CLAUDE.md` (racine et sous-dossiers), `.claude/agents/`, `.claude/skills/` et `.claude/rules/` du projet.

Signale, avec `fichier:ligne` :

- **Chiffres qui vieillissent** : nombre de fichiers, de tests, de lignes, pourcentages de couverture, versions qui ne sont pas lues depuis un manifeste.
- **Cartes du code** : arborescences détaillées, listes de fichiers ou de classes. Les agents explorent ; une règle durable pointe vers un ADR.
- **Chemins morts** : tout chemin, commande, script ou nom de classe cité qui n'existe plus (vérifie chacun).
- **Doublons** : règle déjà garantie par un hook nabc-dev (`--no-verify`, branches protégées, tests d'acceptance figés, gate) ou déjà écrite dans un ADR.
- **Contradictions** entre fichiers, ou avec `.claude/nabc.json`.

Pour chaque constat, propose une correction : suppression, renvoi vers un ADR ou vers `nabc.json`, ou reformulation sans chiffre. Présente le tout et **n'applique qu'après accord d'Antoine**.

Termine par la taille du `CLAUDE.md` avant / après proposée.
