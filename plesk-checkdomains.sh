#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   Plesk Check Domains v1.0.0                                              ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Autor:   Percio Castelo                                                 ║
# ║   Contato: percio@evolya.com.br | contato@perciocastelo.com.br            ║
# ║   Web:     https://perciocastelo.com.br                                   ║
# ║                                                                           ║
# ║   Função:  Check if the domains point to the IPs of the Plesk server.     ║
# ║            Includes a progress bar and export to CSV.                     ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# --- Report and Log Settings ---
DIRECTORY_REPORTS="/opt/suporte/relatorios"
FILE_REPORT="$DIRECTORY_REPORTS/plesk-relatorio-dominios.txt"
DESTINY_MAIL="mail@domain.tld" # Replace with the recipient's actual email address.
EXECUTION_DATE=$(date "+%d/%m/%Y %H:%M:%S")

# Ensure that the reports directory exists.
mkdir -p "$DIRECTORY_REPORTS"

# Ensures that only root can read the file.
touch "$FILE_REPORT"
chmod 600 "$FILE_REPORT"

# Detect System Language (Get first 2 chars, e.g., 'pt' from 'pt_BR.UTF-8')
SYSTEM_LANG="${LANG:0:2}"

if [[ "$SYSTEM_LANG" == "pt" ]]; then
    # Mensagens em Português
    MSG_GEN_LIST="Lista de domínios não encontrada, gerando..."
    MSG_USE_LIST="Utilizando a lista de domínios em"
    MSG_START="Iniciando verificação de domínios"
    MSG_PROG="Progresso"
    MSG_DONE="Verificação concluída!"
    MSG_HEADER_OK="Domínios apontando para o Plesk"
    MSG_HEADER_NOK="Domínios que NÃO apontam para o Plesk"
    MSG_CSV="CSV gerado:"
    MSG_DOMAINS="domínios"
    MSG_NO_IP="SEM IP"
    MSG_COL_DOMAIN="Domínio"
    MSG_REPORT_EXEC="RELATÓRIO DE EXECUÇÃO:"
    MSG_REPORT_SAVED="Relatório incremental salvo em:"
    MSG_EMAIL_SENT="E-mail enviado para"
else
    # Default to English
    MSG_GEN_LIST="Domain list not found, generating..."
    MSG_USE_LIST="Using domain list at"
    MSG_START="Starting domain verification"
    MSG_PROG="Progress"
    MSG_DONE="Verification completed!"
    MSG_HEADER_OK="Domains pointing to Plesk"
    MSG_HEADER_NOK="Domains NOT pointing to Plesk"
    MSG_CSV="CSV generated:"
    MSG_DOMAINS="domains"
    MSG_NO_IP="NO IP"
    MSG_COL_DOMAIN="Domain"
    MSG_REPORT_EXEC="EXECUTION REPORT:"
    MSG_REPORT_SAVED="Incremental report saved at:"
    MSG_EMAIL_SENT="Email sent to"
fi

# Generate domain file
if [[ ! -f plesk-domains.txt ]]; then
        echo "$MSG_GEN_LIST"
        plesk db -N -e "SELECT name FROM domains;" > plesk-domains.txt
else
        echo "$MSG_USE_LIST $(pwd)/plesk-domains.txt"
fi

# List of server IPs
# Eg
# PLESK_IPS=("192.168.1.100" "192.168.1.101") # Replace with the actual IP addresses of the Plesk server.
PLESK_IPS=("SERVER_IP_1") 

# File with the list of domains
DOMAINS_FILE="${DOMAINS_FILE:-plesk-domains.txt}"

# Arrays to store results
declare -a OK
declare -a NOK

# Function to check if an IP is on the Plesk list
is_plesk_ip() {
    local ip=$1
    for fip in "${PLESK_IPS[@]}"; do
        [[ "$ip" == "$fip" ]] && return 0
    done
    return 1
}

# Total number of domains
TOTAL=$(grep -cve '^\s*$' "$DOMAINS_FILE")
COUNT=0

echo "$MSG_START ($TOTAL $MSG_DOMAINS)..."

# Process each domain
while read -r domain; do
    [[ -z "$domain" ]] && continue
    COUNT=$((COUNT + 1))

    # Progress bar
    PERC=$((COUNT * 100 / TOTAL))
    printf "\r$MSG_PROG: [%-50s] %d%%" $(printf "%0.s=" $(seq 1 $((PERC/2)))) "$PERC"

    # Capture IPs from the domain with a short timeout
    readarray -t ip_list < <(dig +time=2 +tries=1 A +short "$domain" @8.8.8.8 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

    if [[ ${#ip_list[@]} -eq 0 ]]; then
        NOK+=("$domain | $MSG_NO_IP")
        continue
    fi

    matched=false
    for ip in "${ip_list[@]}"; do
        if is_plesk_ip "$ip"; then
            OK+=("$domain | $ip")
            matched=true
        fi
    done

    if [[ $matched == false ]]; then
        for ip in "${ip_list[@]}"; do
            NOK+=("$domain | $ip")
        done
    fi
done < "$DOMAINS_FILE"

echo -e "\n\n$MSG_DONE\n"

# --- START OF TXT REPORT GENERATION ---
{
    echo "=================================================="
    echo "$MSG_REPORT_EXEC $EXECUTION_DATE"
    echo "=================================================="
    echo ""
    echo "$MSG_HEADER_OK"
    echo "------------------------------"
    for item in "${OK[@]}"; do
        echo "$item"
    done
    echo ""
    echo "$MSG_HEADER_NOK"
    echo "------------------------------"
    for item in "${NOK[@]}"; do
        echo "$item"
    done
    echo -e "\n\n"
} >> "$FILE_REPORT"
# --- END OF TXT REPORT GENERATION ---

# Displays on the terminal (optional, maintained as original)
echo "$MSG_REPORT_SAVED $FILE_REPORT"

# Export CSV
CSV_OK="plesk-domains.csv"
CSV_NOK="not-plesk-domains.csv"

echo "$MSG_COL_DOMAIN;IP" > "$CSV_OK"
for item in "${OK[@]}"; do
    echo "$item" | sed 's/ | /;/' >> "$CSV_OK"
done

echo "$MSG_COL_DOMAIN;IP" > "$CSV_NOK"
for item in "${NOK[@]}"; do
    echo "$item" | sed 's/ | /;/' >> "$CSV_NOK"
done

# Email Sending
# We only send a portion of the last execution so the email doesn't become too long over time.
tail -n $(( ${#OK[@]} + ${#NOK[@]} + 10 )) "$FILE_REPORT" | mail -s "Plesk Domain Check - $EXECUTION_DATE" "$DESTINY_MAIL"

echo "$MSG_EMAIL_SENT $DESTINY_MAIL"
echo
echo "$MSG_CSV"
echo " - $CSV_OK"
echo " - $CSV_NOK"