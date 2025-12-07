#!/usr/bin/env bats

setup() {
  export TEST_DIR="$(mktemp -d)"
  export HOME="${TEST_DIR}"
  export PATH="${BATS_TEST_DIRNAME}/../scripts:${PATH}"
}

teardown() {
  rm -rf "${TEST_DIR}"
}

@test "shows usage with no arguments" {
  run claude-switch.sh
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "shows usage with --help" {
  run claude-switch.sh --help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "list shows no accounts when empty" {
  run claude-switch.sh list
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"No accounts saved"* ]]
}

@test "current shows none when no account active" {
  run claude-switch.sh current
  [[ "$status" -eq 0 ]]
  [[ "$output" == "(none)" ]]
}

@test "save fails without claude session" {
  run claude-switch.sh save test
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"No Claude session"* ]]
}

@test "save succeeds with claude session" {
  mkdir -p "${HOME}/.claude"
  echo "test-creds" > "${HOME}/.claude/credentials"

  run claude-switch.sh save work
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Saved current session as 'work'"* ]]
  [[ -d "${HOME}/.claude-accounts/work" ]]
  [[ -f "${HOME}/.claude-accounts/work/credentials" ]]
}

@test "list shows saved account" {
  mkdir -p "${HOME}/.claude"
  echo "test" > "${HOME}/.claude/credentials"
  claude-switch.sh save myaccount

  run claude-switch.sh list
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"myaccount"* ]]
  [[ "$output" == *"(active)"* ]]
}

@test "current shows active account after save" {
  mkdir -p "${HOME}/.claude"
  echo "test" > "${HOME}/.claude/credentials"
  claude-switch.sh save work

  run claude-switch.sh current
  [[ "$status" -eq 0 ]]
  [[ "$output" == "work" ]]
}

@test "use fails for nonexistent account" {
  run claude-switch.sh use nonexistent
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"not found"* ]]
}

@test "use switches to saved account" {
  mkdir -p "${HOME}/.claude"
  echo "work-creds" > "${HOME}/.claude/credentials"
  claude-switch.sh save work

  echo "personal-creds" > "${HOME}/.claude/credentials"
  claude-switch.sh save personal

  run claude-switch.sh use work
  [[ "$status" -eq 0 ]]
  [[ "$(cat "${HOME}/.claude/credentials")" == "work-creds" ]]
}

@test "delete removes account" {
  mkdir -p "${HOME}/.claude"
  echo "test" > "${HOME}/.claude/credentials"
  claude-switch.sh save todelete

  run claude-switch.sh delete todelete
  [[ "$status" -eq 0 ]]
  [[ ! -d "${HOME}/.claude-accounts/todelete" ]]
}

@test "delete fails for nonexistent account" {
  run claude-switch.sh delete nonexistent
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"not found"* ]]
}

@test "unknown command shows error" {
  run claude-switch.sh badcommand
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Unknown"* ]]
}
