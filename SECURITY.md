# Security Policy / Política de Segurança

## Supported Versions / Versões suportadas

| Version | Supported |
| ------- | --------- |
| 1.0.x   | ✅        |
| < 1.0   | ❌        |

## Reporting a Vulnerability / Reportar uma vulnerabilidade

**🇺🇸 Please do not open a public issue for security problems.**

Use GitHub's private reporting: **Security → Report a vulnerability**
(https://github.com/chr1sred/mcp-googleads-open/security/advisories/new).

- You can expect a first response within **7 days** (best effort — this is a community project).
- If confirmed, a fix will be released as a patch version and credited to you in the advisory, unless you prefer to stay anonymous.
- If declined, you will receive an explanation.

**🇧🇷 Não abra issue pública para problemas de segurança.**

Use o reporte privado do GitHub: **Security → Report a vulnerability**
(link acima).

- Primeira resposta em até **7 dias** (melhor esforço — projeto comunitário).
- Se confirmada, a correção sai numa versão de patch, com crédito a você no aviso, a menos que prefira anonimato.
- Se recusada, você recebe a explicação.

## Scope / Escopo

| In scope / Dentro do escopo | Out of scope / Fora do escopo |
| --- | --- |
| Dockerfile, CapRover/nginx configs, scripts, CI workflows and docs of this repository | The MCP server itself (`google-ads-mcp`) → report to [googleads/google-ads-mcp](https://github.com/googleads/google-ads-mcp) / Google VRP |
| Insecure defaults or documentation that leads to exposed credentials | Misconfiguration of your own deployment (e.g. leaked `.env`) |

## Handling secrets / Cuidados com segredos

Never post client secrets, tokens or `.env` contents in issues, discussions or pull requests.
Nunca publique client secrets, tokens ou conteúdo do `.env` em issues, discussões ou pull requests.
