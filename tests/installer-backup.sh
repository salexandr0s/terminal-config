#!/usr/bin/env bash
set -euo pipefail
unset BASH_ENV ENV
export PATH=/usr/bin:/bin
shopt -s nullglob

: "${TEST_FIXTURE_PARENT:?Set a task-owned existing fixture parent}"
[ -d "$TEST_FIXTURE_PARENT" ] || exit 1
fixture=$(mktemp -d "${TEST_FIXTURE_PARENT%/}/installer-backup.XXXXXX")
trap 'status=$?; printf "Fixture retained: %s (status %s)\n" "$fixture" "$status"; exit "$status"' EXIT
export HOME="$fixture/home"
mkdir -p "$HOME"
installer=${INSTALLER_PATH:-"$(cd "$(dirname "$0")/.." && pwd)/install.sh"}

# Extract the exact function, never source or run the complete installer.
awk '
  /^link\(\) \{$/ { count++; inside=1 }
  inside { print }
  inside && /^\}$/ { inside=0; closed++ }
  END { if (count != 1 || closed != 1 || inside) exit 1 }
' "$installer" > "$fixture/link.sh"
printf 'Installer/helper SHA256:\n'
shasum -a 256 "$installer" "$fixture/link.sh"
source "$fixture/link.sh"
BACKUP_SUFFIX=.bak-20000101000000

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }

prepare() {
  src="$case_dir/source with spaces"
  dst="$case_dir/config with spaces"
  printf 'new source\n' > "$src"
  printf 'old contents\n' > "$case_dir/expected-old"
}

assert_link() {
  [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] || fail 'wrong new symlink'
}

one_backup() {
  backups=( "${dst}${BACKUP_SUFFIX}."* )
  [ "${#backups[@]}" -eq 1 ] || fail 'expected one reserved directory'
  backup_dir=${backups[0]}
  backup_item="$backup_dir/original"
  [ -d "$backup_dir" ] && [ ! -L "$backup_dir" ] || fail 'reservation is not a directory'
  [ "$(find "$backup_dir" -prune -type d -perm 700 -print)" = "$backup_dir" ] || fail 'reservation is not private'
}

regular_collision() {
  prepare
  cp "$case_dir/expected-old" "$dst"
  chmod 640 "$dst"
  printf 'prior backup\n' > "${dst}${BACKUP_SUFFIX}"
  link "$src" "$dst" > "$case_dir/output.log" 2>&1
  grep -qx 'prior backup' "${dst}${BACKUP_SUFFIX}" || fail 'pre-existing file backup changed'
  one_backup
  cmp "$case_dir/expected-old" "$backup_item"
  [ "$(find "$backup_item" -prune -perm 640 -print)" = "$backup_item" ] || fail 'old file mode changed'
  assert_link
}

directory_collision() {
  prepare
  mkdir -p "$dst/nested" "${dst}${BACKUP_SUFFIX}/sentinel"
  printf 'hidden old\n' > "$dst/.hidden"
  printf 'nested old\n' > "$dst/nested/marker"
  printf 'prior directory\n' > "${dst}${BACKUP_SUFFIX}/sentinel/keep"
  link "$src" "$dst" > "$case_dir/output.log" 2>&1
  grep -qx 'prior directory' "${dst}${BACKUP_SUFFIX}/sentinel/keep" || fail 'pre-existing directory backup changed'
  one_backup
  grep -qx 'hidden old' "$backup_item/.hidden"
  grep -qx 'nested old' "$backup_item/nested/marker"
  [ ! -e "$backup_item/$(basename "$dst")" ] || fail 'old directory was nested or merged'
  assert_link
}

symlink_case() {
  prepare
  local target="$case_dir/missing target"
  if [ "$1" = wrong ]; then
    target="$case_dir/other file"
    printf 'referenced data\n' > "$target"
  fi
  ln -s "$target" "$dst"
  link "$src" "$dst" > "$case_dir/output.log" 2>&1
  one_backup
  [ -L "$backup_item" ] && [ "$(readlink "$backup_item")" = "$target" ] || fail 'old symlink object changed'
  if [ "$1" = wrong ]; then grep -qx 'referenced data' "$target"; fi
  assert_link
}

correct_link() {
  prepare
  ln -s "$src" "$dst"
  local before
  before=$(ls -di "$dst")
  link "$src" "$dst" > "$case_dir/output.log" 2>&1
  [ "$(ls -di "$dst")" = "$before" ] || fail 'correct symlink was replaced'
  backups=( "${dst}${BACKUP_SUFFIX}"* )
  [ "${#backups[@]}" -eq 0 ] || fail 'no-op reserved a backup'
  assert_link
}

absent_destination() {
  prepare
  link "$src" "$dst" > "$case_dir/output.log" 2>&1
  backups=( "${dst}${BACKUP_SUFFIX}"* )
  [ "${#backups[@]}" -eq 0 ] || fail 'absent path reserved a backup'
  assert_link
}

