# <Projet>

Réponds en français. Méthode : plugin nabc-dev (`/nabc-dev:feature` pour toute fonctionnalité).

- Configuration : `.claude/nabc.json` (commandes, chemins).
- Architecture hexagonale : voir `docs/adr/`. Le domaine ne dépend de rien d'autre que de lui-même ; la règle est vérifiée par l'analyse statique.
- Avant de conclure qu'un changement fonctionne : lancer `<e2e_smoke>`.
- Commits conventionnels en français : `type(scope): quoi et pourquoi`.
- Spécificités du projet : <3 à 5 lignes maximum, renvoyer vers les skills du projet>.
