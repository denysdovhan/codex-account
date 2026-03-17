#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

PROGRAM="${0##*/}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
AUTH_FILE="${AUTH_FILE:-$CODEX_HOME/auth.json}"
CODEX_ACCOUNT_DIR="${CODEX_ACCOUNT_DIR:-$CODEX_HOME/.codex-account}"
ACCOUNTS_HOME="${CODEX_ACCOUNTS_HOME:-$CODEX_ACCOUNT_DIR/accounts}"
BACKUPS_HOME="${CODEX_BACKUPS_HOME:-$ACCOUNTS_HOME}"
STATE_FILE="${CODEX_CURRENT_ACCOUNT_FILE:-$CODEX_ACCOUNT_DIR/.current-account}"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

note() {
  printf '%s\n' "$*"
}

usage() {
  cat <<EOF
$PROGRAM - switch saved Codex auth accounts

Usage:
  $PROGRAM <account>
  $PROGRAM list
  $PROGRAM current
  $PROGRAM save <account>
  $PROGRAM switch <account>
  $PROGRAM help

Commands:
  list
      List saved auth accounts from $ACCOUNTS_HOME.

  current
      Show the active account when it can be detected.

  save <account>
      Save the current $AUTH_FILE as <account>.auth.json and mark it as current.

  switch <account>
      Back up the current auth to $BACKUPS_HOME/<account>-backup.auth.json,
      then replace $AUTH_FILE with <account>.auth.json.

Notes:
  - This tool only swaps auth.json. It does not touch the rest of ~/.codex.
  - Saved accounts live in ~/.codex/.codex-account/accounts.
  - Named backups live alongside saved accounts as *-backup.auth.json files.
  - To add a new account, log into it with Codex first, then run:
      $PROGRAM save <account>
  - Running '$PROGRAM <account>' is shorthand for '$PROGRAM switch <account>'.
  - After switching, restart Codex if it is already running.
EOF
}

ensure_dirs() {
  mkdir -p "$CODEX_HOME" "$CODEX_ACCOUNT_DIR" "$ACCOUNTS_HOME"
  chmod 700 "$CODEX_ACCOUNT_DIR" 2>/dev/null || true
  chmod 700 "$ACCOUNTS_HOME" 2>/dev/null || true
}

ensure_storage() {
  ensure_dirs
}

require_auth_file() {
  [[ -f "$AUTH_FILE" ]] || die "No auth file found at $AUTH_FILE. Run 'codex login' first."
}

validate_account_name() {
  local account="$1"

  if [[ ! "$account" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    die "Invalid account name '$account'. Use letters, numbers, dots, dashes, or underscores."
  fi

  if [[ "$account" == *-backup ]]; then
    die "Account names cannot end with '-backup'."
  fi
}

account_path() {
  local account="$1"
  printf '%s/%s.auth.json\n' "$ACCOUNTS_HOME" "$account"
}

backup_path() {
  local account="$1"
  printf '%s/%s-backup.auth.json\n' "$BACKUPS_HOME" "$account"
}

set_current_account() {
  local account="$1"

  printf '%s\n' "$account" > "$STATE_FILE"
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}

get_recorded_account() {
  [[ -f "$STATE_FILE" ]] || return 1

  local account=''
  IFS= read -r account < "$STATE_FILE" || true
  [[ -n "$account" ]] || return 1

  printf '%s\n' "$account"
}

match_live_account() {
  [[ -f "$AUTH_FILE" ]] || return 1

  local file account

  for file in "$ACCOUNTS_HOME"/*.auth.json; do
    [[ -f "$file" ]] || continue
    [[ "$file" == *-backup.auth.json ]] && continue

    if cmp -s "$AUTH_FILE" "$file"; then
      account="${file##*/}"
      account="${account%.auth.json}"
      printf '%s\n' "$account"
      return 0
    fi
  done

  return 1
}

copy_auth_to() {
  local destination="$1"

  cp "$AUTH_FILE" "$destination"
  chmod 600 "$destination" 2>/dev/null || true
}

save_current_auth() {
  local account="$1"

  require_auth_file
  copy_auth_to "$(account_path "$account")"
}

restore_account_auth() {
  local account="$1"
  local source tmp_file

  source="$(account_path "$account")"
  [[ -f "$source" ]] || die "Unknown account '$account'. Run '$PROGRAM list' to see saved accounts."

  tmp_file="$(mktemp "${AUTH_FILE}.tmp.XXXXXX")"
  cp "$source" "$tmp_file"
  chmod 600 "$tmp_file" 2>/dev/null || true
  mv "$tmp_file" "$AUTH_FILE"
}

command_list() {
  ensure_storage

  local matched_current recorded_current file account prefix found=0
  matched_current="$(match_live_account || true)"
  recorded_current="$(get_recorded_account || true)"

  for file in "$ACCOUNTS_HOME"/*.auth.json; do
    [[ -f "$file" ]] || continue
    [[ "$file" == *-backup.auth.json ]] && continue
    found=1
    account="${file##*/}"
    account="${account%.auth.json}"
    prefix=' '

    if [[ "$account" == "$matched_current" ]]; then
      prefix='*'
    elif [[ -z "$matched_current" && "$account" == "$recorded_current" ]]; then
      prefix='~'
    fi

    printf '%s %s\n' "$prefix" "$account"
  done

  if [[ "$found" -eq 0 ]]; then
    note 'No saved Codex accounts.'
    return 0
  fi

  if [[ -z "$matched_current" && -n "$recorded_current" ]]; then
    note ''
    note "~ recorded current account (live auth differs from saved snapshot)"
  fi
}

