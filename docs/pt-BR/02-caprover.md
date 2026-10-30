# 2. Deploy no CapRover

## 2.1 DNS

Crie um registro **A** do subdomínio (ex.: `gads-mcp.seudominio.com`) apontando para o IP da VPS. Se usar Cloudflare, deixe o proxy laranja **desligado** até o certificado ser emitido.

## 2.2 Criar o app

1. No painel do CapRover: **Apps → Create a New App**.
2. Nome: `google-ads-mcp`.
3. Marque **Has Persistent Data** (é o que guarda os logins OAuth).

## 2.3 App Configs

**Environment Variables** (modo *Bulk Edit*), baseado no [`.env.example`](../../.env.example):

```env
GOOGLE_PROJECT_ID=seu-projeto-gcp
GOOGLE_ADS_MCP_OAUTH_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET=GOCSPX-...
GOOGLE_ADS_MCP_BASE_URL=https://gads-mcp.seudominio.com
GOOGLE_ADS_MCP_JWT_SIGNING_KEY=...
GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY=...
GOOGLE_ADS_LOGIN_CUSTOMER_ID=
```

Gere as duas chaves com:

```bash
python3 scripts/gen-secrets.py
```

**Persistent Directories**:

| Path in App | Label |
|---|---|
| `/data` | `google-ads-mcp-data` |

**Instance Count**: mantenha **1**. O armazenamento em disco não é compartilhado entre instâncias.

Clique em **Save & Update**.

## 2.4 HTTP Settings

1. **Container HTTP Port**: `8080`.
2. **Connect New Domain**: `gads-mcp.seudominio.com`.
3. **Enable HTTPS** e depois **Force HTTPS by redirecting all HTTP traffic to HTTPS**.
4. **Edit Default Nginx Configurations**: dentro do bloco `location / { ... }`, adicione as linhas de [`caprover/nginx-location.conf`](../../caprover/nginx-location.conf):

   ```nginx
   proxy_buffering off;
   proxy_cache off;
   proxy_read_timeout 3600s;
   proxy_send_timeout 3600s;
   chunked_transfer_encoding on;
   ```

   Sem isso, as respostas em streaming (SSE) do MCP podem travar ou cair.

5. **Save & Update**.

## 2.5 Deploy

Escolha um método na aba **Deployment**:

| Método | Como |
|---|---|
| **GitHub (recomendado)** | Method 3: repositório `https://github.com/SEU-USUARIO/mcp-googleads-open`, branch `main` (ou `master`), usuário + token do GitHub. Opcionalmente cole o webhook do CapRover no GitHub para deploy automático a cada push. |
| **CLI** | Na pasta do repositório: `caprover deploy -a google-ads-mcp` |
| **Tarball** | Compacte o repositório (`.tar`) e envie pelo painel |

O CapRover lê o `captain-definition`, faz o build do `Dockerfile` e sobe o container.

## 2.6 Teste rápido

```bash
# Deve responder 200 com JSON (metadados OAuth)
curl https://gads-mcp.seudominio.com/.well-known/oauth-protected-resource/mcp

# Deve responder 401 (endpoint protegido: OK!)
curl -i https://gads-mcp.seudominio.com/mcp
```

Confira se a URL do campo `resource` no primeiro comando é `https://gads-mcp.seudominio.com/mcp`. Se aparecer `localhost`, a variável `GOOGLE_ADS_MCP_BASE_URL` não foi aplicada.

## 2.7 Atualização

1. Altere `ARG GOOGLE_ADS_MCP_VERSION=` no `Dockerfile`.
2. Faça push (ou redeploy). Os logins continuam válidos enquanto o volume `/data` e as duas chaves forem mantidos.

Próximo: [3. Conectar clientes MCP](03-clientes-mcp.md)
