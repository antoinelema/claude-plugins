---
name: finish
description: Livraison d'une story NABC — nettoyage, spec marquée livrée, commits vérifiés, description de PR, worktrees supprimés. La fusion reste humaine.
argument-hint: <story-id>
disable-model-invocation: true
---
Story : $ARGUMENTS

Lis `.claude/nabc.json`.

1. **Plan** : supprime `.claude/plans/<story-id>.md` (fichier temporaire).
2. **Spec** : **garde-la** (documentation vivante). Passe son statut à `livrée le <date du jour>`. Si l'implémentation a précisé un comportement, vérifie que la spec le dit.
3. **Commits** : `git log <base>..HEAD`. Vérifie :
   - messages conventionnels (`type(scope): quoi et pourquoi`) ;
   - aucun fichier temporaire, fichier généré ou artefact de test (traces, captures, état d'authentification) ;
   - secrets et données personnelles : lance `/nabc-dev:secrets-audit` — il couvre tout l'historique qui partira au push, pas seulement `<base>..HEAD` ;
   - pas de commit « wip » ou « fix tests » isolé qui mériterait d'être fusionné avec son commit d'origine : propose-le à Antoine, ne réécris pas l'historique sans accord.
4. **Description de PR** (rends-la, ne crée pas la PR sans accord) :

```markdown
## Story <id> : <titre>
<lien vers la spec>

## Scénarios
- [x] <scénario> — <test>

## Vérification
<rapport de /nabc-dev:verify>

## Points d'attention pour la relecture
- …
```

5. **Worktrees de la session** : pour chacun, vérifie qu'il est fusionné ou qu'Antoine accepte de le perdre, puis `git worktree remove <chemin>` et `git branch -D <branche>`. Ne supprime jamais un worktree avec des modifications non commitées sans le montrer d'abord.

**ARRÊT** : la relecture et la fusion sont faites par Antoine.
