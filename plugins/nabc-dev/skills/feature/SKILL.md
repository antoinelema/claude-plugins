---
name: feature
description: Chaîne complète d'une fonctionnalité NABC, de la spec à la PR, avec arrêts de validation humaine.
argument-hint: <description de la fonctionnalité | identifiant de story>
disable-model-invocation: true
---
Fonctionnalité demandée : $ARGUMENTS

Lis d'abord `.claude/nabc.json`. S'il n'existe pas, arrête-toi et propose `/nabc-dev:init`.

Chaque étape est déléguée à un sous-agent du plugin (outil Agent, `subagent_type` indiqué). Un sous-agent ne peut pas dialoguer : quand il rend des questions, c'est toi qui les poses à Antoine, puis tu relances **le même agent** avec les réponses (SendMessage vers cet agent ; à défaut, nouvel appel avec la spec en cours et les réponses). Passe à chaque agent les chemins dont il a besoin, explicitement.

1. **Spec** — `nabc-dev:spec-analyst`, avec le besoin et le chemin absolu du template `../../templates/spec.md.tpl` (relatif au dossier de cette skill).
   Relaie ses questions, puis présente la spec. **ARRÊT : validation explicite d'Antoine.** Relance l'agent pour qu'il passe le statut à « validée ».
2. **Tests d'acceptance** — `nabc-dev:test-writer`, avec le chemin de la spec.
   Vérifie dans son résumé que chaque scénario a un test, et que chaque test est rouge **pour la bonne raison**. Sinon, renvoie-lui le problème.
3. **Plan** — `nabc-dev:implementation-planner`, avec la spec et les tests.
   **ARRÊT si le plan contient des « Questions de spec »** : pose-les à Antoine ; si la réponse change la spec, retour à l'étape 1.
4. **Implémentation** — `nabc-dev:code-implementer`, avec le plan.
   S'il s'arrête sur « Intervention manuelle requise » ou sur un test d'acceptance qu'il juge faux : ARRÊT, présente son diagnostic à Antoine.
5. **Vérification** — exécute la skill `/nabc-dev:verify` toi-même.
6. **Revue** — `nabc-dev:code-reviewer`, **uniquement** avec le chemin de la spec et la base du diff (`git merge-base HEAD <branche principale>`). Ne lui transmets aucun résumé de l'implémentation.
7. **Corrections** — si `À CORRIGER` : `nabc-dev:code-refactorer` avec les constats bloquants et importants, puis retour à l'étape 5. Au troisième aller-retour sans `CONFORME` : ARRÊT, intervention manuelle.
8. **Fin** — exécute la skill `/nabc-dev:finish`. **ARRÊT : la fusion est faite par Antoine.**

Ne saute aucune étape. Si la réalité contredit la spec (code existant, contrainte technique, test impossible à écrire), arrête-toi et demande à Antoine lequel des deux a raison.

À chaque arrêt, résume en quelques lignes : étape atteinte, ce qui est fait, ce qui est attendu d'Antoine.
