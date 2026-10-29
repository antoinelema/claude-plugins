---
name: plan
description: Étape 3 isolée — plan d'implémentation minimal à partir d'une spec validée et de ses tests d'acceptance rouges.
argument-hint: <chemin de la spec>
disable-model-invocation: true
---
Spec : $ARGUMENTS

Lis `.claude/nabc.json`. Vérifie que la spec est « validée » et que ses tests d'acceptance existent ; sinon, indique l'étape manquante et arrête-toi.

Délègue au sous-agent `nabc-dev:implementation-planner` (outil Agent) avec le chemin de la spec et des tests d'acceptance.

Présente le plan à Antoine. S'il contient des « Questions de spec », pose-les : la réponse peut demander de revenir à `/nabc-dev:spec`.

Arrête-toi là. Étape suivante : `/nabc-dev:implement <story-id>`.
