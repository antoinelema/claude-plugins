---
name: acceptance
description: Étape 2 isolée — écrire ou modifier les tests d'acceptance d'une spec validée. Seule voie autorisée pour modifier un test d'acceptance.
argument-hint: <chemin de la spec>
disable-model-invocation: true
---
Spec : $ARGUMENTS

Les tests d'acceptance encodent la spec validée. Cette skill est **la seule voie** pour les créer ou les modifier.

1. Lis `.claude/nabc.json` et la spec. Si son statut n'est pas « validée », arrête-toi : la spec passe d'abord par `/nabc-dev:spec`.
2. S'il s'agit de **modifier** des tests existants : vérifie qu'Antoine a décidé de changer la spec (la spec a été modifiée et revalidée). Sinon, arrête-toi et demande-lui.
3. Délègue au sous-agent `nabc-dev:test-writer` (outil Agent) avec le chemin de la spec.
4. Contrôle son résumé : un test par scénario, chacun rouge pour la bonne raison (comportement absent). Renvoie-lui tout écart.

Arrête-toi là. Étape suivante : `/nabc-dev:plan <chemin de la spec>`.
