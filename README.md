# claude-plugins — marketplace `nabc`

Plugins Claude Code de Not a Bad Company.

| Plugin | Rôle |
|---|---|
| [`nabc-dev`](plugins/nabc-dev) | Méthode de dev : spec BDD → tests d'acceptance figés → plan → implémentation → gate déterministe → revue → livraison |

## Installation

```bash
/plugin marketplace add antoinelema/claude-plugins
/plugin install nabc-dev@nabc
```

## Développement

```bash
claude --plugin-dir ./plugins/nabc-dev          # charger sans installer
claude plugin validate ./plugins/nabc-dev --strict
claude plugin validate . --strict               # la marketplace
cd plugins/nabc-dev && bats tests/              # tests des hooks
```
