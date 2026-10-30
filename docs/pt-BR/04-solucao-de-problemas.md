# 4. Solução de problemas

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Erro 400: redirect_uri_mismatch` no login Google | Redirect URI diferente do cadastrado | Cadastre exatamente `https://SEU-DOMINIO/auth/callback` (https, sem barra final) no cliente OAuth |
| `Acesso bloqueado: app não concluiu a verificação` | Seu e-mail não é usuário de teste | Adicione o e-mail em **Usuários de teste** na tela de consentimento |
| Metadados mostram `localhost:8080` | `GOOGLE_ADS_MCP_BASE_URL` ausente ou errado | Defina a URL pública e faça *Save & Update* |
| Precisa logar de novo toda semana | App OAuth em modo **Teste** (refresh token de ~7 dias) | Comportamento esperado em Teste; publique em Produção (requer verificação) se precisar evitar |
| Precisa logar de novo após cada deploy | Volume `/data` não persistente ou chaves trocadas | Marque *Has Persistent Data*, mapeie `/data` e mantenha `JWT_SIGNING_KEY` e `STORAGE_ENCRYPTION_KEY` fixos |
| Conexão cai ou trava nas respostas | Buffer do nginx no SSE | Aplique [`caprover/nginx-location.conf`](../../caprover/nginx-location.conf) |
| `USER_PERMISSION_DENIED` / conta não acessível | Acesso via MCC sem `login-customer-id` | Defina `GOOGLE_ADS_LOGIN_CUSTOMER_ID` (só números) ou informe a MCC no prompt |
| `The developer token is only approved for use with test accounts` | Nível de acesso insuficiente | Solicite Explorer/Basic na página da Google Ads API do projeto |
| Container reinicia em loop | Variável obrigatória faltando ou chave inválida | Veja os logs do app no CapRover; gere chaves novas com `scripts/gen-secrets.py` |
| `/mcp` responde **401** no navegador/curl | Comportamento correto | O endpoint exige token; use um cliente MCP |

## Comandos úteis

```bash
# Metadados (precisa responder 200)
curl https://SEU-DOMINIO/.well-known/oauth-protected-resource/mcp
curl https://SEU-DOMINIO/.well-known/oauth-authorization-server

# Logs do serviço no host do CapRover
docker service logs srv-captain--google-ads-mcp --tail 100 -f
```

## Reportar problemas

- Problema de deploy/documentação deste projeto: abra uma *issue* aqui.
- Problema no servidor MCP em si (tools, consultas): [googleads/google-ads-mcp/issues](https://github.com/googleads/google-ads-mcp/issues).
