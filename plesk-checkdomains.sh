#!/bin/bash
################################################################################
#                                                                              #
#   PROJECT: Plesk DNS Auditor                                                 #
#   VERSION: 9.0.1                                                             #
#                                                                              #
#   AUTHOR:  Percio Andrade                                                    #
#   CONTACT: percio@evolya.com.br | contato@perciocastelo.com.br               #
#   WEB:     https://perciocastelo.com.br                                      #
#                                                                              #
#   INFO:                                                                      #
#   Check if domains point to Plesk Server IPs with progress bar & CSV export. #
#                                                                              #
################################################################################

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
    MSG_NO_IP="SEM IP"      # Adicionado
    MSG_COL_DOMAIN="Domínio" # Adicionado para cabeçalhos (Maiúsculo)
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
    MSG_NO_IP="NO IP"       # Added
    MSG_COL_DOMAIN="Domain"  # Added for headers (Capitalized)
fi

# Generate domain file
if [[ ! -f plesk-domains.txt ]]; then
        echo "$MSG_GEN_LIST"
        plesk db -N -e "SELECT name FROM domains;" > plesk-domains.txt
else
        echo "$MSG_USE_LIST $(pwd)/plesk-domains.txt"
fi

# List of server IPs (adjust the correct IPs here)
PLESK_IPS=("IP")

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

# Line break after progress
echo -e "\n\n$MSG_DONE\n"

# Displays result in the terminal
echo "=============================="
echo "$MSG_HEADER_OK"
echo "$MSG_COL_DOMAIN | IP"
for item in "${OK[@]}"; do
    echo "$item"
done

echo
echo "=============================="
echo "$MSG_HEADER_NOK"
echo "$MSG_COL_DOMAIN | IP"
for item in "${NOK[@]}"; do
    echo "$item"
done

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

echo
echo "$MSG_CSV"
echo " - $CSV_OK"
echo " - $CSV_NOK"
