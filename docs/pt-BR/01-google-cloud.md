# 1. Configuração no Google Cloud

Objetivo: ter um **projeto** com a Google Ads API liberada e um **cliente OAuth** que o servidor usará para o login dos usuários. Tempo estimado: 15 minutos. **Custo: zero.**

> Defina antes o endereço do servidor. No CapRover com DNS curinga, ele é o **nome do app** + seu domínio raiz (ex.: app `google-ads-mcp` → `google-ads-mcp.seudominio.com`). Esse endereço entra no redirect URI.

## Custo: por que é grátis

| Item | Custo |
|---|---|
| Projeto no Google Cloud | Grátis |
| Google Ads API (nível Explorer) | Grátis, até 2.880 operações/dia em contas reais |
| Tela de consentimento + cliente OAuth | Grátis |
| Conta de faturamento | **Não é necessária** |

> **Não vincule faturamento** ao projeto e ignore o banner "Comece gratuitamente / US$ 300". Sem faturamento, não existe forma de haver cobrança.

## 1.1 Projeto

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/) com a conta que acessa suas contas do Google Ads (ou a MCC).
2. **Novo projeto** → nome (ex.: `mcp-google-ads`).
3. Anote o **ID do projeto**, que vai em `GOOGLE_PROJECT_ID`.

> Se o Google recusar um ID legível com "ID não disponível", use o ID gerado automaticamente. Funciona igual.

> **Google Workspace:** em contas de empresa, o projeto é criado dentro da organização (ex.: `suaempresa.com`), e isso não pode ser mudado depois. É o recomendado, por causa da tela de consentimento **Interna** (veja 1.3).

## 1.2 Google Ads API e nível de acesso

1. Ative a [Google Ads API](https://console.cloud.google.com/apis/library/googleads.googleapis.com) no projeto. Ele começa no nível **Teste**, que só acessa contas de teste.
2. Na página da API, clique em **Níveis de acesso → Gerenciar**.
3. Em **Fazer upgrade do nível de acesso → Exploração**, clique em **Inscrever-se para receber acesso**. A aprovação costuma ser **automática, em segundos**.

| Nível | Contas reais | Limite/dia | Precisa? |
|---|---|---|---|
| Teste | ❌ | 15.000 (só teste) | Não basta |
| **Exploração (Explorer)** | ✅ | 2.880 | **Sim, é suficiente** |
| Básico | ✅ | 15.000 | Só para alto volume; exige verificação de marca |
| Standard | ✅ | Ilimitado | Auditoria manual |

> Desde 09/09/2026 o Google não exige mais *developer token*: o nível de acesso fica no projeto do Cloud.

## 1.3 Tela de consentimento (Google Auth Platform)

**APIs e serviços → Tela de permissão OAuth → Vamos começar**:

1. **Informações do app:** nome (ex.: "MCP Google Ads") e e-mail de suporte.
2. **Público:**

   | Tipo | Quando usar | Quem loga | Login expira? |
   |---|---|---|---|
   | **Interno** (recomendado) | Conta Google Workspace | Qualquer pessoa da sua organização | Não |
   | Externo + Teste | Conta Gmail pessoal | Só os "usuários de teste" cadastrados (até 100) | Sim, a cada ~7 dias |

3. **Dados de contato:** seu e-mail.
4. Aceite a política de dados do usuário e clique em **Criar**.

Não é preciso cadastrar escopos: o servidor pede `openid`, `userinfo.email`, `userinfo.profile` e `adwords` no login.

## 1.4 Cliente OAuth

1. **Google Auth Platform → Clientes → Criar cliente**.
2. Tipo: **Aplicativo da Web**. Nome livre (ex.: `mcp-googleads-caprover`).
3. **URIs de redirecionamento autorizados**, exatamente:

   ```
   https://google-ads-mcp.seudominio.com/auth/callback
   ```

4. Deixe desmarcado "Use this client for an AI-powered agent".
5. **Criar.**

> ⚠️ **O Client secret só é exibido uma vez.** Na janela "Cliente OAuth criado", copie o **ID** e o **secret** (ou baixe o JSON) **antes de clicar em OK**. Guarde num gerenciador de senhas, nunca no repositório. Se perder o secret, use **Add secret** no cliente e desative o antigo.

> Os clientes MCP (Claude etc.) **não** são cadastrados aqui. Eles se registram sozinhos no seu servidor (registro dinâmico), e o servidor faz a ponte com o Google.

## 1.5 Conta MCC (opcional)

Se você acessa as contas dos clientes por uma **conta de administrador (MCC)**, defina `GOOGLE_ADS_LOGIN_CUSTOMER_ID` com o ID da MCC, **só números** (ex.: `1234567890`). O assistente também pode informar `login_customer_id` em cada chamada, e o valor da chamada tem precedência.

## Checklist

- [ ] `GOOGLE_PROJECT_ID` anotado
- [ ] Google Ads API ativada com nível **Exploração**
- [ ] Tela de consentimento criada (Interna ou Externa + usuários de teste)
- [ ] Cliente OAuth "Aplicativo da Web" com redirect `https://SEU-APP.SEU-DOMINIO/auth/callback`
- [ ] Client ID e secret guardados em local seguro
- [ ] Nenhuma conta de faturamento vinculada

Próximo: [2. Deploy no CapRover](02-caprover.md)
