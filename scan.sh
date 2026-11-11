#!/usr/bin/env bash
# Advanced Nmap Scan Automation
# Use ONLY against systems you own or have explicit permission to test.

set -Eeuo pipefail
IFS=$'\n\t'

VERSION="2.0.0"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${SCRIPT_DIR}/reports"

usage() {
  cat <<'EOF'
Advanced Nmap Scanner v2.0

Usage:
  ./scan.sh -t <target> [options]

Required:
  -t, --target TARGET       IP, hostname, or CIDR range you are authorized to scan

Options:
  -p, --ports PORTS         Ports (default: 1-1000). Example: 22,80,443 or 1-65535
      --profile PROFILE     quick | standard | full (default: standard)
  -o, --output NAME         Report filename prefix (default: scan_<target>_<timestamp>)
      --timing LEVEL        Nmap timing template 0-4 (default: 3)
      --no-ping             Skip host discovery (-Pn); use only when appropriate
      --udp                 Also run a UDP scan (can take considerably longer)
      --safe-scripts        Run NSE scripts in the "safe" category
      --html                Create an HTML report if xsltproc is installed
      --list-interfaces     Show Nmap interfaces and exit
  -h, --help                Show this help
  -V, --version             Show version

Profiles:
  quick       Top 100 TCP ports, service detection
  standard    Selected ports (default 1-1000), service detection
  full        All TCP ports (1-65535), service detection

Examples:
  ./scan.sh -t 192.168.1.10
  ./scan.sh -t 192.168.1.0/24 --profile quick
  ./scan.sh -t scanme.nmap.org -p 22,80,443 --safe-scripts
  ./scan.sh -t 192.168.1.10 --profile full --html

IMPORTANT:
  Only scan your own devices, networks, or explicitly authorized lab targets.
  Scanning may trigger alerts or disrupt fragile systems. Get written permission.
EOF
}

die() { echo "[!] $*" >&2; exit 1; }
info() { echo "[*] $*"; }
ok() { echo "[+] $*"; }

TARGET=""
PORTS="1-1000"
PROFILE="standard"
TIMING="3"
OUTPUT_NAME=""
NO_PING=0
DO_UDP=0
SAFE_SCRIPTS=0
MAKE_HTML=0

while (($#)); do
  case "$1" in
    -t|--target) (($# >= 2)) || die "Missing value for $1"; TARGET="$2"; shift 2 ;;
    -p|--ports) (($# >= 2)) || die "Missing value for $1"; PORTS="$2"; shift 2 ;;
    --profile) (($# >= 2)) || die "Missing value for $1"; PROFILE="$2"; shift 2 ;;
    -o|--output) (($# >= 2)) || die "Missing value for $1"; OUTPUT_NAME="$2"; shift 2 ;;
    --timing) (($# >= 2)) || die "Missing value for $1"; TIMING="$2"; shift 2 ;;
    --no-ping) NO_PING=1; shift ;;
    --udp) DO_UDP=1; shift ;;
    --safe-scripts) SAFE_SCRIPTS=1; shift ;;
    --html) MAKE_HTML=1; shift ;;
    --list-interfaces) command -v nmap >/dev/null 2>&1 || die "Nmap is not installed"; nmap --iflist; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    -V|--version) echo "Advanced Nmap Scanner v${VERSION}"; exit 0 ;;
    --) shift; (($# == 0)) || die "Unexpected positional arguments";;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
done

[[ -n "$TARGET" ]] || { usage; die "Target is required."; }
[[ "$TARGET" != -* ]] || die "Target must not start with '-'."
[[ "$TARGET" != *[[:space:]]* ]] || die "Target must not contain whitespace."
[[ "$TARGET" =~ ^[A-Za-z0-9._:/-]+$ ]] || die "Target contains unsupported characters."
[[ "$PORTS" =~ ^[0-9,-]+$ ]] || die "Ports must contain only numbers, commas, and hyphens."
[[ "$TIMING" =~ ^[0-4]$ ]] || die "Timing must be from 0 to 4."
[[ "$PROFILE" == "quick" || "$PROFILE" == "standard" || "$PROFILE" == "full" ]] || die "Profile must be quick, standard, or full."
[[ -z "$OUTPUT_NAME" || "$OUTPUT_NAME" =~ ^[A-Za-z0-9._-]+$ ]] || die "Output name may contain only letters, numbers, dot, underscore, and hyphen."

command -v nmap >/dev/null 2>&1 || die "Nmap is not installed. Install it first (see README.md)."

case "$PROFILE" in
  quick) PROFILE_PORTS="--top-ports 100" ;;
  standard) PROFILE_PORTS="-p ${PORTS}" ;;
  full) PROFILE_PORTS="-p 1-65535" ;;
esac

mkdir -p "$REPORT_DIR"
timestamp="$(date +%Y%m%d_%H%M%S)"
safe_target="$(printf '%s' "$TARGET" | tr '/:' '__' | tr '.' '_')"
prefix="${OUTPUT_NAME:-scan_${safe_target}_${timestamp}}"
prefix="${REPORT_DIR}/${prefix}"

# Refuse accidental overwrite of existing reports.
for ext in nmap xml gnmap; do
  [[ ! -e "${prefix}.${ext}" ]] || die "Report already exists: ${prefix}.${ext}"
done

args=(-n -sV --version-light "-T${TIMING}" -oA "$prefix")
[[ "$NO_PING" -eq 1 ]] && args+=(-Pn)
if [[ "$PROFILE" == "quick" ]]; then
  args+=(--top-ports 100)
elif [[ "$PROFILE" == "full" ]]; then
  args+=(-p 1-65535)
else
  args+=(-p "$PORTS")
fi
[[ "$SAFE_SCRIPTS" -eq 1 ]] && args+=(--script safe)

info "Advanced Nmap Scanner v${VERSION}"
info "Target: ${TARGET}"
info "Profile: ${PROFILE}"
info "TCP ports: ${PORTS} (ignored by quick/full profile where applicable)"
info "Reports: ${prefix}.{nmap,xml,gnmap}"
info "Starting TCP scan..."

if ! nmap "${args[@]}" "$TARGET"; then
  die "Nmap reported an error. Check target, permissions, and network connectivity."
fi

if [[ "$DO_UDP" -eq 1 ]]; then
  info "Starting UDP top-100 scan (may take a long time)..."
  udp_args=(-n -sU --top-ports 100 "-T${TIMING}" -oA "${prefix}_udp")
  [[ "$NO_PING" -eq 1 ]] && udp_args+=(-Pn)
  [[ "$SAFE_SCRIPTS" -eq 1 ]] && udp_args+=(--script safe)
  nmap "${udp_args[@]}" "$TARGET" || die "UDP scan failed."
fi

if [[ "$MAKE_HTML" -eq 1 ]]; then
  if command -v xsltproc >/dev/null 2>&1 && [[ -s "${prefix}.xml" ]]; then
    xsltproc -o "${prefix}.html" /usr/share/nmap/nmap.xsl "${prefix}.xml" \
      && ok "HTML report: ${prefix}.html" \
      || info "HTML conversion failed; XML report is still available."
  else
    info "HTML report skipped: xsltproc or Nmap XSL stylesheet not found."
  fi
fi

ok "Scan completed."
ok "Text report: ${prefix}.nmap"
ok "XML report:  ${prefix}.xml"
ok "Grep report: ${prefix}.gnmap"
if [[ "$DO_UDP" -eq 1 ]]; then
  ok "UDP report prefix: ${prefix}_udp"
fi
