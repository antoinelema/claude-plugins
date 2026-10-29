/**
 * Règle d'architecture hexagonale pour dependency-cruiser.
 * Adapter les chemins à paths.domain de .claude/nabc.json.
 * Lancement (dans le script gate) : npx depcruise src --config .dependency-cruiser.cjs
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