command_current() {
  ensure_storage

  local matched_current recorded_current

  if [[ ! -f "$AUTH_FILE" ]]; then
    note "No active Codex auth file at $AUTH_FILE."
    return 0
  fi

  matched_current="$(match_live_account || true)"
  recorded_current="$(get_recorded_account || true)"

  if [[ -n "$matched_current" ]]; then
    note "$matched_current"
    return 0
  fi

  if [[ -n "$recorded_current" ]]; then
    note "$recorded_current (recorded, live auth differs from saved snapshot)"
    return 0
  fi

  note 'Current auth is not linked to a saved account.'
}

command_save() {
  local account="${1:-}"
  [[ -n "$account" ]] || die "Usage: $PROGRAM save <account>"

  validate_account_name "$account"
  ensure_storage
  save_current_auth "$account"
  set_current_account "$account"

  note "Saved current auth as '$account'."
}

command_switch() {
  local target="${1:-}"
  [[ -n "$target" ]] || die "Usage: $PROGRAM switch <account>"

  validate_account_name "$target"
  ensure_storage

  local target_file matched_current recorded_current backup_account backup_file
  target_file="$(account_path "$target")"
  [[ -f "$target_file" ]] || die "Unknown account '$target'. Run '$PROGRAM save $target' after logging into it."

  matched_current="$(match_live_account || true)"
  recorded_current="$(get_recorded_account || true)"

  if [[ "$matched_current" == "$target" ]]; then
    set_current_account "$target"
    note "Account '$target' is already active."
    return 0
  fi

  backup_account="${matched_current:-$recorded_current}"
  backup_file="$(backup_path "$backup_account")"

  if [[ -f "$AUTH_FILE" ]]; then
    if [[ -n "$backup_account" ]]; then
      copy_auth_to "$backup_file"
      note "Backed up current auth to '$backup_file'."
    else
      note 'Current auth is not linked to a saved account, skipping named backup.'
    fi
  fi

  restore_account_auth "$target"
  set_current_account "$target"

  note "Switched to '$target'."
  note "Restart Codex if it is already running."
}

main() {
  local command="${1:-help}"
  shift || true

  case "$command" in
    list)
      command_list "$@"
      ;;
    current)
      command_current "$@"
      ;;
    save)
      command_save "$@"
      ;;
    switch)
      command_switch "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      if [[ "$#" -eq 0 ]]; then
        validate_account_name "$command"
        ensure_storage

        if [[ -f "$(account_path "$command")" ]]; then
          command_switch "$command"
          return 0
        fi

        printf "Unknown account '%s'.\n\n" "$command" >&2
        usage >&2
        exit 1
      fi

      die "Unknown command '$command'. See '$PROGRAM help'."
      ;;
  esac
}

main "$@"
