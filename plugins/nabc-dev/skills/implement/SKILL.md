---
name: implement
description: Étape 4 isolée — implémenter une story selon son plan, jusqu'à ce que les tests d'acceptance passent.
argument-hint: <story-id>
disable-model-invocation: true
---
Story : $ARGUMENTS

Lis `.claude/nabc.json`. Vérifie que le plan `.claude/plans/<story-id>.md` existe ; sinon, propose `/nabc-dev:plan`.

Délègue au sous-agent `nabc-dev:code-implementer` (outil Agent) avec le chemin du plan, de la spec et des tests d'acceptance.

Rapporte son résumé. S'il s'est arrêté (« Intervention manuelle requise », test d'acceptance jugé faux), présente le diagnostic à Antoine sans tenter de contourner.

Étape suivante : `/nabc-dev:verify`.
