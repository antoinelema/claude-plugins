---
name: secrets-audit
description: Audit des secrets et données sensibles avant un push — tout le dépôt et tout l'historique, pas seulement la branche. Scanner + recherche des vraies valeurs du .env + fichiers sensibles + données personnelles. Ne pousse rien.
argument-hint: "[remote/branche visée, défaut origin/<branche courante>]"
disable-model-invocation: true
---
Cible du push : $ARGUMENTS (défaut : `origin/<branche courante>`).

Un push publie **tout l'historique** qui n'est pas encore sur le remote, pas seulement le dernier état : un secret ajouté puis retiré trois commits plus loin part quand même. L'audit porte donc sur l'historique complet (`git rev-list --all`).

**Règle absolue : n'affiche jamais une valeur de secret**, ni dans la sortie d'une commande ni dans le rapport. Rapporte le nom de la variable, le fichier, le commit, et au plus les 4 premiers caractères.

1. **Périmètre** — `git rev-list --count <cible>..HEAD` (commits qui partiraient) et visibilité du dépôt (`gh repo view --json visibility`).

2. **Scanner** — gitleaks sur tout l'historique, en mode masqué. S'il n'est pas installé, par l'image officielle, dépôt monté en lecture seule et rapport dans le scratchpad :
   ```
   docker run --rm -v "$PWD:/repo:ro" -v "<scratchpad>:/out" zricethezav/gitleaks:v8.21.2 \
     git /repo --log-opts="--all" --redact --report-format json --report-path /out/gitleaks.json
   ```
   Trie chaque détection : faux positif (mot de passe de test, `YOUR_TOKEN`, exemple de doc) ou réel, en regardant le contexte (`git show <commit>:<fichier>`).

3. **Vraies valeurs** — le scanner ne connaît que des motifs. Pour chaque variable du `.env` local dont le nom contient KEY, SECRET, PASSWORD, TOKEN ou CLIENT_ID et dont la valeur fait au moins 8 caractères (hors `null`, placeholders), cherche la valeur exacte dans toutes les révisions avec `git grep -lF -- "$valeur" $(git rev-list --all)`, sans l'afficher. Une valeur retrouvée, surtout dans un `.env.example`, est une fuite réelle.

4. **Fichiers sensibles jamais commités** — `git log --all --name-only --format= | sort -u`, puis filtre : `.env*` (hors `.env.example`), `*.sql`, `*.dump`, `*.pem`, `*.key`, `*.p12`, `*.sqlite`, `id_rsa*`, `credentials*`, exports `*.csv`/`*.xlsx`. Pour chacun, vérifie le contenu (fixture de test synthétique ou vraie donnée ?).

5. **Préfixes de clés connus** dans tout l'historique (`git grep -lE`) : `sk-ant-`, `sk-`, `AIza…`, `GOCSPX-`, `AKIA…`, `ghp_`/`github_pat_`, `xkeysib-`/`xsmtpsib-`, `phc_`, `-----BEGIN … PRIVATE KEY`, plus les mots de passe codés en dur déjà connus du projet.

6. **Données personnelles** (RGPD) dans l'état courant : emails non génériques de personnes (hors domaines d'exemple et du projet), numéros de mobile (`(\+33 ?|0)[67]…`), noms associés à un téléphone ou une adresse, l'email et le téléphone d'Antoine. Un contact générique d'entreprise (`contact@…`) n'est pas une donnée personnelle ; le mobile d'un artisan en nom propre, si.

7. **Qualifier chaque fuite réelle** :
   - **déjà sur le remote** : la réécriture d'historique ne la dépublie pas (clones, caches, forks) → **rotation de la clé** chez le fournisseur ; le push n'aggrave rien ;
   - **seulement en local** : elle partira au push → la retirer avant. Si elle est dans des commits anciens, propose la réécriture (`git filter-repo`) à Antoine, ne la fais pas sans accord ;
   - **donnée personnelle dans l'état courant** : pseudonymise dans un commit `docs:`/`test:` dédié.

8. **Rapport** :

```
Périmètre       : <n> commits à pousser vers <cible>, dépôt <public|privé>
Scanner         : <n> détections — <n> faux positifs, <n> réelles
Vraies valeurs  : <VAR> → <fichier> (<commit>, <déjà sur le remote | local>) | aucune
Fichiers        : <liste> | aucun
Données perso   : <constats> | aucune
Actions         : rotation <VAR> chez <fournisseur> ; <corrections faites>
Verdict         : push sans risque supplémentaire | à corriger avant push
```

**ARRÊT** : ne pousse pas toi-même sauf si Antoine l'a demandé explicitement et que le verdict est « sans risque supplémentaire ».
