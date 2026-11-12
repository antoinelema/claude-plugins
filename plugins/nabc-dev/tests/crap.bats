load test_helper
FIX="$BATS_TEST_DIRNAME/fixtures/crap"

setup() {
  common_setup
  mkdir -p "$REPO/app" "$REPO/resources/js/components" "$REPO/resources/js/lib"
  touch "$REPO/app/Risky.php" "$REPO/app/Half.php" \
    "$REPO/resources/js/components/RadarTab.tsx" "$REPO/resources/js/lib/format.ts"
  git -C "$REPO" add -A && git -C "$REPO" commit -qm sources
  set_cfg '.crap = {threshold: 30, sources: [
    {label: "php", format: "clover", command: "", report: "fixtures/clover.xml"},
    {label: "js", format: "crapper", command: "", report: "fixtures/crap.edn"}]}'
  mkdir -p "$REPO/fixtures"
  cp "$FIX/clover.xml" "$FIX/crap.edn" "$REPO/fixtures/"
}
teardown() { common_teardown; }

crap() { run python3 "$SCRIPTS/crap.py" --root "$REPO" "$@"; }

@test "fusionne PHP et JS, pire score en tête, sortie 2 au-dessus du seuil" {
  crap
  [ "$status" -eq 2 ]
  first="$(sed -n 4p <<<"$output")"
  [[ "$first" == *"App\\Risky::decide"* ]]
  [[ "$output" == *"6 entrées analysées sur 6, 3 au-dessus du seuil"* ]]
  [[ "$output" == *"resources.js.components.RadarTab::RadarTab"* ]]
}

@test "le chemin du conteneur est ramené au chemin du projet" {
  crap
  [[ "$output" == *"(app/Risky.php)"* ]]
  jq -e '.entries[] | select(.name == "decide") | .file == "app/Risky.php"' "$REPO/.metrics/crap.json"
}

@test "couverture Clover = part des instructions exécutées de la méthode" {
  crap
  jq -e '.entries[] | select(.name == "split") | .coverage == 75' "$REPO/.metrics/crap.json"
  jq -e '.entries[] | select(.name == "decide") | .coverage == 0' "$REPO/.metrics/crap.json"
}

@test "conseil : couvrir quand c'est atteignable, découper quand CC dépasse le seuil" {
  crap
  [[ "$(grep 'Risky::decide' <<<"$output")" == *"couvrir ≥ 50 %"* ]]
  [[ "$(grep 'Half::split' <<<"$output")" == *"découper (CC 40 > 30)"* ]]
}

@test "--changed ne garde que les fichiers modifiés, PHP comme JS" {
  echo x >>"$REPO/app/Half.php"
  echo x >>"$REPO/resources/js/lib/format.ts"
  crap --changed
  [ "$status" -eq 2 ]
  [[ "$output" == *"Half::split"* ]]
  [[ "$output" == *"resources.js.lib.format::format"* ]]
  [[ "$output" != *"Risky"* ]]
  [[ "$output" != *"RadarTab"* ]]
}

@test "--changed sans entrée au-dessus du seuil : sortie 0" {
  echo x >>"$REPO/resources/js/lib/format.ts"
  crap --changed
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 au-dessus du seuil"* ]]
}

@test "--threshold remplace le seuil de la config" {
  crap --threshold 200
  [ "$status" -eq 0 ]
}

@test "la commande de la source est lancée avant la lecture du rapport" {
  rm "$REPO/fixtures/crap.edn"
  set_cfg ".crap.sources[1].command = \"cp '$FIX/crap.edn' fixtures/\""
  crap
  [[ "$output" == *"RadarTab"* ]]
}

@test "--no-run ne lance pas les commandes" {
  set_cfg '.crap.sources[0].command = "touch lance.txt"'
  crap --no-run
  [ ! -f "$REPO/lance.txt" ]
}

@test "rapport absent : signalé, les autres sources restent analysées" {
  rm "$REPO/fixtures/clover.xml"
  crap
  [[ "$output" == *"[php] rapport absent"* ]]
  [[ "$output" == *"RadarTab"* ]]
}

@test "--config lit une config hors du projet" {
  cp "$REPO/.claude/nabc.json" "$TMP/ailleurs.json"
  set_cfg 'del(.crap)'
  crap --config "$TMP/ailleurs.json"
  [ "$status" -eq 2 ]
  [[ "$output" == *"Risky::decide"* ]]
}

