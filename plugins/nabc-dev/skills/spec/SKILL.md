---
name: spec
description: Étape 1 isolée de la méthode NABC — rédiger la spec BDD d'une fonctionnalité avec le spec-analyst.
argument-hint: <description de la fonctionnalité>
disable-model-invocation: true
---
Besoin : $ARGUMENTS

Lis `.claude/nabc.json` (sinon, propose `/nabc-dev:init`).

Délègue au sous-agent `nabc-dev:spec-analyst` (outil Agent), avec le besoin et le chemin absolu du template `../../templates/spec.md.tpl` (relatif au dossier de cette skill).

L'agent ne peut pas dialoguer : relaie ses questions à Antoine, puis relance le même agent (SendMessage) avec les réponses. Présente la spec obtenue. Après validation explicite d'Antoine, relance l'agent pour passer le statut à « validée le <date> ».

Arrête-toi là. Étape suivante : `/nabc-dev:acceptance <chemin de la spec>`.
