---
name: parallel
description: Découper un chantier en lots indépendants confiés à des agents en parallèle, un worktree par agent, avec validation humaine avant chaque fusion.
argument-hint: <chantier>
disable-model-invocation: true
---
Chantier : $ARGUMENTS

Lis `.claude/nabc.json`.

## 1. Découpage (à valider par Antoine avant de lancer quoi que ce soit)

- **Phase séquentielle d'abord** : tout ce que plusieurs lots partagent (schéma de base, ports du domaine, fixtures et helpers de test communs). Elle est faite, gate verte et commitée sur la branche principale avant le lancement des lots.
- **Lots parallèles** : chaque lot a un périmètre de fichiers **disjoint** des autres. Deux lots qui touchent le même fichier ne sont pas indépendants : fusionne-les ou séquence-les.
- Présente le tableau : lot → périmètre → fichiers autorisés → critère de fin. **ARRÊT : validation d'Antoine.**

## 2. Lancement

Un agent par lot, chacun dans son worktree (outil Agent avec `isolation: "worktree"`), tous dans un même message pour qu'ils tournent en parallèle. Si `worktree.db_per_worktree` est activé, chaque worktree a sa propre base de test (exportée par le hook de session) ; sinon, les lots qui utilisent la base passent l'un après l'autre.

Brief imposé pour chaque agent :

```
Objectif : <une phrase>

Périmètre
- Fichiers autorisés : <liste>
- Interdit : tout autre fichier, les tests d'acceptance, la configuration partagée.

Règles
- Lis la version actuelle de chaque fichier sur la branche principale avant de le modifier ; sois additif, ne réécris pas.
- Jamais --no-verify, jamais de test affaibli ou désactivé.
- Trois tentatives par problème, puis « Intervention manuelle requise » avec le diagnostic.

Critère de fin
- <critère vérifiable>
- `<commands.gate>` vert dans le worktree.

Rapport (court)
- Fichiers modifiés, résultat de la gate, ce qui n'a pas pu être fait et pourquoi.
```

## 3. Fusion

Lot par lot : présente le diff et le rapport à Antoine. **Validation humaine avant chaque fusion.** Après chaque fusion, gate verte sur la branche principale avant de passer au lot suivant. Vérifie `git status` : pas de fichiers parasites laissés par les worktrees.

Nettoyage final : `git worktree remove` et `git branch -D` pour chaque lot fusionné.