@test "sans section crap : non configuré, sortie 1" {
  set_cfg 'del(.crap)'
  crap
  [ "$status" -eq 1 ]
  [[ "$output" == *"CRAP non configuré"* ]]
}

# Vitest package as in prospecto on 2026-11-12: vitest ^4.1.10 resolved to 4.1.12.
# vitest_package <provider declared: yes|no> [installed provider version]
vitest_package() {
  local deps='{vitest: "^4.1.10"}'
  [ "$1" = yes ] && deps='{vitest: "^4.1.10", "@vitest/coverage-v8": "4.1.12"}'
  jq -n "{name: \"p\", private: true, scripts: {test: \"vitest run\"}, devDependencies: $deps}" >"$REPO/package.json"
  mkdir -p "$REPO/node_modules/vitest"
  echo '{"name":"vitest","version":"4.1.12"}' >"$REPO/node_modules/vitest/package.json"
  if [ -n "${2:-}" ]; then
    mkdir -p "$REPO/node_modules/@vitest/coverage-v8"
    echo "{\"name\":\"@vitest/coverage-v8\",\"version\":\"$2\"}" >"$REPO/node_modules/@vitest/coverage-v8/package.json"
  fi
  echo '{"name":"p","lockfileVersion":3,"packages":{}}' >"$REPO/node_modules/.package-lock.json"
  set_cfg ".crap.sources[1].command = \"touch lance.txt && cp '$FIX/crap.edn' fixtures/\""
}

@test "crapper sur Vitest sans @vitest/coverage-v8 déclaré : source refusée, sortie 1, rien lancé" {
  vitest_package no
  crap
  [ "$status" -eq 1 ]
  [[ "$output" == *"[js] source refusée"* ]]
  [[ "$output" == *"Déclarer @vitest/coverage-v8@4.1.12 en devDependency"* ]]
  [[ "$output" == *"--no-package-lock"* ]]
  [ ! -f "$REPO/lance.txt" ]
  # the stale report on disk is not passed off as a fresh measure
  [[ "$output" != *"RadarTab"* ]]
  [[ "$output" == *"App\\Risky::decide"* ]]
}

@test "crapper sur Vitest, @vitest/coverage-v8 déclaré mais pas installé : refusée, npm ci" {
  vitest_package yes
  crap
  [ "$status" -eq 1 ]
  [[ "$output" == *"absent de node_modules : lancer \`npm ci\`"* ]]
  [ ! -f "$REPO/lance.txt" ]
}

@test "crapper sur Vitest, @vitest/coverage-v8 à une autre version que vitest : refusée" {
  vitest_package yes 4.0.0
  crap
  [ "$status" -eq 1 ]
  [[ "$output" == *"@vitest/coverage-v8 4.0.0 installé pour vitest 4.1.12"* ]]
  [ ! -f "$REPO/lance.txt" ]
}

@test "crapper sur Vitest, @vitest/coverage-v8 déclaré et installé à la version de vitest : lancée" {
  vitest_package yes 4.1.12
  crap
  [ "$status" -eq 2 ]
  [ -f "$REPO/lance.txt" ]
  [[ "$output" == *"RadarTab"* ]]
  [[ "$output" != *"refusée"* ]]
  [[ "$output" != *"node_modules"* ]]
}

@test "package sans Vitest : pas d'exigence sur @vitest/coverage-v8" {
  echo '{"name":"p","scripts":{"test":"jest"}}' >"$REPO/package.json"
  set_cfg ".crap.sources[1].command = \"touch lance.txt\""
  crap
  [ -f "$REPO/lance.txt" ]
  [[ "$output" != *"refusée"* ]]
}

@test "une commande de source qui modifie node_modules : avertissement et sortie 3" {
  vitest_package yes 4.1.12
  set_cfg '.crap.sources[0].command = "echo changed >> node_modules/.package-lock.json"'
  crap
  [ "$status" -eq 3 ]
  [[ "$output" == *"[php] ATTENTION : la commande a modifié node_modules"* ]]
  [[ "$output" == *"npm ci"* ]]
  [[ "$output" != *"[js] ATTENTION"* ]]
}

@test "node_modules créé par une commande de source : avertissement et sortie 3" {
  set_cfg '.crap.sources[0].command = "mkdir -p node_modules && echo {} > node_modules/.package-lock.json"'
  crap
  [ "$status" -eq 3 ]
  [[ "$output" == *"[php] ATTENTION : la commande a modifié node_modules"* ]]
}
