# Méthode de dev — guideline générale

S'applique à tous les projets. Chaque projet précise son application dans son
`CLAUDE.md` et `.claude/nabc.json` ; en cas de conflit, le projet l'emporte.

## Langue
- Réponses et documentation en français. Code, noms et commentaires en anglais,
  sauf convention contraire du projet.

## Le réel prime sur le vert
- **Des tests verts ne prouvent pas que ça marche.** Avant de conclure, confronter
  le changement au réel : réponse d'API réelle, volume réel, parcours dans un vrai
  navigateur. Ce qui n'a pas pu être vérifié est « non vérifié », jamais « OK ».
- **Mesurer avant de décider.** Un chiffre se donne avec son échantillon, sa date et
  ce dont il dépend (un filtre, un segment). Un petit échantillon ne porte pas une
  décision engageante.
- Les fixtures de test viennent de données réelles quand elles existent, avec leur
  date de relevé.

## Refuser plutôt que deviner
- Une valeur absente ou douteuse devient « inconnu », jamais une valeur plausible :
  0 n'est pas « masqué », une date reportée n'est pas une date. Vérifier que ce qui
  sort d'une conversion est bien ce qui y est entré.
- Ce que la demande ou la spec ne tranche pas se signale au lieu d'être choisi.

## Tests
- Le backend est toujours testé. Un test vaut s'il **échouerait si le comportement
  disparaissait** — pas par le taux de couverture qu'il ajoute.
- Vérifier qu'un test passe par le chemin de code visé : un test peut rester vert
  sur un bug intact.
- Jamais de test affaibli, ignoré ou supprimé pour obtenir du vert ; jamais
  `--no-verify`.

## Changements
- Lire le code existant et suivre ses conventions avant d'écrire. Architecture
  hexagonale : le domaine ne dépend ni du framework ni de l'infrastructure.
- Changement minimal ; pas de refactoring opportuniste ni de dépendance ajoutée
  sans accord.
- Trois tentatives par problème (prévue, alternative, minimale sûre), puis arrêt
  avec le diagnostic : ce qui a été essayé, ce qui échoue, l'hypothèse.
- Opérations sur de gros volumes (migration, UPDATE, COUNT) : estimer le coût sur
  le volume réel avant de lancer.

## Décisions
- Une décision s'écrit avec la mesure qui la fonde, le verdict et **la condition
  pour la rouvrir**. Une décision tranchée ne se remesure pas sans fait nouveau.
- Un seul endroit fait foi par projet (indiqué dans son `CLAUDE.md`).

## Données et sécurité
- Minimisation : ne pas extraire ce qui ne sert pas. Aucun secret commité. Entrées
  validées côté client et serveur.

## Git
- Commits conventionnels (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`,
  `style`) : `type: quoi et pourquoi`, dans la langue du projet.
- **Jamais** de mention de Claude ni de ligne `Co-Authored-By` dans un commit ou
  une PR.
- Branches, PR et push : selon la politique du projet. Sans politique écrite,
  demander.

## Délégation
- Objectif : déléguer, avec la même qualité qu'en direct. Ce qui la garantit est
  mécanique (hooks, gate, tests d'acceptance figés), jamais une consigne seule.
- Une tâche ne se délègue que si son critère de fin est vérifiable par une machine,
  confrontation au réel comprise. Sinon, elle se fait en direct.
- Le contrat de délégation est ce que l'humain a validé (spec, tests d'acceptance) :
  l'agent est libre sur le comment, jamais sur le contrat.
- Un rapport délégué donne ses preuves : commandes lancées, résultats, ce qui n'a
  pas pu être vérifié.
- Hors délégation, le fil principal fait le travail ; un sous-agent se justifie
  pour une revue en contexte neuf ou des lots vraiment indépendants.
- On élargit ce qui est délégué sur mesure : le taux de reprise humaine.

## Ce que chaque projet doit préciser
- Commandes : gate rapide, tests, analyse statique, mode d'exécution (Sail, Docker…).
- Politique Git : solo sur la branche principale, ou branches et PR.
- Ce que « le réel » veut dire ici : données, volumes, parcours de référence.
- Où vivent les décisions et la dette connue.
- Ses 2 à 4 parcours de travail (correction, mesure, fonctionnalité…).
