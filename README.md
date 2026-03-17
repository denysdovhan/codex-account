# codex-account

A small CLI utility for switching Codex auth accounts by swapping `~/.codex/auth.json`.

## Layout

- `codex-account.sh` — CLI entrypoint script.
- `accounts/` — saved auth snapshots, ignored by Git.
- `.current-account` — recorded current account, ignored by Git.

Switch backups are stored alongside saved accounts as `*-backup.auth.json`.

## Installation

```sh
git clone <repo-url> ~/.codex/.codex-account
ln -sfn ~/.codex/.codex-account/codex-account.sh ~/.local/bin/codex-account
```

## Usage

```sh
codex-account list
codex-account current
codex-account save personal
codex-account switch work
codex-account personal
```

## License

MIT © [Denys Dovhan](https://denysdovhan.com)