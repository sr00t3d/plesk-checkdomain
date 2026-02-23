# Domain Name Verifier (Plesk)

Readme: [Português](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/plesk-checkdomain)
![Bash Script](https://img.shields.io/badge/bash-script-green)

This Bash script was developed to audit and bulk-verify whether a list of domains (extracted from Plesk or manually provided) is correctly pointing to the IP addresses of a target server.

The script resolves the DNS of each domain externally (using Google DNS
8.8.8.8 to avoid local cache), compares it with a list of authorized IPs,
generates CSV reports, appends an incremental TXT execution report, and sends
an email summary.

## 🚀 Features

- Automatic Extraction: If there is no prior list, the script automatically extracts all domains from the Plesk database (plesk db).
- External DNS Verification: Uses dig pointing to Google DNS, ensuring that propagation is checked externally.
- Visual Feedback: Includes a real-time progress bar to monitor the processing of large lists.
- CSV Reports: Generates two separate files (semicolon-separated ;) to simplify importing into Excel:
- Domains with correct pointing.
- Domains with incorrect pointing or without IP.
- Incremental TXT report: Appends each run to a persistent report file.
- Email summary: Sends only the current execution section by email.

## 📋 Prerequisites

- Linux Operating System (compatible with Plesk servers).
- Root access or permission to execute Plesk (plesk db) and dig commands.
- bind-utils or dnsutils package installed (for the dig command).
- `mail` command configured on the server (mailx / mailutils).

## ⚙️ Configuration

Before running, update the variables at the beginning of the script:

```bash
DIRECTORY_REPORTS="/opt/suporte/relatorios"
FILE_REPORT="$DIRECTORY_REPORTS/plesk-relatorio-dominios.txt"
DESTINY_MAIL="mail@domain.tld"
PLESK_IPS=("SERVER_IP_1")
```

You can add multiple IPs by separating them with spaces inside
`PLESK_IPS=(...)`.

## ▶️ How to Use

**1. Installation:**

Save the script on the server, for example, as plesk-checkdomains.sh.

**2. Execution Permission:**

```bash
chmod +x plesk-checkdomains.sh
```

**3. Execution:**

```bash
./plesk-checkdomains.sh
```

## Domain List Behavior

- **First execution**: The script looks for `plesk-domains.txt`. If not found,
  it runs the Plesk command to generate the base list.
- **Subsequent executions**: If `plesk-domains.txt` already exists, the script
  uses this static list. To force a fresh read from Plesk, remove
  `plesk-domains.txt` before running again.

## 📂 Output (Outputs)

At the end of execution, the script prints progress/status and generates:

```bash
File                   ,  Description
plesk-domains.csv      ,  List of domains that correctly point to the configured IPs.
not-plesk-domains.csv  ,  List of domains that DO NOT point to the configured IPs or do not have DNS resolution.
/opt/suporte/relatorios/plesk-relatorio-dominios.txt , Incremental execution report (appended on each run).
```

## ⚠️ Legal Notice

> [!WARNING]
> This software is provided "as is". Always make sure to test first in a development environment. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## 📚 Detailed Tutorial

For a complete, step-by-step guide, check out my full article:

👉 [**Check Domains Ponting to Plesk**](https://perciocastelo.com.br/blog/check-domains-pointing-to-plesk.html)

## License 📄

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.