repeated_suffix() {
  prepare
  printf 'first old\n' > "$dst"
  link "$src" "$dst" > "$case_dir/first.log" 2>&1
  one_backup
  local first="$backup_item"
  [ -L "$dst" ] || fail 'first replacement was not a symlink'
  rm "$dst"
  printf 'second old\n' > "$dst"
  link "$src" "$dst" > "$case_dir/second.log" 2>&1
  backups=( "${dst}${BACKUP_SUFFIX}."* )
  [ "${#backups[@]}" -eq 2 ] || fail 'same-suffix backups collided'
  grep -qx 'first old' "$first" || fail 'first backup lost'
  local second
  for backup_dir in "${backups[@]}"; do
    if [ "$backup_dir/original" != "$first" ]; then second="$backup_dir/original"; fi
  done
  grep -qx 'second old' "$second" || fail 'second backup lost'
  assert_link
}

failure_case() {
  prepare
  cp "$case_dir/expected-old" "$dst"
  printf 'prior backup\n' > "${dst}${BACKUP_SUFFIX}"
  local mode="$1" context="$2" status
  local calls="$case_dir/calls.log" output="$case_dir/output.log"
  : > "$calls"
  mkdir -m 700 "$case_dir/unrelated"
  printf 'unrelated sentinel\n' > "$case_dir/unrelated/keep"
  # Overrides exist only in this case's subshell; real commands keep the fixed PATH.
  mktemp() {
    printf 'mktemp\n' >> "$calls"
    case "$mode" in
      mktemp-nonzero) printf '%s\n' "$case_dir/nonzero-result"; return 1 ;;
      mktemp-empty) return 0 ;;
      mktemp-invalid) printf '%s\n' "$case_dir/unrelated"; return 0 ;;
      mktemp-nonprivate)
        local reserved
        reserved=$(command mktemp "$@") || return 1
        chmod 755 "$reserved"
        printf '%s\n' "$reserved"
        ;;
      *) command mktemp "$@" ;;
    esac
  }
  mv() {
    printf 'mv\n' >> "$calls"
    [ "$mode" != mv ] || return 1
    command mv "$@"
  }
  mkdir() {
    printf 'mkdir\n' >> "$calls"
    [ "$mode" != mkdir ] || return 1
    command mkdir "$@"
  }
  ln() {
    printf 'ln\n' >> "$calls"
    [ "$mode" != ln ] || return 1
    command ln "$@"
  }
  if [ "$context" = conditional ]; then
    if link "$src" "$dst" > "$output" 2>&1; then status=0; else status=$?; fi
  else
    set +e
    link "$src" "$dst" > "$output" 2>&1
    status=$?
    set -e
  fi
  [ "$status" -ne 0 ] || fail "failure not propagated: $mode/$context"
  ! grep -q '^  ln ' "$output" || fail 'false link success message'
  grep -qx 'prior backup' "${dst}${BACKUP_SUFFIX}" || fail 'prior backup changed on failure'
  grep -qx 'unrelated sentinel' "$case_dir/unrelated/keep"
  case "$mode" in
    mktemp-*)
      cmp "$case_dir/expected-old" "$dst"
      ! grep -Eq '^(mv|mkdir|ln)$' "$calls" || fail 'mutation after reservation failure'
      if [ "$mode" = mktemp-nonprivate ]; then
        backups=( "${dst}${BACKUP_SUFFIX}."* )
        [ "${#backups[@]}" -eq 1 ] && [ -d "${backups[0]}" ] || fail 'rejected reservation was not retained'
        grep -Fq "${backups[0]}" "$output" || fail 'rejected reservation diagnostic missing'
      fi
      ;;
    mv)
      cmp "$case_dir/expected-old" "$dst"
      one_backup
      [ ! -e "$backup_item" ] && [ ! -L "$backup_item" ] || fail 'move failure created backup item'
      ! grep -qx ln "$calls" || fail 'link attempted after move failure'
      grep -Fq "$backup_dir" "$output" || fail 'reservation diagnostic missing'
      ! grep -q '^  bak ' "$output" || fail 'false backup success message'
      ;;
    mkdir|ln)
      one_backup
      cmp "$case_dir/expected-old" "$backup_item"
      [ ! -e "$dst" ] && [ ! -L "$dst" ] || fail 'unexpected destination after failure'
      grep -Fq "$backup_item" "$output" || fail 'exact recovery path missing'
      if [ "$mode" = mkdir ]; then ! grep -qx ln "$calls" || fail 'link attempted after mkdir failure'; fi
      ;;
  esac
}

run_case() (
  name="$1"; shift
  case_dir="$HOME/$name"
  mkdir -p "$case_dir"
  "$@"
  printf 'ok %s\n' "$name"
)

run_case regular-file-collision regular_collision
if [ "${TEST_MODE:-all}" = collision-only ]; then exit 0; fi
run_case directory-collision directory_collision
run_case wrong-symlink symlink_case wrong
run_case broken-symlink symlink_case broken
run_case correct-link-no-op correct_link
run_case absent-destination absent_destination
run_case repeated-fixed-suffix repeated_suffix
for mode in mktemp-nonzero mktemp-empty mktemp-invalid mktemp-nonprivate mv mkdir ln; do
  for context in normal conditional; do
    run_case "$mode-$context" failure_case "$mode" "$context"
  done
done
