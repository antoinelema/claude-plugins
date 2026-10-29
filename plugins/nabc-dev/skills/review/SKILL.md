---
name: review
description: Étape 6 isolée — revue du diff contre la spec par un agent en contexte neuf.
argument-hint: <chemin de la spec> [base du diff]
disable-model-invocation: true
---
Arguments : $ARGUMENTS

Base du diff : celle donnée en argument, sinon `git merge-base HEAD <branche principale>` (la première branche de `git.protected_branches` dans `.claude/nabc.json`).

Délègue au sous-agent `nabc-dev:code-reviewer` (outil Agent) avec **uniquement** le chemin de la spec et la base du diff. Ne lui transmets ni résumé de l'implémentation, ni contexte de la conversation : la revue doit juger le résultat, pas les intentions.

Rapporte le verdict et les constats tels quels. Si `À CORRIGER` : proposer `nabc-dev:code-refactorer` sur les constats bloquants et importants, puis `/nabc-dev:verify`.
