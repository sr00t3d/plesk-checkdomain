# Plesk Domain Pointing Verifier

Readme: [EN](README.md)

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-green.svg)](https://github.com/sr00t3d/plesk-checkdomain/releases)
[![Shell](https://img.shields.io/badge/bash-4.0+-blue.svg)](https://www.gnu.org/software/bash/)

<img width="700" src="plesk-checkdomains-cover.webp" alt="Plesk Domain Pointing Verifier" />

**Plesk Domain Pointing Verifier v2.0.0** e uma ferramenta CLI em Bash para administradores Plesk verificarem via DNS (`dig`) se os dominios hospedados apontam para os enderecos IPv4 autorizados do servidor. Suporta extracao automatica de dominios via `plesk db` e descoberta de IPs, filtros (`all|ok|mismatch`), exportacoes `chmod 600` em texto/CSV, envio opcional por e-mail, modo `--dry-run` e saidas em tabela, JSON ou CSV.

---

## Funcionalidades

- **Descoberta Automatica no Plesk**: consulta `plesk db` para listar dominios e `plesk bin ipmanage --ip_list` (ou `hostname -I`) para IPs autorizados, alem de aceitar `-f / --domains-file` e `-i / --ips`
- **Consultas DNS Rapidas e Configuraveis**: consulta registros `A` via `dig` usando resolver (`--dns-server`, padrao `8.8.8.8`) e timeout (`--timeout`, padrao `2s`) configuraveis
- **Filtros Objetivos (`--filter all|ok|mismatch`)**: isola rapidamente dominios orfaos ou migrados que nao apontam mais para o servidor
- **Exportacoes Protegidas (`chmod 600`)**: `--save PATH` para salvar relatorio, `--export-csv DIR` para gerar CSVs separados (`plesk-domains.csv` e `not-plesk-domains.csv`) e `--email ENDERECO` opcional
- **Simulacao Dry-Run (`--dry-run`)**: carrega dominios e IPs autorizados sem disparar consultas DNS
- **Relatorios Multi-Formato (`-o table|json|csv`)**: tabela ASCII, JSON para automacoes ou CSV para auditorias de limpeza

---

## Requisitos

- Servidor Linux com Bash 4+
- `dig` (`bind-utils` / `dnsutils`)
- Opcional: CLI `plesk` (quando nao usar `--domains-file` / `--ips`) e `mail` (apenas com `--email`)

---

## Instalacao

```bash
curl -fsSLO https://raw.githubusercontent.com/sr00t3d/plesk-checkdomain/main/plesk-checkdomains.sh
chmod +x plesk-checkdomains.sh
```

---

## Uso

```bash
./plesk-checkdomains.sh [OPCOES]

Opcoes:
  -f, --domains-file FILE Arquivo com um dominio por linha (padrao: consulta 'plesk db')
  -i, --ips IP1,IP2       IPv4s autorizados separados por virgula (padrao: autodetect)
  --dns-server IP         Resolver DNS para consultas dig (padrao: 8.8.8.8)
  --timeout SEC           Timeout das consultas DNS em segundos (padrao: 2)
  --filter MODE           Filtro de resultados: all (padrao), ok, mismatch
  --save PATH             Salva relatorio em arquivo (chmod 600)
  --export-csv DIR        Exporta CSVs separados (plesk-domains.csv e not-plesk-domains.csv)
  --email ADDRESS         Envia relatorio por e-mail via mail/mailx (opcional)
  --dry-run               Carrega dominios e IPs sem executar consultas DNS
  -o, --output FORMATO    Formato de saida: table (padrao), json, csv
  -q, --quiet             Suprime saida padrao (mantem erros em stderr)
  --no-color              Desativa cores ANSI
  -V, --version           Exibe a versao e encerra
  -h, --help              Exibe a ajuda e encerra
```

### Exemplos

```bash
# Autodetectar dominios e IPs do Plesk em modo dry-run
./plesk-checkdomains.sh --dry-run

# Auditar lista de dominios contra um IP autorizado e exportar CSVs separados
./plesk-checkdomains.sh -f domains.txt -i 172.64.80.1 --export-csv /root/reports

# Exibir apenas dominios divergentes ou orfaos em JSON
./plesk-checkdomains.sh --filter mismatch -o json

# Execucao em cron salvando relatorio chmod 600 e notificando por e-mail
./plesk-checkdomains.sh --save /root/reports/audit.txt --email ops@exemplo.com.br -q
```

---

## Exemplo de Saida Real

Capturado em servidor AlmaLinux 8.10 consultando Google Public DNS (`8.8.8.8`):

### Saida em tabela (padrao)

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

### Saida JSON (`-o json`)

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

### Saida CSV filtrada (`--filter mismatch -o csv`)

```csv
timestamp,dns_server,domain,resolved_ips,status
2026-11-20T07:13:35Z,"8.8.8.8","example.com","104.20.23.154,172.66.147.243",MISMATCH
2026-11-20T07:13:35Z,"8.8.8.8","nonexistent-test.invalid","NO_IP",NO_IP
```

---

## Licenca

Apache-2.0. Consulte [LICENSE](LICENSE) para detalhes.

## Autor

[Percio Castelo](https://perciocastelo.com.br)
