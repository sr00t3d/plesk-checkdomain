# Verificador de Apontamento de Domínios (Plesk)

Readme: [English](README.md)

![License](https://img.shields.io/github/license/sr00t3d/plesk-checkdomain)
![PHP Script](https://img.shields.io/badge/javascript-script-green)

Este script em Bash foi desenvolvido para auditar e verificar em massa se uma lista de domínios (extraída do Plesk ou fornecida manualmente) está apontando corretamente para os endereços IP de um servidor de destino.

O script resolve o DNS de cada domínio externamente (usando Google DNS 8.8.8.8 para evitar cache local), compara com uma lista de IPs autorizados e gera relatórios em CSV.

## 🚀 Funcionalidades

- Extração Automática: Se não houver uma lista prévia, o script extrai automaticamente todos os domínios do banco de dados do Plesk (plesk db).
- Verificação DNS Externa: Utiliza o dig apontando para o DNS do Google, garantindo que a propagação seja verificada externamente.
- Feedback Visual: Possui uma barra de progresso em tempo real para acompanhar o processamento de grandes listas.
- Relatórios CSV: Gera dois arquivos separados (separados por ponto e vírgula ;) para facilitar a importação no Excel:
- Domínios com apontamento correto.
- Domínios com apontamento incorreto ou sem IP.

## 📋 Pré-requisitos

- Sistema Operacional Linux (compatível com servidores Plesk).
- Acesso root ou permissão para executar comandos do Plesk (plesk db) e dig.
- Pacote bind-utils ou dnsutils instalado (para o comando dig).

## ⚙️ Configuração

Antes de executar, verifique a variável de IPs no início do script para garantir que correspondem à infraestrutura atual:

```bash
# Lista de IPs da Andamento (ajuste aqui os IPs corretos)
ANDAMENTO_IPS=("IP")
```

_Você pode adicionar múltiplos IPs separando-os por espaço dentro dos parênteses._

## ▶️ Como Usar

**1. Instalação:**

Salve o script no servidor, por exemplo, como plesk-checkdomains.sh.

**2. Permissão de Execução:**

```bash
chmod +x plesk-checkdomains.sh
```

**3. Execução:**

```bash
./check_domains.sh
```

## Comportamento da Lista de Domínios

- **Primeira Execução**: O script procurará pelo arquivo dominio-andamento.txt. Se não encontrar, ele executará o comando do Plesk para gerar a lista base.
- **Execuções Seguintes**: Se o arquivo dominio-andamento.txt já existir, o script usará essa lista estática. Para forçar uma nova leitura do Plesk, remova este arquivo (rm dominio-andamento.txt) antes de rodar o script.

## 📂 Saída (Outputs)

Ao final da execução, o script exibirá um resumo no terminal e gerará os seguintes arquivos no diretório atual:

```bash
Arquivo                ,  Descrição
plesk-domains.csv      ,  Lista de domínios que apontam corretamente para os IPs configurados.
not-plesk-domains.csv  ,  Lista de domínios que NÃO apontam para os IPs configurados ou não possuem resolução DNS.
```

## ⚠️ Aviso Legal

> [!WARNING]
> Este software é fornecido "no estado em que se encontra". Certifique-se sempre de testar primeiro em um ambiente de desenvolvimento. O autor não se responsabiliza por qualquer uso indevido, consequências legais ou impacto em dados causados por esta ferramenta.

## 📚 Tutorial Detalhado

Para um guia completo, passo a passo, confira meu artigo completo:

👉 [**Verificar Domínios Apontando para o Plesk**](https://perciocastelo.com.br/blog/check-domains-pointing-to-plesk.html)

## Licença 📄

Este projeto está licenciado sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
