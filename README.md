# Multi-Cloudflared Manager (mcf)

Manage multiple Cloudflare tunnels with different accounts on a single VPS easily. 
Built for Ubuntu 22.04.

**Author:** caixax - dios

## Features

- **Multi-Account Support:** Switch between different Cloudflare accounts seamlessly.
- **PM2-style Management:** Easy commands to `start`, `stop`, `list`, and `delete` tunnels.
- **Isolated Configurations:** Keeps certificates and credentials organized per user and tunnel.
- **Auto-Logging:** Logs are automatically stored for debugging.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/multi-cloudflare.git
   cd multi-cloudflare
   ```

2. Make the script executable and install it to your path:
   ```bash
   chmod +x mcf
   sudo cp mcf /usr/local/bin/
   ```

3. Ensure `cloudflared` is installed. If not, follow the [official guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/) or let `mcf` check for you:
   ```bash
   mcf setup
   ```

## Usage

The command `mcf` is your main entry point.

### 1. Create a User (Account)
This will open the Cloudflare login link. Authenticate with the desired account.
```bash
mcf create user my-main-account
```
You can repeat this for other accounts:
```bash
mcf create user client-account
```

### 2. Manage Domains (Optional)
You can associate domains with users to keep track of which account owns what.
```bash
mcf add domain example.com --user my-main-account
mcf add domain client-site.es --user client-account
```
View users and their domains:
```bash
mcf list users
```

### 3. Create a Tunnel
Create a tunnel linked to a specific user.
```bash
mcf create tunnel website-tunnel --user my-main-account
```

### 4. Route and Start
Route a DNS hostname to your tunnel (requires the domain to be in the user's Cloudflare account):
```bash
mcf route website-tunnel app.example.com
```

## Advanced Usage (PM2 Style)

### Managing Processes
`mcf` now assigns an **ID** to every tunnel. You can use this ID for all commands.

**List all tunnels:**
```bash
mcf list
```
*Output:*
```
ID   NAME            USER            STATUS              PID      HOSTNAME                  LOCAL
1    website-01      my-user         ONLINE              12345    app.example.com           http://localhost:3000
2    api-tunnel      client-x        STOPPED             -        api.client.com            -
```

**Start/Stop/Restart by ID:**
```bash
mcf start 1 3000        # Start ID 1 on port 3000 (shorthand)
mcf start 1 http://localhost:3000  # Explicit URL
mcf stop 1
mcf restart 1
```

**View Logs:**
Like `pm2 logs`, view the output of the tunnel daemon.
```bash
mcf logs 1
mcf logs 1 --lines 100
```

### Persistence (Startup)
To ensure your tunnels start automatically after a server reboot:

1. **Setup the startup hook:**
   ```bash
   mcf startup
   ```
   *This creates a systemd service.*

2. **Save the current list:**
   Start all the tunnels you want to run, then:
   ```bash
   mcf save
   ```
   *This freezes the list of running tunnels. They will be resurrected on boot.*

### Packaging
You can build a `.deb` package to install this tool easily on other servers.
Run the build script:
```bash
./build.sh
```
*Creates `mcf_1.1.0_all.deb` which can be installed via `sudo dpkg -i mcf_1.1.0_all.deb`*

## Directory Structure

Data is stored in `~/.multi-cloudflared/`:
- `users/`: Stores `cert.pem` for each account.
- `tunnels/`: Stores credentials and metadata for each tunnel.
- `logs/`: Output logs for running tunnels.

## License

MIT
