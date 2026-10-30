# 3. Conectar clientes MCP

URL do servidor para todos os clientes:

```
https://google-ads-mcp.seudominio.com/mcp
```

Nenhum segredo vai na configuração do cliente. No primeiro uso, o cliente abre o navegador para você logar com a conta Google. Com tela de consentimento **Interna**, qualquer conta da sua organização entra; com **Externa + Teste**, só os usuários de teste cadastrados.

| Cliente | Como adicionar | Status |
|---|---|---|
| Claude (web/desktop/mobile) | Conector personalizado com a URL acima | 🔄 a validar |
| Claude Code | `claude mcp add --transport http google-ads https://google-ads-mcp.seudominio.com/mcp` e depois `/mcp` para autenticar | 🔄 a validar |
| Codex CLI | `codex mcp add google_ads --url https://google-ads-mcp.seudominio.com/mcp` e `codex mcp login google_ads` | 📄 documentado pelo Google |
| Antigravity | `"serverUrl": "https://google-ads-mcp.seudominio.com/mcp"` em `mcpServers` | 📄 documentado pelo Google |
| Cursor / VS Code | Servidor MCP do tipo HTTP com a URL acima | 🔄 a validar |
| n8n | Nó *MCP Client Tool* (HTTP Streamable) | 🔄 a validar |

*(A coluna Status será atualizada conforme os testes reais forem concluídos.)*

## Claude

1. Adicione um **conector personalizado** (custom connector) informando a URL `https://google-ads-mcp.seudominio.com/mcp`.
2. Clique em conectar. Você será levado à tela de consentimento do Google.
3. Autorize e volte ao Claude. As tools do Google Ads passam a aparecer na conversa.

## Claude Code

```bash
claude mcp add --transport http google-ads https://google-ads-mcp.seudominio.com/mcp
```

Dentro do Claude Code, rode `/mcp`, escolha `google-ads` e conclua o login no navegador.

## Prompts para testar

```
Quais contas do Google Ads eu consigo acessar?
Quantas campanhas ativas tem a conta 123-456-7890?
Como foi a performance das campanhas da conta 1234567890 nos últimos 7 dias?
Quais campos posso consultar no recurso "campaign"?
```

Dica: informe o **ID da conta** no prompt quando trabalhar com várias contas. Se o acesso for via MCC, garanta que `GOOGLE_ADS_LOGIN_CUSTOMER_ID` está definido ou peça ao assistente para usar o `login_customer_id` da MCC.

Próximo: [4. Solução de problemas](04-solucao-de-problemas.md)
