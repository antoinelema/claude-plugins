/**
 * Règle d'architecture hexagonale pour dependency-cruiser.
 * Adapter les chemins à paths.domain de .claude/nabc.json.
 * Lancement (dans le script gate) : npx depcruise src --config .dependency-cruiser.cjs --ignore-known
 * Violations existantes : npx depcruise src --config .dependency-cruiser.cjs --output-type baseline > .dependency-cruiser-known-violations.json
 */
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    {
      name: "domain-independant",
      comment: "Le domaine définit ses propres ports ; il ne dépend ni de l'infrastructure, ni de l'application, ni du framework.",
      severity: "error",
      from: { path: "^src/domain/" },
      to: {
        path: [
          "^src/infrastructure/",
          "^src/application/",
          "^src/app/",
          "^node_modules/(next|react|react-dom)/",
        ],
      },
    },
    {
      name: "application-sans-infrastructure",
      comment: "Les cas d'usage passent par les ports du domaine. Les adaptateurs d'entrée (routes, pages) restent hors de la règle : les lister dans l'ADR du découpage des couches.",
      severity: "error",
      from: { path: "^src/application/" },
      to: { path: ["^src/infrastructure/"] },
    },
    {
      name: "pas-de-cycle",
      severity: "error",
      from: {},
      to: { circular: true },
    },
  ],
  options: {
    doNotFollow: { path: "node_modules" },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: "tsconfig.json" },
  },
};
