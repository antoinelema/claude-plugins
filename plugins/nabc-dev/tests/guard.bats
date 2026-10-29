load test_helper
setup() { common_setup; }
teardown() { common_teardown; }

@test "bloque git commit --no-verify et indique de corriger la cause" {
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input 'git commit --no-verify -m wip')"
  [ "$status" -eq 0 ]
  is_denied
  [[ "$output" == *"Corrige la cause"* ]]
}

@test "bloque git commit -n (alias de --no-verify)" {
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input 'git commit -nm wip')"
  is_denied
}

@test "laisse passer un commit normal" {
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input 'git commit -m "feat: x"')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "bloque git push depuis la branche protégée courante" {
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input 'git push')"
  is_denied
}

@test "bloque git push explicite vers une branche protégée" {
  git -C "$REPO" checkout -qb feat-x
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input 'git push origin feat-x:production')"
  is_denied
}

@test "bloque git -C dir push depuis main" {
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input "git -C $REPO push origin")"
  is_denied
}

@test "autorise le push d'une branche de travail" {
  git -C "$REPO" checkout -qb feat-x
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input 'git push -u origin feat-x')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "bloque une commande listée dans blocked_commands" {
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input 'netlify deploy --prod --dir dist')"
  is_denied
}

@test "l'implémenteur ne touche pas aux tests d'acceptance" {
  run bash "$SCRIPTS/guard.sh" <<<"$(edit_input nabc-dev:code-implementer tests/Acceptance/Story153Test.php)"
  is_denied
}

@test "le refactoreur ne touche pas aux tests d'acceptance" {
  run bash "$SCRIPTS/guard.sh" <<<"$(edit_input nabc-dev:code-refactorer tests/Acceptance/Story153Test.php)"
  is_denied
}

@test "l'implémenteur peut modifier le domaine" {
  run bash "$SCRIPTS/guard.sh" <<<"$(edit_input nabc-dev:code-implementer app/__Domain__/Post/Post.php)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "le test-writer ne modifie pas le code de production" {
  run bash "$SCRIPTS/guard.sh" <<<"$(edit_input nabc-dev:test-writer app/__Domain__/Post/Post.php)"
  is_denied
}

@test "le test-writer écrit dans les tests d'acceptance" {
  run bash "$SCRIPTS/guard.sh" <<<"$(edit_input nabc-dev:test-writer tests/Acceptance/Story153Test.php)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "la session principale ne modifie pas les tests d'acceptance" {
  run bash "$SCRIPTS/guard.sh" <<<"$(edit_input '' tests/Acceptance/Story153Test.php)"
  is_denied
  [[ "$output" == *"NABC_ALLOW_ACCEPTANCE_EDIT=1"* ]]
}

@test "la session principale modifie les tests d'acceptance avec l'accord explicite" {
  NABC_ALLOW_ACCEPTANCE_EDIT=1 run bash "$SCRIPTS/guard.sh" <<<"$(edit_input '' tests/Acceptance/Story153Test.php)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "l'accord explicite ne lève pas la restriction de l'implémenteur" {
  NABC_ALLOW_ACCEPTANCE_EDIT=1 run bash "$SCRIPTS/guard.sh" <<<"$(edit_input nabc-dev:code-implementer tests/Acceptance/Story153Test.php)"
  is_denied
}

@test "la session principale reste libre hors des tests d'acceptance" {
  run bash "$SCRIPTS/guard.sh" <<<"$(edit_input '' app/__Domain__/Post/Post.php)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "payload réel : la session principale, sans clé agent_type, est bloquée" {
  run bash "$SCRIPTS/guard.sh" <<<"$(real_payload pretooluse-write-main-thread)"
  is_denied
}

@test "payload réel : l'implémenteur est bloqué sur les tests d'acceptance" {
  run bash "$SCRIPTS/guard.sh" <<<"$(real_payload pretooluse-write-code-implementer)"
  is_denied
}

@test "payload réel : le test-writer est bloqué sur le code de production" {
  run bash "$SCRIPTS/guard.sh" <<<"$(real_payload pretooluse-write-test-writer)"
  is_denied
}

@test "config illisible : l'action est bloquée (fail closed)" {
  echo '{ invalide' >"$REPO/.claude/nabc.json"
  run bash "$SCRIPTS/guard.sh" <<<"$(bash_input 'ls')"
  [ "$status" -eq 2 ]
}
