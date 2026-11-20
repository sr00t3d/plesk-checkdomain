#!/usr/bin/env bash
# +============================================================================+
# | plesk-checkdomains.sh                                                      |
# | Plesk Domain Pointing Verifier v2.0.0                                      |
# | Audits whether Plesk-hosted domains resolve to authorized server IPv4      |
# | addresses via DNS (dig), with automatic IP/domain discovery, filtering,    |
# | optional CSV/email export, dry-run, and table/JSON/CSV reporting.          |
# |                                                                            |
# | Author:  Percio Castelo                                                    |
# | Contact: percio@evolya.com.br | contato@perciocastelo.com.br               |
# | Web:     https://perciocastelo.com.br                                      |
# | Repo:    https://github.com/sr00t3d/plesk-checkdomain                      |
# |                                                                            |
# | Copyright 2024-2026 Percio Castelo                                         |
# | SPDX-License-Identifier: Apache-2.0                                        |
# +============================================================================+

set -uo pipefail

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# ---- Defaults ---------------------------------------------------------------
DOMAINS_FILE=""
IPS_RAW=""
DNS_SERVER="8.8.8.8"
DNS_TIMEOUT=2
FILTER="all"
SAVE_PATH=""
EXPORT_CSV_DIR=""
EMAIL_TO=""
DRY_RUN=0
OUTPUT_FORMAT="table"
QUIET=0
NO_COLOR=0

# ---- Color helpers ----------------------------------------------------------
init_colors() {
    if [[ "$NO_COLOR" -eq 1 || ! -t 1 ]]; then
        C_RESET="" C_BOLD="" C_GREEN="" C_YELLOW="" C_RED="" C_CYAN=""
    else
        C_RESET=$'\033[0m'
        C_BOLD=$'\033[1m'
        C_GREEN=$'\033[32m'
        C_YELLOW=$'\033[33m'
        C_RED=$'\033[31m'
        C_CYAN=$'\033[36m'
    fi
}

# ---- Help & Version ---------------------------------------------------------
show_version() {
    echo "Plesk Domain Pointing Verifier v${VERSION}"
}

show_help() {
    cat <<EOF
Plesk Domain Pointing Verifier v${VERSION}
Checks whether domains resolve via DNS to the authorized Plesk server IPv4s.

Usage: ${SCRIPT_NAME} [OPTIONS]

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

Examples:
  ${SCRIPT_NAME} --dry-run
  ${SCRIPT_NAME} -f domains.txt -i 191.252.117.212 --filter all
  ${SCRIPT_NAME} -f domains.txt -i 191.252.117.212 --filter mismatch -o json
  ${SCRIPT_NAME} --export-csv /root/reports --save /root/reports/audit.txt -o csv
EOF
}

# ---- Argument Parser --------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--domains-file)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires a file path." >&2; exit 1; }
            DOMAINS_FILE="$2"; shift 2 ;;
        -i|--ips)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires a comma-separated IP list." >&2; exit 1; }
            IPS_RAW="$2"; shift 2 ;;
        --dns-server)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires a DNS server IP." >&2; exit 1; }
            DNS_SERVER="$2"; shift 2 ;;
        --timeout)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires a timeout in seconds." >&2; exit 1; }
            DNS_TIMEOUT="$2"; shift 2 ;;
        --filter)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires all, ok, or mismatch." >&2; exit 1; }
            FILTER="$2"; shift 2 ;;
        --save)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires a file path." >&2; exit 1; }
            SAVE_PATH="$2"; shift 2 ;;
        --export-csv)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires a directory path." >&2; exit 1; }
            EXPORT_CSV_DIR="$2"; shift 2 ;;
        --email)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires an email address." >&2; exit 1; }
            EMAIL_TO="$2"; shift 2 ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -o|--output)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires table, json, or csv." >&2; exit 1; }
            OUTPUT_FORMAT="$2"; shift 2 ;;
        -q|--quiet)
            QUIET=1; shift ;;
        --no-color)
            NO_COLOR=1; shift ;;
        -V|--version)
            show_version; exit 0 ;;
        -h|--help)
            show_help; exit 0 ;;
        *)
            echo "ERROR: Unknown option: $1 (run with -h for usage)" >&2
            exit 1 ;;
    esac
done

init_colors

# ---- Validations ------------------------------------------------------------
case "$OUTPUT_FORMAT" in
    table|json|csv) ;;
    *)
        echo "${C_RED}ERROR: Invalid output format '${OUTPUT_FORMAT}'. Expected table, json, or csv.${C_RESET}" >&2
        exit 1 ;;
esac

case "$FILTER" in
    all|ok|mismatch) ;;
    *)
        echo "${C_RED}ERROR: Invalid filter '${FILTER}'. Expected all, ok, or mismatch.${C_RESET}" >&2
        exit 1 ;;
esac

if ! [[ "$DNS_TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$DNS_TIMEOUT" -lt 1 ]]; then
    echo "${C_RED}ERROR: --timeout must be a positive integer.${C_RESET}" >&2
    exit 1
fi

