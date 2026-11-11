# Advanced Nmap Scanner

A Bash-based wrapper for Nmap that adds safer argument handling, scan profiles,
timestamped reports, optional UDP top-100 scanning, optional safe NSE scripts,
and optional HTML report conversion.

> **Authorization required:** Use this tool only on systems and networks you own
> or have explicit permission to assess. Scanning can trigger security alerts and
> may affect fragile systems. Obtain written authorization and follow the scope.

## Features

- Quick, standard, and full TCP scan profiles
- Custom TCP port selection
- Service/version detection (`-sV --version-light`)
- Optional UDP top-100 scan
- Optional NSE `safe` category scripts
- Nmap normal, XML, and grepable output (`-oA`)
- Optional HTML conversion using `xsltproc`
- Input validation and protection against option injection
- Timestamped output under `reports/`

## Requirements

- Linux, macOS, or WSL with Bash 4+ recommended
- Nmap
- Optional: `xsltproc` for HTML conversion

Install Nmap:

```bash
# Debian / Ubuntu / Kali
sudo apt update && sudo apt install nmap

# Fedora
sudo dnf install nmap

# macOS with Homebrew
brew install nmap
```

Optional HTML dependency on Debian/Ubuntu:

```bash
sudo apt install xsltproc
```

## Setup

```bash
git clone https://github.com/azlanshaikh125/nmap-scan-script.git
cd nmap-scan-script
chmod +x scan.sh
```

If using the downloaded ZIP, extract it and run `chmod +x scan.sh` inside the folder.

## Usage

```bash
./scan.sh --help
```

Examples (authorized targets only):

```bash
# Default standard scan: TCP ports 1-1000
./scan.sh --target 192.168.1.10

# Quick scan: top 100 TCP ports
./scan.sh -t 192.168.1.10 --profile quick

# Selected TCP ports
./scan.sh -t 192.168.1.10 --ports 22,80,443

# Full TCP port range
./scan.sh -t 192.168.1.10 --profile full

# Add safe-category NSE scripts
./scan.sh -t 192.168.1.10 --safe-scripts

# UDP top 100 plus standard TCP scan
./scan.sh -t 192.168.1.10 --udp

# Produce HTML if xsltproc and the Nmap stylesheet are installed
./scan.sh -t 192.168.1.10 --html

# Combine options
./scan.sh -t 192.168.1.10 --profile quick --safe-scripts --html --timing 2
```

## Options

| Option | Description |
|---|---|
| `-t`, `--target` | IP, hostname, or CIDR target |
| `-p`, `--ports` | TCP ports for standard profile (default `1-1000`) |
| `--profile quick` | Top 100 TCP ports |
| `--profile standard` | Selected TCP ports |
| `--profile full` | TCP ports 1-65535 |
| `--timing 0..4` | Nmap timing template; default 3 |
| `--no-ping` | Skip host discovery (`-Pn`) |
| `--udp` | Additional UDP top-100 scan |
| `--safe-scripts` | Run NSE scripts in the `safe` category |
| `--html` | Convert XML to HTML if dependencies exist |
| `-o`, `--output` | Custom report filename prefix |
| `--list-interfaces` | Show Nmap network interfaces |
| `-h`, `--help` | Help |

## Output

Reports are saved in `reports/`:

- `.nmap` — human-readable output
- `.xml` — structured output for tools and automation
- `.gnmap` — grepable output
- `_udp.*` — additional UDP scan reports when `--udp` is used
- `.html` — optional HTML report

## Safety notes

- The default scan does not run NSE scripts.
- `--safe-scripts` explicitly opts into the NSE `safe` category; review scripts and scope before use.
- UDP scans can be slow and are limited to the top 100 UDP ports in this wrapper.
- `--profile full` can take significantly longer than a quick scan.
- Timing level 4 is more aggressive; use lower values on fragile or rate-limited networks.
- This script does not exploit vulnerabilities or attempt authentication.

## Troubleshooting

**`nmap: command not found`** — Install Nmap and ensure it is on your `PATH`.

**Permission errors** — Some scan types require elevated privileges. The default TCP connect-style service scan generally works without raw-packet privileges. Do not run the whole script as root unless needed and authorized.

**HTML report not created** — Install `xsltproc` and verify that `/usr/share/nmap/nmap.xsl` exists. The XML report remains available.

## License

MIT. See `LICENSE`.
