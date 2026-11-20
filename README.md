# Plesk Domain Pointing Verifier

Readme: [PT-BR](README-ptbr.md)

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-green.svg)](https://github.com/sr00t3d/plesk-checkdomain/releases)
[![Shell](https://img.shields.io/badge/bash-4.0+-blue.svg)](https://www.gnu.org/software/bash/)

<img width="700" src="plesk-checkdomains-cover.webp" alt="Plesk Domain Pointing Verifier" />

**Plesk Domain Pointing Verifier v2.0.0** is a Bash CLI auditing tool for Plesk administrators that verifies whether hosted domains resolve via DNS (`dig`) to authorized server IPv4 addresses. It supports automatic Plesk DB domain extraction and server IP discovery, filtering (`all|ok|mismatch`), `chmod 600` report/CSV exports, optional email delivery, dry-run mode, and table/JSON/CSV outputs.

---

## Features

- **Automatic Plesk Discovery**: queries `plesk db` for hosted domains and `plesk bin ipmanage --ip_list` (or `hostname -I`) for authorized IPs, or accepts custom `-f / --domains-file` and `-i / --ips` overrides
- **Fast Configurable DNS Queries**: queries `A` records via `dig` against a configurable resolver (`--dns-server`, default `8.8.8.8`) and timeout (`--timeout`, default `2s`)
- **Actionable Filtering (`--filter all|ok|mismatch`)**: isolate orphaned or migrated domains that no longer point to the server
- **Protected Exports (`chmod 600`)**: optional `--save PATH` report file, `--export-csv DIR` split CSVs (`plesk-domains.csv` and `not-plesk-domains.csv`), and optional `--email ADDRESS` delivery
- **Dry-Run Simulation (`--dry-run`)**: loads domains and authorized IPs without issuing DNS queries
- **Multi-Format Reporting (`-o table|json|csv`)**: ASCII table, JSON for pipelines, or CSV for cleanup audits

---

## Requirements

- Linux server with Bash 4+
- `dig` (`bind-utils` / `dnsutils`)
- Optional: `plesk` CLI (when not passing `--domains-file` / `--ips`) and `mail` (only when using `--email`)

---

## Installation

```bash
curl -fsSLO https://raw.githubusercontent.com/sr00t3d/plesk-checkdomain/main/plesk-checkdomains.sh
chmod +x plesk-checkdomains.sh
```

---

## Usage

```bash
./plesk-checkdomains.sh [OPTIONS]

Options:
  -f, --domains-file FILE File with one domain per line (default: query 'plesk db')
  -i, --ips IP1,IP2       Comma-separated authorized server IPv4s (default: auto-detect)
  --dns-server IP         DNS resolver for dig queries (default: 8.8.8.8)
  --timeout SEC           DNS query timeout in seconds (default: 2)
  --filter MODE           Filter results: all (default), ok, mismatch
  --save PATH             Save rendered report to file (chmod 600)
  --export-csv DIR        Export split CSVs (plesk-domains.csv & not-plesk-domains.csv)
  --email ADDRESS         Email report summary via mail/mailx (optional)
  --dry-run               Load domains & authorized IPs without running DNS queries
  -o, --output FORMAT     Output format: table (default), json, csv
  -q, --quiet             Suppress standard output (errors still go to stderr)
  --no-color              Disable ANSI colors
  -V, --version           Show version and exit
  -h, --help              Show this help and exit
```

### Examples

```bash
# Auto-detect Plesk domains & IPs in dry-run mode
./plesk-checkdomains.sh --dry-run

# Audit a custom domain list against an authorized IP and export split CSVs
./plesk-checkdomains.sh -f domains.txt -i 172.64.80.1 --export-csv /root/reports

# Show only mismatched / orphaned domains in JSON
./plesk-checkdomains.sh --filter mismatch -o json

# Cron-friendly audit saving a chmod 600 report and emailing ops
./plesk-checkdomains.sh --save /root/reports/audit.txt --email ops@example.com -q
```

---

## Real Output Example

Captured live on an AlmaLinux 8.10 server querying Google Public DNS (`8.8.8.8`):

### Table output (default)

```text
$ ./plesk-checkdomains.sh -f /tmp/plesk-e2e/domains.txt -i 172.64.80.1 --save /tmp/plesk-e2e/report.txt --export-csv /tmp/plesk-e2e/csv --no-color

Plesk Domain Pointing Verifier v2.0.0
Host           : plesk-srv01.example.com
Source         : /tmp/plesk-e2e/domains.txt (3 domain(s))
DNS Resolver   : 8.8.8.8 (timeout: 2s)
Authorized IPs : 172.64.80.1
Filter         : all
Dry-Run        : no
Status         : SUCCESS
Timestamp      : 2026-11-20T07:13:35Z

+------------------------------+---------------------------+--------------+
| Domain                       | Resolved IP(s)            | Status       |
+------------------------------+---------------------------+--------------+
| example.com                  | 172.66.147.243,104.20.23.154 | MISMATCH     |
| nonexistent-test.invalid     | NO_IP                     | NO_IP        |
| perciocastelo.com.br         | 172.64.80.1               | MATCH        |
+------------------------------+---------------------------+--------------+
Summary        : 1 matched | 1 mismatched | 1 no-ip
```

### JSON output (`-o json`)

```json
{
  "version": "2.0.0",
  "status": "SUCCESS",
  "hostname": "plesk-srv01.example.com",
  "domain_source": "/tmp/plesk-e2e/domains.txt",
  "dns_server": "8.8.8.8",
  "authorized_ips": "172.64.80.1",
  "filter": "all",
  "total_checked": 3,
  "matched": 1,
  "mismatched": 1,
  "no_ip": 1,
  "dry_run": false,
  "timestamp": "2026-11-20T07:13:35Z",
  "results": [
    {"domain": "example.com", "resolved_ips": "172.66.147.243,104.20.23.154", "status": "MISMATCH"},
    {"domain": "nonexistent-test.invalid", "resolved_ips": "NO_IP", "status": "NO_IP"},
    {"domain": "perciocastelo.com.br", "resolved_ips": "172.64.80.1", "status": "MATCH"}
  ]
}
```

### Filtered CSV output (`--filter mismatch -o csv`)

```csv
timestamp,dns_server,domain,resolved_ips,status
2026-11-20T07:13:35Z,"8.8.8.8","example.com","104.20.23.154,172.66.147.243",MISMATCH
2026-11-20T07:13:35Z,"8.8.8.8","nonexistent-test.invalid","NO_IP",NO_IP
```

---

## License

Apache-2.0. See [LICENSE](LICENSE) for details.

## Author

[Percio Castelo](https://perciocastelo.com.br)