if [[ "$DRY_RUN" -eq 0 ]] && ! command -v dig >/dev/null 2>&1; then
    echo "${C_RED}ERROR: 'dig' (bind-utils/dnsutils) is required for DNS resolution.${C_RESET}" >&2
    exit 1
fi

TIMESTAMP_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HOSTNAME_LOCAL="$(hostname 2>/dev/null || echo unknown)"

# ---- Discover Authorized Server IPs -----------------------------------------
declare -a PLESK_IPS=()
if [[ -n "$IPS_RAW" ]]; then
    IFS=',' read -ra PLESK_IPS <<< "$IPS_RAW"
elif command -v plesk >/dev/null 2>&1; then
    mapfile -t PLESK_IPS < <(plesk bin ipmanage --ip_list 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
fi

if [[ "${#PLESK_IPS[@]}" -eq 0 ]]; then
    mapfile -t PLESK_IPS < <(hostname -I 2>/dev/null | tr ' ' '\n' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' | grep -v '^127\.' | sort -u)
fi

if [[ "${#PLESK_IPS[@]}" -eq 0 ]]; then
    echo "${C_RED}ERROR: Could not detect any server IPv4 address. Pass --ips IP1,IP2.${C_RESET}" >&2
    exit 1
fi

is_plesk_ip() {
    local ip="$1"
    for p in "${PLESK_IPS[@]}"; do
        [[ "$ip" == "$p" ]] && return 0
    done
    return 1
}

# ---- Discover Domains -------------------------------------------------------
declare -a DOMAINS=()
DOMAIN_SOURCE=""
if [[ -n "$DOMAINS_FILE" ]]; then
    if [[ ! -f "$DOMAINS_FILE" ]]; then
        echo "${C_RED}ERROR: Domains file not found: ${DOMAINS_FILE}${C_RESET}" >&2
        exit 1
    fi
    DOMAIN_SOURCE="$DOMAINS_FILE"
    mapfile -t DOMAINS < <(sed -E 's/#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$DOMAINS_FILE" | grep -v '^$' | sort -u)
elif command -v plesk >/dev/null 2>&1; then
    DOMAIN_SOURCE="plesk-db"
    mapfile -t DOMAINS < <(plesk db -N -e "SELECT name FROM domains;" 2>/dev/null | grep -v '^$' | sort -u)
else
    echo "${C_RED}ERROR: 'plesk' CLI not found. Provide a domain list with -f / --domains-file.${C_RESET}" >&2
    exit 1
fi

if [[ "${#DOMAINS[@]}" -eq 0 ]]; then
    echo "${C_RED}ERROR: No domains found from ${DOMAIN_SOURCE}.${C_RESET}" >&2
    exit 2
fi

# ---- Execute DNS Checks -----------------------------------------------------
declare -a R_DOMAIN=()
declare -a R_IPS=()
declare -a R_STATUS=()

COUNT_OK=0
COUNT_MISMATCH=0
COUNT_NOIP=0

for domain in "${DOMAINS[@]}"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
        R_DOMAIN+=("$domain")
        R_IPS+=("-")
        R_STATUS+=("WOULD_CHECK")
        continue
    fi

    mapfile -t resolved < <(
        dig +time="$DNS_TIMEOUT" +tries=1 A +short "$domain" "@${DNS_SERVER}" 2>/dev/null \
            | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || true
    )

    if [[ "${#resolved[@]}" -eq 0 ]]; then
        COUNT_NOIP=$((COUNT_NOIP + 1))
        [[ "$FILTER" == "ok" ]] && continue
        R_DOMAIN+=("$domain")
        R_IPS+=("NO_IP")
        R_STATUS+=("NO_IP")
        continue
    fi

    joined_ips="$(IFS=','; echo "${resolved[*]}")"
    matched=0
    for ip in "${resolved[@]}"; do
        if is_plesk_ip "$ip"; then
            matched=1
            break
        fi
    done

    if [[ "$matched" -eq 1 ]]; then
        COUNT_OK=$((COUNT_OK + 1))
        [[ "$FILTER" == "mismatch" ]] && continue
        R_DOMAIN+=("$domain")
        R_IPS+=("$joined_ips")
        R_STATUS+=("MATCH")
    else
        COUNT_MISMATCH=$((COUNT_MISMATCH + 1))
        [[ "$FILTER" == "ok" ]] && continue
        R_DOMAIN+=("$domain")
        R_IPS+=("$joined_ips")
        R_STATUS+=("MISMATCH")
    fi
done

OVERALL_STATUS="SUCCESS"
[[ "$DRY_RUN" -eq 1 ]] && OVERALL_STATUS="DRY_RUN"
IPS_JOINED="$(IFS=','; echo "${PLESK_IPS[*]}")"

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ---- Render Report ----------------------------------------------------------
render_report() {
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        printf '{\n'
        printf '  "version": "%s",\n' "$VERSION"
        printf '  "status": "%s",\n' "$OVERALL_STATUS"
        printf '  "hostname": "%s",\n' "$(json_escape "$HOSTNAME_LOCAL")"
        printf '  "domain_source": "%s",\n' "$(json_escape "$DOMAIN_SOURCE")"
        printf '  "dns_server": "%s",\n' "$(json_escape "$DNS_SERVER")"
        printf '  "authorized_ips": "%s",\n' "$(json_escape "$IPS_JOINED")"
        printf '  "filter": "%s",\n' "$FILTER"
        printf '  "total_checked": %d,\n' "${#DOMAINS[@]}"
        printf '  "matched": %d,\n' "$COUNT_OK"
        printf '  "mismatched": %d,\n' "$COUNT_MISMATCH"
        printf '  "no_ip": %d,\n' "$COUNT_NOIP"
        printf '  "dry_run": %s,\n' "$([[ "$DRY_RUN" -eq 1 ]] && echo true || echo false)"
        printf '  "timestamp": "%s",\n' "$TIMESTAMP_ISO"
        printf '  "results": [\n'
        for i in "${!R_DOMAIN[@]}"; do
            comma=","
            [[ "$i" -eq $((${#R_DOMAIN[@]} - 1)) ]] && comma=""
            printf '    {"domain": "%s", "resolved_ips": "%s", "status": "%s"}%s\n' \
                "$(json_escape "${R_DOMAIN[$i]}")" \
                "$(json_escape "${R_IPS[$i]}")" \
                "${R_STATUS[$i]}" \
                "$comma"
        done
        printf '  ]\n'
        printf '}\n'

    elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
        echo "timestamp,dns_server,domain,resolved_ips,status"
        for i in "${!R_DOMAIN[@]}"; do
            printf '%s,"%s","%s","%s",%s\n' \
                "$TIMESTAMP_ISO" "$DNS_SERVER" "${R_DOMAIN[$i]}" "${R_IPS[$i]}" "${R_STATUS[$i]}"
        done

    else
        BORDER="+------------------------------+---------------------------+--------------+"
        echo ""
        echo "${C_BOLD}Plesk Domain Pointing Verifier v${VERSION}${C_RESET}"
        echo "Host           : ${HOSTNAME_LOCAL}"
        echo "Source         : ${DOMAIN_SOURCE} (${#DOMAINS[@]} domain(s))"
        echo "DNS Resolver   : ${DNS_SERVER} (timeout: ${DNS_TIMEOUT}s)"
        echo "Authorized IPs : ${IPS_JOINED}"
        echo "Filter         : ${FILTER}"
        echo "Dry-Run        : $([[ "$DRY_RUN" -eq 1 ]] && echo yes || echo no)"
        echo "Status         : ${OVERALL_STATUS}"
        echo "Timestamp      : ${TIMESTAMP_ISO}"
        echo ""
        echo "$BORDER"
        printf "| %-28s | %-25s | %-12s |\n" "Domain" "Resolved IP(s)" "Status"
        echo "$BORDER"
        for i in "${!R_DOMAIN[@]}"; do
            printf "| %-28s | %-25s | %-12s |\n" "${R_DOMAIN[$i]}" "${R_IPS[$i]}" "${R_STATUS[$i]}"
        done
        echo "$BORDER"
        echo "Summary        : ${COUNT_OK} matched | ${COUNT_MISMATCH} mismatched | ${COUNT_NOIP} no-ip"
        echo ""
    fi
}

REPORT_OUT="$(render_report)"

if [[ -n "$SAVE_PATH" && "$DRY_RUN" -eq 0 ]]; then
    mkdir -p "$(dirname "$SAVE_PATH")"
    printf '%s\n' "$REPORT_OUT" > "$SAVE_PATH"
    chmod 600 "$SAVE_PATH"
fi

if [[ -n "$EXPORT_CSV_DIR" && "$DRY_RUN" -eq 0 ]]; then
    mkdir -p "$EXPORT_CSV_DIR"
    csv_ok="${EXPORT_CSV_DIR}/plesk-domains.csv"
    csv_nok="${EXPORT_CSV_DIR}/not-plesk-domains.csv"
    echo "domain;resolved_ips;status" > "$csv_ok"
    echo "domain;resolved_ips;status" > "$csv_nok"
    for i in "${!R_DOMAIN[@]}"; do
        if [[ "${R_STATUS[$i]}" == "MATCH" ]]; then
            printf '%s;%s;%s\n' "${R_DOMAIN[$i]}" "${R_IPS[$i]}" "${R_STATUS[$i]}" >> "$csv_ok"
        else
            printf '%s;%s;%s\n' "${R_DOMAIN[$i]}" "${R_IPS[$i]}" "${R_STATUS[$i]}" >> "$csv_nok"
        fi
    done
    chmod 600 "$csv_ok" "$csv_nok"
fi

if [[ -n "$EMAIL_TO" && "$DRY_RUN" -eq 0 ]]; then
    if command -v mail >/dev/null 2>&1; then
        printf '%s\n' "$REPORT_OUT" | mail -s "Plesk Domain Check (${HOSTNAME_LOCAL}) - ${TIMESTAMP_ISO}" "$EMAIL_TO" || true
    fi
fi

if [[ "$QUIET" -eq 0 ]]; then
    printf '%s\n' "$REPORT_OUT"
fi

exit 0
