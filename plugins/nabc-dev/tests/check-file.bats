load test_helper
setup() {
  common_setup
  mkdir -p "$REPO/app"
  echo '<?php' >"$REPO/app/A.php"
  echo 'x' >"$REPO/README.md"
}
teardown() { common_teardown; }

file_input() { jq -nc --arg cwd "$REPO" --arg f "$REPO/$1" '{cwd:$cwd,session_id:"t",tool_name:"Edit",tool_input:{file_path:$f}}'; }

@test "analyse en échec : sortie renvoyée à Claude (exit 2)" {
  set_cfg '.commands.check_file = "echo erreur-dans {file}; exit 1"'
  run bash "$SCRIPTS/check-file.sh" <<<"$(file_input app/A.php)"
  [ "$status" -eq 2 ]
  [[ "$output" == *"app/A.php"* ]]
  [[ "$output" == *"erreur-dans $REPO/app/A.php"* ]]
}

@test "analyse verte : exit 0" {
  set_cfg '.commands.check_file = "test -f {file}"'
  run bash "$SCRIPTS/check-file.sh" <<<"$(file_input app/A.php)"
  [ "$status" -eq 0 ]
}

@test "fichier hors check_file_glob : ignoré" {
  set_cfg '.commands.check_file = "exit 1"'
  run bash "$SCRIPTS/check-file.sh" <<<"$(file_input README.md)"
  [ "$status" -eq 0 ]
}

@test "sans commande check_file : ne fait rien" {
  run bash "$SCRIPTS/check-file.sh" <<<"$(file_input app/A.php)"
  [ "$status" -eq 0 ]
}

@test "check_files : chaque analyse correspondant au fichier est lancée" {
  echo 'x' >"$REPO/app/B.tsx"
  set_cfg '.commands.check_files = [
    {glob: "\\.tsx$", command: "echo lint-front {file}; exit 1"},
    {glob: "\\.php$", command: "echo jamais; exit 1"},
    {glob: "\\.(tsx|ts)$", command: "echo types-front; exit 1"}]'
  run bash "$SCRIPTS/check-file.sh" <<<"$(file_input app/B.tsx)"
  [ "$status" -eq 2 ]
  [[ "$output" == *"lint-front $REPO/app/B.tsx"* ]]
  [[ "$output" == *"types-front"* ]]
  [[ "$output" != *"jamais"* ]]
}

@test "check_files et check_file historique se cumulent" {
  set_cfg '.commands.check_file = "echo historique; exit 1" | .commands.check_files = [{glob: "\\.php$", command: "echo nouvelle; exit 1"}]'
  run bash "$SCRIPTS/check-file.sh" <<<"$(file_input app/A.php)"
  [ "$status" -eq 2 ]
  [[ "$output" == *"historique"* ]]
  [[ "$output" == *"nouvelle"* ]]
}

@test "{relfile} : chemin depuis la racine du projet (outil en conteneur)" {
  set_cfg '.commands.check_files = [{glob: "\\.php$", command: "echo dans-le-conteneur {relfile}; exit 1"}]'
  run bash "$SCRIPTS/check-file.sh" <<<"$(file_input app/A.php)"
  [ "$status" -eq 2 ]
  [[ "$output" == *"dans-le-conteneur app/A.php"* ]]
}

@test "check_files tous verts : exit 0" {
  set_cfg '.commands.check_files = [{glob: "\\.php$", command: "test -f {file}"}]'
  run bash "$SCRIPTS/check-file.sh" <<<"$(file_input app/A.php)"
  [ "$status" -eq 0 ]
}
