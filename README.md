# Domain Pointing Checker (Plesk)

Readme: [Português](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/plesk-checkdomain)
![PHP Script](https://img.shields.io/badge/javascript-script-green)

This Bash script was developed to audit and bulk-verify whether a list of domains (extracted from Plesk or manually provided) is correctly pointing to the IP addresses of a target server.

The script resolves the DNS of each domain externally (using Google DNS 8.8.8.8 to avoid local cache), compares it with a list of authorized IPs, and generates CSV reports.

## 🚀 Features

- Automatic Extraction: If there is no prior list, the script automatically extracts all domains from the Plesk database (plesk db).
- External DNS Verification: Uses dig pointing to Google DNS, ensuring that propagation is checked externally.
- Visual Feedback: Includes a real-time progress bar to monitor the processing of large lists.
- CSV Reports: Generates two separate files (semicolon-separated ;) to simplify importing into Excel:
- Domains with correct pointing.
- Domains with incorrect pointing or without IP.

## 📋 Prerequisites

- Linux Operating System (compatible with Plesk servers).
- Root access or permission to execute Plesk (plesk db) and dig commands.
- bind-utils or dnsutils package installed (for the dig command).

## ⚙️ Configuration

Before running, check the IP variable at the beginning of the script to ensure it matches the current infrastructure:

```bash
# Andamento IP list (adjust correct IPs here)
ANDAMENTO_IPS=("IP")
```

_You can add multiple IPs by separating them with spaces inside the parentheses._

## ▶️ How to Use

**1. Installation:**

Save the script on the server, for example, as plesk-checkdomains.sh.

**2. Execution Permission:**

```bash
chmod +x plesk-checkdomains.sh
```

**3. Execution:**

```bash
./check_domains.sh
```

## Domain List Behavior

- **First Execution**: The script will look for the file dominio-andamento.txt. If not found, it will execute the Plesk command to generate the base list.
- **Subsequent Executions**: If the dominio-andamento.txt file already exists, the script will use this static list. To force a new read from Plesk, remove this file (rm dominio-andamento.txt) before running the script.

## 📂 Output (Outputs)

At the end of execution, the script will display a summary in the terminal and generate the following files in the current directory:

```bash
File                   ,  Description
plesk-domains.csv      ,  List of domains that correctly point to the configured IPs.
not-plesk-domains.csv  ,  List of domains that DO NOT point to the configured IPs or do not have DNS resolution.
```

## ⚠️ Legal Notice

> [!WARNING]
> This software is provided "as is". Always make sure to test first in a development environment. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## 📚 Detailed Tutorial

For a complete, step-by-step guide, check out my full article:

👉 [**Check Domains On Plesk**](https://perciocastelo.com.br/blog/check-domains-on-plesk.html)

## License 📄

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.
