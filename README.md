# mcp-googleads-open

🇧🇷 Português | [🇺🇸 English](README.en-US.md)

Deploy **self-hosted** do [servidor MCP oficial do Google Ads](https://github.com/googleads/google-ads-mcp) em VPS com **CapRover** (ou Docker Compose), com HTTPS, login OAuth e tokens persistentes e criptografados.

Com ele, assistentes de IA compatíveis com MCP (Claude, Claude Code, Codex, Cursor, Antigravity etc.) consultam suas contas do Google Ads em linguagem natural: *"Como foi a performance das campanhas desta semana?"*.

> Este projeto **não modifica** o servidor do Google. Ele empacota a versão oficial publicada no PyPI, fixada no `Dockerfile`, e adiciona tudo o que falta para rodar em produção numa VPS própria.

## Por que self-hosted?

| | Local (stdio, padrão do Google) | Cloud Run (guia oficial) | **Este projeto (VPS + CapRover)** |
|---|---|---|---|
| Onde roda | No seu computador | Google Cloud | Sua VPS |
| Usar em vários dispositivos/agentes | ❌ | ✅ | ✅ |
| Funciona como conector remoto no Claude | ❌ | ✅ | ✅ |
| Credenciais fora da config do cliente | ❌ | ✅ | ✅ |
| Custo | Zero | Pago por uso + Firestore/Redis | Já incluso na VPS |
| Persistência dos logins | n/a | Firestore ou Redis | Volume em disco, criptografado |

## O que o servidor faz

Modo **somente leitura** (versão atual do Google):

| Tool | Para quê |
|---|---|
| `customers_list_accessible_customers` | Lista as contas que o seu login acessa |
| `search_search` | Consulta dados via GAQL (campanhas, métricas, orçamentos, status) |
| `metadata_get_resource_metadata` | Mostra os campos disponíveis de um recurso (ex.: `campaign`) |

Também expõe como *resources*: discovery document, métricas, segmentos e release notes da Google Ads API.

## Arquitetura

```
Cliente MCP (Claude, Claude Code...)
        │  HTTPS  /mcp  (OAuth 2.1 + registro dinâmico)
        ▼
CapRover (nginx + Let's Encrypt)
        │  HTTP 8080
        ▼
Container google-ads-mcp (FastMCP OAuth Proxy)
        │  volume /data → tokens OAuth criptografados
        ▼
Google OAuth  +  Google Ads API
```

Cada pessoa faz login com a própria conta Google e só enxerga as contas do Google Ads a que já tem acesso.

## Requisitos

- VPS com CapRover (testado como referência: 3 vCPU, 3 GB RAM + swap; o processo usa ~170 MB)
- Um subdomínio apontando para a VPS (no CapRover com DNS curinga, é o próprio nome do app: `google-ads-mcp.seudominio.com`)
- Projeto no Google Cloud com a **Google Ads API** ativada no nível **Explorer** (grátis, sem faturamento)
- Conta Google com acesso às contas do Google Ads (direto ou via MCC)

## Início rápido

1. **Google Cloud** → crie o cliente OAuth e configure a tela de consentimento: [docs/pt-BR/01-google-cloud.md](docs/pt-BR/01-google-cloud.md)
2. **Segredos** → `python3 scripts/gen-secrets.py`
3. **CapRover** → crie o app, volume, variáveis, domínio e ajuste do nginx: [docs/pt-BR/02-caprover.md](docs/pt-BR/02-caprover.md)
4. **Clientes MCP** → conecte o Claude, Claude Code e outros em `https://SEU-DOMINIO/mcp`: [docs/pt-BR/03-clientes-mcp.md](docs/pt-BR/03-clientes-mcp.md)
5. Problemas? [docs/pt-BR/04-solucao-de-problemas.md](docs/pt-BR/04-solucao-de-problemas.md)

Sem CapRover? Use o [`docker-compose.yml`](docker-compose.yml) atrás de qualquer proxy reverso com HTTPS (Traefik, Caddy, nginx).

## Variáveis de ambiente

| Variável | Obrigatória | Descrição |
|---|---|---|
| `GOOGLE_PROJECT_ID` | ✅ | ID do projeto no Google Cloud |
| `GOOGLE_ADS_MCP_OAUTH_CLIENT_ID` | ✅ | Client ID do OAuth (tipo "Aplicativo da Web") |
| `GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET` | ✅ | Client secret do OAuth |
| `GOOGLE_ADS_MCP_BASE_URL` | ✅ | URL pública, sem `/mcp` e sem barra final |
| `GOOGLE_ADS_MCP_JWT_SIGNING_KEY` | ✅ | Chave fixa para os logins sobreviverem a redeploys |
| `GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY` | ✅ | Criptografa os tokens salvos em disco |
| `GOOGLE_ADS_LOGIN_CUSTOMER_ID` | — | ID da MCC (só números) como padrão |
| `GOOGLE_ADS_DEVELOPER_TOKEN` | — | Descontinuado pelo Google em 09/2026; deixe vazio |
| `GOOGLE_ADS_MCP_TOOLS_CONFIG` | — | Caminho de um `tools_config.yaml` para ligar/desligar tools |

Modelo completo em [`.env.example`](.env.example).

## Atualizando o servidor do Google

Altere `GOOGLE_ADS_MCP_VERSION` no [`Dockerfile`](Dockerfile) para a versão desejada do [PyPI](https://pypi.org/project/google-ads-mcp/) e faça redeploy. Os logins são mantidos enquanto o volume e as chaves não mudarem.

## Segurança

- O endpoint é público, mas **toda chamada exige login OAuth**.
- Quem pode logar é definido no Google: tela de consentimento **Interna** (só a sua organização Workspace) ou **Externa em Teste** (só os usuários de teste cadastrados).
- Os tokens ficam criptografados (Fernet) no volume `/data`. Nunca faça commit do `.env` nem de JSON de credenciais.
- O container roda como usuário não-root.

## Créditos e licença

- Servidor MCP: [googleads/google-ads-mcp](https://github.com/googleads/google-ads-mcp), © Google LLC, Apache-2.0.
- Este repositório: Apache-2.0, veja [LICENSE](LICENSE) e [NOTICE](NOTICE).

Projeto independente, sem afiliação com o Google. "Google Ads" é marca registrada da Google LLC.
