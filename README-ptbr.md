# Verificador de Apontamento de Domínios (Plesk)

Readme: [English](README.md)

![License](https://img.shields.io/github/license/sr00t3d/plesk-checkdomain)
![Bash Script](https://img.shields.io/badge/bash-script-green)

<img width="700" src="plesk-checkdomains-cover.webp" />

Este script em Bash foi desenvolvido para auditar e verificar em massa se uma lista de domínios (extraída do Plesk ou fornecida manualmente) está apontando corretamente para os endereços IP de um servidor de destino.

O script resolve o DNS de cada domínio externamente (usando Google DNS 8.8.8.8
para evitar cache local), compara com uma lista de IPs autorizados, gera
relatórios CSV, adiciona relatório TXT incremental por execução e envia um
resumo por e-mail.

## 🚀 Funcionalidades

- Extração Automática: Se não houver uma lista prévia, o script extrai automaticamente todos os domínios do banco de dados do Plesk (plesk db).
- Verificação DNS Externa: Utiliza o dig apontando para o DNS do Google, garantindo que a propagação seja verificada externamente.
- Feedback Visual: Possui uma barra de progresso em tempo real para acompanhar o processamento de grandes listas.
- Relatórios CSV: Gera dois arquivos separados (separados por ponto e vírgula ;) para facilitar a importação no Excel:
- Domínios com apontamento correto.
- Domínios com apontamento incorreto ou sem IP.
- Relatório TXT incremental: Adiciona cada execução em um arquivo persistente.
- Resumo por e-mail: Envia apenas o trecho da execução atual.

## 📋 Pré-requisitos

- Sistema Operacional Linux (compatível com servidores Plesk).
- Acesso root ou permissão para executar comandos do Plesk (plesk db) e dig.
- Pacote bind-utils ou dnsutils instalado (para o comando dig).
- Comando `mail` configurado no servidor (mailx / mailutils).

## ⚙️ Configuração

Antes de executar, ajuste as variáveis no início do script:

```bash
DIRECTORY_REPORTS="/opt/suporte/relatorios"
FILE_REPORT="$DIRECTORY_REPORTS/plesk-relatorio-dominios.txt"
DESTINY_MAIL="mail@domain.tld"
PLESK_IPS=("SERVER_IP_1")
```

Você pode adicionar múltiplos IPs separando por espaço em `PLESK_IPS=(...)`.

## ▶️ Como Usar

**1. Instalação:**

Salve o script no servidor, por exemplo, como plesk-checkdomains.sh.

**2. Permissão de Execução:**

```bash
chmod +x plesk-checkdomains.sh
```

**3. Execução:**

```bash
./plesk-checkdomains.sh
```

## Comportamento da Lista de Domínios

- **Primeira execução**: O script procura por `plesk-domains.txt`. Se não
  encontrar, executa o comando do Plesk para gerar a lista base.
- **Execuções seguintes**: Se `plesk-domains.txt` já existir, o script usa essa
  lista estática. Para forçar nova leitura do Plesk, remova
  `plesk-domains.txt` antes de executar novamente.

## 📂 Saída (Outputs)

Ao final da execução, o script exibe progresso/status e gera:

```bash
Arquivo                ,  Descrição
plesk-domains.csv      ,  Lista de domínios que apontam corretamente para os IPs configurados.
not-plesk-domains.csv  ,  Lista de domínios que NÃO apontam para os IPs configurados ou não possuem resolução DNS.
/opt/suporte/relatorios/plesk-relatorio-dominios.txt , Relatório incremental de execução (acumulado a cada rodada).
```

## ⚠️ Aviso Legal

> [!WARNING]
> Este software é fornecido "no estado em que se encontra". Certifique-se sempre de testar primeiro em um ambiente de desenvolvimento. O autor não se responsabiliza por qualquer uso indevido, consequências legais ou impacto em dados causados por esta ferramenta.

## 📚 Tutorial Detalhado

Para um guia completo, passo a passo, confira meu artigo completo:

👉 [**Verificar Domínios Apontando para o Plesk**](https://perciocastelo.com.br/blog/check-domains-pointing-to-plesk.html)

## Licença 📄

Este projeto está licenciado sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
