---
name: verify
description: Vérification complète d'un changement — gate, mutation sur le domaine touché, parcours E2E de référence, puis passage dans un vrai navigateur. « Green is not working. »
disable-model-invocation: true
---
**Green is not working.** Des tests verts ne prouvent pas que le produit marche : cette skill finit toujours par un passage dans un vrai navigateur.

Lis `.claude/nabc.json`. Exécute dans l'ordre, sans en sauter ; une commande absente de la config est notée « non configurée », pas inventée.

1. **Gate** — `commands.gate`. Rouge : arrête-toi, rapporte la sortie ; la vérification reprend après correction.
2. **Mutation** — `commands.mutation`, restreinte si l'outil le permet aux fichiers de `paths.domain` et `paths.application` modifiés depuis la base (`git diff --name-only <base>...HEAD`). Rapporte le score et les mutants survivants les plus significatifs (ce qu'ils révèlent : test manquant ou assertion trop faible).
2 bis. **CRAP** — si `crap.sources` est configuré : `python3 ../../scripts/crap.py --changed <base>` (chemin relatif au dossier de cette skill). Une méthode modifiée au-dessus du seuil est un constat, avec l'action indiquée (couvrir ou découper). Sortie 3 (`node_modules` modifié par la mesure) : arrête-toi, lance `npm ci`, puis reprends la vérification depuis la gate — ce qui a tourné sur ces dépendances ne vaut rien.
3. **Parcours de référence** — `commands.e2e_smoke`. Ne le lance jamais en même temps qu'une autre suite qui utilise la même base de données. S'il est rouge, c'est prioritaire sur tout le reste.
4. **Navigateur** — ouvre l'application dans un vrai navigateur (Claude in Chrome, chrome-devtools ou Playwright en mode visible) et suis le parcours utilisateur concerné par le changement, comme un utilisateur :
   - pas de rechargement ni de `goto` après la connexion ;
   - chaque formulaire aboutit à un résultat visible (redirection, message, erreur) ;
   - console du navigateur sans erreur ; requêtes réseau sans 4xx/5xx inattendu.
   Si l'application ne peut pas être lancée ou le navigateur n'est pas disponible, dis-le : c'est « non vérifié », pas « OK ».
5. **Rapport** :

```
Gate            : vert | rouge
Mutation        : <score> | non configurée — survivants notables : …
CRAP            : <n> méthodes modifiées au-dessus du seuil | aucune | non configuré
Parcours E2E    : vert | rouge | non configuré
Navigateur      : <parcours suivi> — OK | constats : …
Non vérifié     : <ce qui n'a pas pu l'être, et pourquoi>
```
