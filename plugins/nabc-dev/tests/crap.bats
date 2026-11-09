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
