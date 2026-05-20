# Multi-Cloudflared Manager (mcf)

Manage multiple Cloudflare tunnels with different accounts on a single VPS easily.
Built and tested on Ubuntu 22.04 (works on any modern Linux with bash 4+).

**Author:** caixax - dios

## Features

- **Multi-Account Support:** Switch between different Cloudflare accounts seamlessly, each with its own isolated `cert.pem`.
- **PM2-style Management:** Easy commands to `start`, `stop`, `list`, `restart`, and `delete` tunnels.
- **Real `delete`:** Removes the tunnel locally **and** in Cloudflare (`cloudflared tunnel cleanup` + `delete -f`), and wipes associated DNS CNAMEs via the Cloudflare API.
- **Safe meta format:** All per-tunnel metadata is stored as JSON (no more `source`-ing untrusted text).
- **Strict-mode script:** Runs under `set -euo pipefail`; failures abort instead of printing fake `[SUCCESS]` messages.
- **Auto-Logging:** Logs are automatically stored under `~/.multi-cloudflared/logs/`.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/caixax/mcf.git
   cd mcf
   ```

2. Make the script executable and install it to your path:
   ```bash
   chmod +x mcf
   sudo cp mcf /usr/local/bin/
   ```

3. Make sure `cloudflared`, `jq`, and `curl` are installed. `mcf setup` checks for you:
   ```bash
   mcf setup
   ```

## Usage

The command `mcf` is your main entry point.

### 1. Create a User (Account)

This opens the Cloudflare login link. Authenticate with the desired account.

```bash
mcf create user my-main-account
```

You will then be prompted (optionally) for a **Cloudflare API token** for that account. The token is required if you want `mcf delete` to also remove DNS records (CNAMEs) created via `mcf route`. Press Enter to skip; you can always add it later:

```bash
mcf set token my-main-account
```

The token needs **Zone:Read** and **DNS:Edit** permissions on the zones you intend to manage. You can repeat the whole flow for other accounts:

```bash
mcf create user client-account
```

### 2. Manage Domains (Optional, Informational)

You can track which domains belong to which user (purely for your own bookkeeping; it does not interact with Cloudflare):

```bash
mcf add domain example.com --user my-main-account
mcf add domain client-site.es --user client-account
```

View users and their tracked domains:

```bash
mcf list users
```

### 3. Create a Tunnel

Create a tunnel linked to a specific user. The credentials file is written directly inside the tunnel's directory (no global state touched):

```bash
mcf create tunnel website-tunnel --user my-main-account
```

### 4. Route DNS and Start

Route a DNS hostname to your tunnel (the zone must live in the chosen user's Cloudflare account):

```bash
mcf route website-tunnel app.example.com
```

You can route multiple hostnames to the same tunnel — they are all tracked in the tunnel's meta so `mcf delete` can clean them up later.

## Advanced Usage (PM2 Style)

### Managing Processes

`mcf` assigns an **ID** to every tunnel. You can use this ID for all commands.

**List all tunnels:**

```bash
mcf list
```

Output:

```
ID   NAME            USER            STATUS    PID      HOSTNAMES                 LOCAL
1    website-01      my-user         ONLINE    12345    app.example.com           http://localhost:3000
2    api-tunnel      client-x        STOPPED   -        api.client.com            -
```

**Start / Stop / Restart by ID or name:**

```bash
mcf start 1 3000                    # Start ID 1 on port 3000 (shorthand)
mcf start 1 http://localhost:3000   # Explicit URL
mcf stop 1
mcf restart 1
```

**View Logs:**

Like `pm2 logs`, tail the tunnel daemon output:

```bash
mcf logs 1
mcf logs 1 --lines 100
```

### Deleting Tunnels

`mcf delete` does a full cleanup, in this order:

1. Stop the local process (if running).
2. `cloudflared tunnel cleanup <uuid>` — drop stale connections.
3. `cloudflared tunnel delete -f <uuid>` — delete the tunnel from Cloudflare.
4. For every routed hostname stored in the meta: delete the matching DNS record via the Cloudflare API (requires `mcf set token <user>`).
5. Remove the local tunnel directory.

If no API token is set, step 4 is skipped with a warning and the CNAMEs survive — set the token and clean them up by hand, or delete them through the dashboard.

```bash
mcf delete website-tunnel
```

### Purge a Whole User

To nuke every tunnel of a given user, every DNS record they created via mcf, and the user itself (cert + token + tracked domains) in one go:

```bash
mcf purge user my-main-account
```

Interactive confirmation required.

### Persistence (Startup)

To ensure your tunnels start automatically after a server reboot:

1. **Setup the startup hook:**
   ```bash
   mcf startup
   ```
   *Creates a systemd service.*

2. **Save the current list** — start every tunnel you want to run, then:
   ```bash
   mcf save
   ```
   *Snapshots the list of currently-running tunnels. They will be resurrected on boot via `mcf resurrect`.*

### Packaging

Build a `.deb` package to install this tool easily on other servers:

```bash
./build.sh
```

*Creates `mcf_1.2.1_all.deb`, install via `sudo dpkg -i mcf_1.2.1_all.deb`.*

## Directory Structure

Data is stored in `~/.multi-cloudflared/`:

- `users/<user>/cert.pem` — Cloudflare origin cert for the account.
- `users/<user>/api_token` — optional API token (chmod 600).
- `users/<user>/domains` — bookkeeping list of domains.
- `tunnels/<name>/meta` — JSON metadata (`uuid`, `user`, `id`, `creds`, `created_at`, `hostnames`, `url`).
- `tunnels/<name>/creds.json` — tunnel credentials (chmod by cloudflared).
- `tunnels/<name>/pid` — present while the tunnel is running.
- `logs/<name>.log` — cloudflared stdout/stderr.
- `dump.json` — `mcf save` snapshot for `mcf resurrect`.

## License

MIT

## Changelog

### 1.2.1

- **Dropped legacy meta migration.** Per-tunnel meta is now assumed to be JSON; a non-JSON meta is a hard, loud error instead of being silently rewritten.
- **Hardened `set -euo pipefail` behaviour.** Internal `meta_*` reads are guarded so a single corrupted meta no longer aborts the whole run.
- **Faster bad-token feedback.** `delete`/DNS cleanup now detects a rejected Cloudflare token on the first API call (e.g. code 6003) and reports the exact code/message plus the `mcf set token <user>` fix, instead of uselessly walking the FQDN.
- **`sudo mcf startup` now works.** The systemd unit is generated for the invoking user (`$SUDO_USER`) and their real home, not root's.
- **Identifier validation.** `create user` / `create tunnel` reject names that aren't `[a-zA-Z0-9_-]+` before any directory is created.
- **Cleaner `delete`.** The tunnel's orphaned `logs/<name>.log` is removed along with its directory.
