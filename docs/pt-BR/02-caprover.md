# 2. Deploy no CapRover

## 2.1 Endereço (DNS)

| Seu CapRover | O que fazer |
|---|---|
| **DNS curinga** (`*.seudominio.com` → VPS), o padrão do CapRover | Nada. O app ganha `NOME-DO-APP.seudominio.com` automaticamente. Para usar `google-ads-mcp.seudominio.com`, basta o app se chamar `google-ads-mcp`. |
| Domínio fora do curinga | Crie um registro **A** apontando para o IP da VPS e use **Conectar Novo Domínio** (passo 2.4). Com Cloudflare, deixe o proxy laranja desligado até o certificado sair. |

> Use **o mesmo endereço** em três lugares: redirect URI do Google, `GOOGLE_ADS_MCP_BASE_URL` e URL dos clientes MCP.

## 2.2 Criar o app

1. **Apps → Criar Um Novo App**.
2. Marque **Possui Dados Persistentes** (é o que guarda os logins OAuth).
3. Nome: `google-ads-mcp` → **Criar Novo App**.

## 2.3 Configurações do App

**Variáveis de Ambiente** (ligue a *Edição em Massa*):

```env
GOOGLE_PROJECT_ID=seu-projeto-gcp
GOOGLE_ADS_MCP_BASE_URL=https://google-ads-mcp.seudominio.com
GOOGLE_ADS_MCP_OAUTH_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET=GOCSPX-...
GOOGLE_ADS_MCP_JWT_SIGNING_KEY=...
GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY=...
```

Sem espaços em volta do `=` e sem aspas. Opcional: `GOOGLE_ADS_LOGIN_CUSTOMER_ID=` (ID da MCC, só números).

Gere as duas chaves no seu computador (não precisa clonar o repositório):

```bash
python3 -c "import secrets,base64;print('GOOGLE_ADS_MCP_JWT_SIGNING_KEY='+secrets.token_urlsafe(48));print('GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY='+base64.urlsafe_b64encode(secrets.token_bytes(32)).decode())"
```

Guarde as chaves junto com o client secret. Se mudarem, todos os logins precisam ser refeitos.

**Diretórios Persistentes** → Adicionar:

| Caminho no App | Rótulo |
|---|---|
| `/data` | `google-ads-mcp-data` |

**Contagem de instâncias:** mantenha **1** (o armazenamento em disco não é compartilhado).

**Salvar & Reiniciar.**

## 2.4 Configurações HTTP

1. **Habilitar HTTPS** (emite o certificado Let's Encrypt na hora).
2. **Porta HTTP do Contêiner:** `8080`.
3. Marque **Forçar HTTPS redirecionando todo o tráfego HTTP para HTTPS**.
4. **Editar Configurações Padrão do Nginx.** O template tem **dois** blocos `location /`. Use o **segundo** (o que tem `proxy_pass $upstream;`) e cole as linhas de [`caprover/nginx-location.conf`](../../caprover/nginx-location.conf) **logo abaixo** de `proxy_set_header X-Forwarded-Proto $scheme;`:

   ```nginx
   proxy_buffering off;
   proxy_cache off;
   proxy_read_timeout 3600s;
   proxy_send_timeout 3600s;
   chunked_transfer_encoding on;
   ```

   Não altere as áreas entre `<% ... %>`. Sem essas linhas, as respostas em streaming (SSE) do MCP podem travar.

5. Deixe **Suporte a Websocket** desligado (o MCP não usa).
6. **Salvar & Reiniciar.**

## 2.5 Deploy

### Método 6: imagem pronta (mais rápido)

Aba **Implantação → Método 6: Implantar via ImageName** → `ghcr.io/chr1sred/mcp-googleads-open:1.0.0` → **Implantar Agora**.

Sem build na VPS, sem token. Para atualizar, troque a versão e implante de novo. Prefira uma versão fixa (`1.0.0`) a `latest`, para saber exatamente o que está rodando.

### Método 3: GitHub (build na VPS)

> ⚠️ O CapRover **não salva** o Método 3 com usuário e senha vazios, **mesmo para repositório público**. É preciso um token.

1. No GitHub: **Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token**.
   - **Não marque nenhum escopo.** Para repositório público, um token sem escopos já permite clonar e não dá permissão de escrita em nada.
   - Validade: 90 dias (renove depois).
2. No CapRover, aba **Implantação → Método 3**:

   | Campo | Valor |
   |---|---|
   | Repository | `github.com/SEU-USUARIO/mcp-googleads-open` |
   | Branch | `main` (ou a branch que quiser) |
   | Username | seu usuário do GitHub |
   | Password | o token |

3. **Salvar & Reiniciar.** O webhook aparece e o botão **Forçar build** é liberado.
4. **Forçar build.** O primeiro build leva de 2 a 4 minutos. Acompanhe em **Ver Logs de Build**.
5. Opcional: cole o webhook do CapRover no GitHub (Settings → Webhooks) para redeploy automático a cada push.

### Outros métodos

| Método | Quando usar |
|---|---|
| Método 3 (acima) | Você fez um fork e quer deploy automático a cada push |
| CLI (`caprover deploy -a google-ads-mcp`) | Você já usa o CLI do CapRover |
| Tarball | Sem token: baixe o ZIP do GitHub, converta para `.tar` e envie |

## 2.6 Teste rápido

```bash
# 200 com JSON (metadados OAuth)
curl https://google-ads-mcp.seudominio.com/.well-known/oauth-protected-resource/mcp

# 401 = endpoint protegido: OK!
curl -i -X POST https://google-ads-mcp.seudominio.com/mcp
```

O campo `resource` do primeiro comando deve ser `https://google-ads-mcp.seudominio.com/mcp`. Se aparecer `localhost`, a variável `GOOGLE_ADS_MCP_BASE_URL` não foi aplicada.

> Abrir `/mcp` no navegador mostra uma página de erro: é o 401 esperado, não um problema.

## 2.7 Atualização

1. Altere `ARG GOOGLE_ADS_MCP_VERSION=` no `Dockerfile` e faça push (ou **Forçar build**).
2. Os logins continuam válidos enquanto o volume `/data` e as duas chaves forem mantidos.

## 2.8 Trocar segredos (rotação)

1. Gere chaves novas com o comando do passo 2.3.
2. No Google Cloud, no cliente OAuth: **Add secret** → copie o novo → desative e exclua o antigo.
3. Atualize as 3 variáveis no CapRover → **Salvar & Reiniciar**. Os usuários precisam logar de novo.

Próximo: [3. Conectar clientes MCP](03-clientes-mcp.md)
