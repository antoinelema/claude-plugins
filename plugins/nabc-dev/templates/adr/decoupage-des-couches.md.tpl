# Découpage des couches et dépendances autorisées

- **Statut** : brouillon, à trancher par Antoine (questions en fin de document)
- **Date** : <AAAA-MM-JJ>
- **Vérifié par** : <règle du domaine et règle de l'application, et l'outil qui les lance : PHPStan + PHPat, ou dependency-cruiser>, donc par le hook d'analyse de fichier, la gate et la CI ; dette tolérée dans <fichier de baseline>

## Contexte

<Relevé daté : pour chaque couche, le nombre de fichiers qui dépendent de l'infrastructure ou d'un accès direct à la base, et ce qui le vérifie déjà. Mesurer, ne pas estimer.>

| Couche | Dépend de l'infrastructure ou de la base | Règle mécanique |
|---|---|---|
| <domaine> | <n / total> | <oui / non> |
| <cas d'usage> | <n / total> | <oui / non> |
| <adaptateurs d'entrée : contrôleurs, commandes, jobs…> | <n / total> | <oui / non> |

<Ce qui rend la règle difficile à écrire : cas d'usage rangés à plusieurs endroits, adaptateurs dans un dossier qui ne dit pas leur couche… Lister les fichiers qui violent la règle proposée.>

## Décision proposée

| Rôle | Où | Peut dépendre de | Ne dépend jamais de |
|---|---|---|---|
| **Domaine** : entités, règles métier, ports | <dossier> | lui-même | framework, infrastructure, application, adaptateurs |
| **Application** : orchestration d'un cas d'usage (plusieurs ports, transaction, effets) | <dossiers> | domaine | infrastructure, accès direct à la base |
| **Adaptateurs d'entrée** : traduisent une requête, une commande, un job en appel de cas d'usage | <dossiers> | application, domaine ; infrastructure seulement pour l'assemblage | logique métier |
| **Infrastructure** : implémente les ports | <dossier> | domaine, framework | application, adaptateurs |

Mise en œuvre : la règle de l'application vise l'orchestration seulement ; les violations existantes vont en baseline (aucune nouvelle ne passe, chaque correction en sort) ; aucun fichier n'est déplacé pour satisfaire la règle.

## Conséquences

<Ce que la règle bloque désormais, ce qui reste vérifié par la revue seulement, la dette en baseline et ce qu'il faudra pour la résorber.>

## Questions à trancher

1. **Où va un nouveau cas d'usage ?** Proposition : dans le domaine s'il n'applique que des règles métier sur des ports ; dans l'application s'il orchestre plusieurs ports, une transaction ou des effets.
2. **Quels dossiers sont des adaptateurs d'entrée**, donc hors de la règle de l'application ?
3. <Toute classe dont le rôle est ambigu (présentateurs, services transverses) : proposer un rangement à partir de ce dont elle dépend réellement. Une classe d'infrastructure qui ne dépend que du domaine est mal rangée.>

## Condition pour rouvrir

Si la baseline de la règle de l'application ne baisse pas en trois mois, ou si un défaut réel vient d'une dépendance que ce découpage autorise.
