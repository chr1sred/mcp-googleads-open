# 1. Configuração no Google Cloud

Objetivo: ter um **projeto** com a Google Ads API liberada e um **cliente OAuth** que o servidor usará para o login dos usuários.

> Defina antes o subdomínio do servidor (ex.: `gads-mcp.seudominio.com`). Ele entra no redirect URI.

## 1.1 Projeto e API

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/) e crie (ou escolha) um projeto. Anote o **ID do projeto**, que vai em `GOOGLE_PROJECT_ID`.
2. Ative a [Google Ads API](https://console.cloud.google.com/apis/library/googleads.googleapis.com).
3. Na página de visão geral da Google Ads API, confirme o **nível de acesso** do projeto: Explorer, Basic ou Standard. Se não houver nenhum, solicite um.

> Desde 09/09/2026 o Google não exige mais o *developer token*: o nível de acesso fica vinculado ao projeto do Cloud.

## 1.2 Tela de consentimento OAuth (Google Auth Platform)

1. Menu **APIs e serviços → Tela de permissão OAuth** (ou **Google Auth Platform**).
2. Tipo de usuário: **Externo**. Se você usa Google Workspace e todos os usuários são da mesma organização, **Interno** também funciona.
3. Preencha o nome do app (ex.: "MCP Google Ads") e os e-mails de suporte/contato.
4. **Escopos**: não é obrigatório cadastrá-los aqui; o servidor solicita `openid`, `userinfo.email`, `userinfo.profile` e `https://www.googleapis.com/auth/adwords` no login.
5. **Status de publicação: Teste.** Em **Usuários de teste**, adicione cada e-mail que poderá usar o servidor.

### Modo Teste x Produção

| | Teste (recomendado para uso próprio/agência) | Produção |
|---|---|---|
| Quem consegue logar | Só os usuários de teste cadastrados (até 100) | Qualquer conta Google |
| Validade do login | O Google expira o refresh token em ~7 dias: refaça o login semanalmente | Sem expiração forçada |
| Verificação do Google | Não precisa | O escopo `adwords` exige verificação do app |

## 1.3 Cliente OAuth

1. **APIs e serviços → Credenciais → Criar credenciais → ID do cliente OAuth**.
2. Tipo de aplicativo: **Aplicativo da Web**.
3. **URIs de redirecionamento autorizados**: adicione exatamente

   ```
   https://gads-mcp.seudominio.com/auth/callback
   ```

4. Salve e copie o **Client ID** e o **Client secret**, que vão em `GOOGLE_ADS_MCP_OAUTH_CLIENT_ID` e `GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET`.

> Os clientes MCP (Claude etc.) **não** precisam ser cadastrados aqui. Eles se registram sozinhos no seu servidor via registro dinâmico (DCR), e o servidor faz a ponte com o Google.

## 1.4 Conta MCC (opcional)

Se você acessa as contas dos clientes por uma **conta de administrador (MCC)**, defina `GOOGLE_ADS_LOGIN_CUSTOMER_ID` com o ID da MCC, **só números** (ex.: `1234567890`). O assistente também pode informar `login_customer_id` em cada chamada; o valor da chamada tem precedência.

## Checklist

- [ ] `GOOGLE_PROJECT_ID` anotado
- [ ] Google Ads API ativada, com nível de acesso aprovado
- [ ] Tela de consentimento em **Teste**, com seus e-mails como usuários de teste
- [ ] Cliente OAuth "Aplicativo da Web" com redirect `https://SEU-DOMINIO/auth/callback`
- [ ] Client ID e secret guardados

Próximo: [2. Deploy no CapRover](02-caprover.md)
