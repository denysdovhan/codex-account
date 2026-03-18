[![SWUbanner](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner-direct-single.svg)](https://stand-with-ukraine.pp.ua/)

<!-- markdownlint-disable no-inline-html -->

<p align="center">
  <img alt="Codex Account Demo" src="https://github.com/user-attachments/assets/96cd73c7-84b7-4df8-92c8-4924ae71d4f8" />
</p>
<!-- markdownlint-enable no-inline-html -->

# codex-account

[![GitHub Sponsors][gh-sponsors-image]][gh-sponsors-url]
[![Buy Me A Coffee][buymeacoffee-image]][buymeacoffee-url]
[![X.com][x-image]][x-url]

> [!NOTE]
> A small CLI for switching Codex auth accounts by swapping `~/.codex/auth.json`.

Codex currently does not provide a UI for switching between saved profiles. If you use separate work and personal accounts, moving between them usually means re-authenticating or manually replacing `auth.json`.

This utility keeps named snapshots of authenticated accounts so you can move between them without logging in again each time.

## Installation

```sh
# Clone the repository into Codex's config area
git clone https://github.com/denysdovhan/codex-account ~/.codex/.codex-account

# Expose the script as a runnable command from your local bin directory
ln -sfn ~/.codex/.codex-account/codex-account.sh ~/.local/bin/codex-account
```

> [!IMPORTANT]
> Make sure `~/.local/bin` is on your `PATH`.
> Otherwise, the `codex-account` command will not be available after creating the
> symlink.

## Quick Start

```sh
# Log into one Codex account first, then save it
codex-account save personal

# Logout and login into another Codex account, then save that one too
codex-account save work

# See saved accounts and the current match
codex-account list

# Switch back to a saved account
codex-account switch personal

# Show the active account
codex-account current
```

## Commands

### `codex-account help`

Show the built-in help text.

### `codex-account list`

List saved accounts. `*` marks the account whose saved snapshot matches the live
`auth.json`. `~` marks the recorded current account when the live auth differs
from every saved snapshot.

### `codex-account current`

Print the active account name when it can be matched. If the live auth does not
match a saved snapshot, it reports the recorded account when available.

### `codex-account save <account>`

Save the current `~/.codex/auth.json` as `<account>.auth.json` and mark that
account as current.

### `codex-account switch <account>`

Back up the current auth as `<account>-backup.auth.json` when the current auth
can be associated with a saved account, then restore the requested saved
account into `~/.codex/auth.json`.

> [!IMPORTANT]
> Restart Codex after switching if it is already running.

### `codex-account <account>`

Shorthand for `codex-account switch <account>`.

## Notes

- This tool only swaps `auth.json`. It does not change the rest of `~/.codex`.
- Saved accounts live in `~/.codex/.codex-account/accounts`.
- Named backups are stored alongside saved accounts as `*-backup.auth.json`.
- To add a new account, log into it with Codex first, then run
  `codex-account save <account>`.
- Restart Codex after switching if it is already running.

## Contributing

Install the local Git hooks after cloning:

```sh
# Install the Git hooks managed by pre-commit
pre-commit install
```

## License

MIT © [Denys Dovhan](https://denysdovhan.com)

<!-- Badges -->

[buymeacoffee-image]: https://img.shields.io/badge/support-buymeacoffee-222222.svg?style=flat-square
[buymeacoffee-url]: https://patreon.com/denysdovhan
[gh-sponsors-image]: https://img.shields.io/github/sponsors/denysdovhan?style=flat-square
[gh-sponsors-url]: https://github.com/sponsors/denysdovhan
[x-image]: https://img.shields.io/badge/follow-%40denysdovhan-000000.svg?style=flat-square
[x-url]: https://x.com/denysdovhan
