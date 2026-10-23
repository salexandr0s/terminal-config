# Installer backup repair

Base: `6ebb3571d771adc10c630a6c71c2c3df83b29a0f` on `main`.
Branch: `fix/security-backups-october-2026`.

The `link()` helper reserves a unique private directory beside an existing destination before moving it. Previous backups are never reused or removed. The old item is retained at `<destination>.bak-<timestamp>.<random>/original`; files, directories and symlink objects use the same recovery path. A correct symlink remains a no-op, and an absent destination needs no backup.

Reservation output must be nonempty and match the expected same-parent path. The directory must exist, belong to the current user, have mode 700 and not be a symlink. Reservation, move, directory-creation and link failures return failure explicitly, including when the helper is called from a shell conditional.

If a move fails, the reservation can remain empty for diagnosis. If the move succeeds but a later step fails, the destination can be absent while the original remains under the reported `original` path. The helper reports that exact recovery path and does not attempt destructive rollback. Before manual recovery, inspect the current destination and retained item; restore only after deciding what should occupy the destination. Keep other backups until their owner decides how to retain them.

## Verification

The helper and focused test are byte-identical to the reviewed Ghostty repair. Root extended its pre-execution approval to these exact bytes and the saved Terminal baseline helper. `bash -n` passes for the installer, focused test and extracted helper. The test extracts exactly one `link()` definition instead of sourcing the installer, uses a fixed suffix and synthetic HOME, and confines failure overrides to case subshells. A cleared environment supplies only task paths and system tools. Fixtures and diagnostics are retained.

The saved baseline collision check fails as expected: moving onto the reused timestamp path overwrites its previous file backup. All 21 candidate cases pass, covering files and directories, wrong/broken/correct symlinks, absent paths, repeated suffixes, paths with spaces and reservation/move/mkdir/link failures in normal and conditional shell contexts.

The audit workspace retains source/helper/test hashes, logs and task fixtures under `batch-2-results/terminal-config-backup-verification`. Every installer byte outside `link()` and every other tracked baseline file remains unchanged.

Run the focused check with a newly chosen task-only directory:

```sh
TEST_FIXTURE_PARENT=/absolute/task/fixture-parent bash --noprofile --norc tests/installer-backup.sh
```

The parent must exist. This runs only the extracted helper and retains its synthetic HOME. Independent exact-diff review is required before commit.

## Limits

This repair does not make concurrent destination changes atomic or protect against a hostile process with the same user ID. The fixture does not certify every filesystem, mount, ACL, extended-attribute or interruption case.

No complete installer, real shell configuration, Homebrew, Oh My Zsh, package/plugin acquisition, notifier or service operation has been run. The rolling remote bootstrap/plugin references remain a separate supply-chain review item. Assistant settings and launcher behavior are unchanged. Root owns publication after independent exact-diff review.
