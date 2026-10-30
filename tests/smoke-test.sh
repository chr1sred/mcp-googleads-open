#!/usr/bin/env bash
# Teste de fumaça / Smoke test — mcp-googleads-open
#
# Modo container (padrão): sobe a imagem com credenciais OAuth FICTÍCIAS e valida
# tudo que dá para validar sem uma conta Google real.
#   IMAGE=mcp-googleads-open:test tests/smoke-test.sh
#
# Modo URL: só os testes HTTP, contra um servidor já rodando (ex.: o seu deploy).
#   MCP_URL=https://google-ads-mcp.seudominio.com tests/smoke-test.sh
#
# Saída: 0 = tudo OK, 1 = alguma falha.

set -euo pipefail

IMAGE="${IMAGE:-mcp-googleads-open:test}"
MCP_URL="${MCP_URL:-}"
PORT="${PORT:-18080}"
NAME="mcp-smoke-$$"
VOLUME="mcp-smoke-data-$$"
FAILS=0

pass() { printf '  \033[32m✔\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✘\033[0m %s\n' "$1"; FAILS=$((FAILS + 1)); }
# check "descrição" comando [args...]  -> roda o comando; sucesso = passou
check() { local msg=$1; shift; if "$@"; then pass "$msg"; else fail "$msg"; fi; }
# contains "texto" "padrão"   |   icontains (sem diferenciar maiúsculas)
contains() { printf '%s' "$1" | grep -q -- "$2"; }
icontains() { printf '%s' "$1" | grep -qi -- "$2"; }
not() { ! "$@"; }

cleanup() {
  if [ -z "$MCP_URL" ]; then
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    docker volume rm "$VOLUME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [ -z "$MCP_URL" ]; then
  BASE="http://127.0.0.1:${PORT}"
  PUBLIC_URL="https://smoke.example.com"
  echo "▶ Subindo container ${IMAGE}"
  docker run -d --name "$NAME" -p "127.0.0.1:${PORT}:8080" \
    -v "${VOLUME}:/data" \
    -e GOOGLE_PROJECT_ID=smoke-project \
    -e GOOGLE_ADS_MCP_OAUTH_CLIENT_ID=smoke.apps.googleusercontent.com \
    -e GOOGLE_ADS_MCP_OAUTH_CLIENT_SECRET=smoke-secret \
    -e GOOGLE_ADS_MCP_BASE_URL="$PUBLIC_URL" \
    -e GOOGLE_ADS_MCP_JWT_SIGNING_KEY=smoke-jwt-signing-key-0123456789 \
    -e GOOGLE_ADS_MCP_STORAGE_ENCRYPTION_KEY=smoke-encryption-key-0123456789 \
    "$IMAGE" >/dev/null

  echo "▶ Aguardando healthcheck"
  STATUS=starting
  for _ in $(seq 1 60); do
    STATUS=$(docker inspect -f '{{.State.Health.Status}}' "$NAME" 2>/dev/null || echo missing)
    [ "$STATUS" = healthy ] && break
    [ "$STATUS" = unhealthy ] && break
    sleep 2
  done
  check "Healthcheck do container = healthy (atual: ${STATUS})" [ "$STATUS" = healthy ]
  if [ "$STATUS" != healthy ]; then
    echo "--- logs do container ---"; docker logs "$NAME" 2>&1 | tail -40
    exit 1
  fi

  echo "▶ Segurança do container"
  UID_IN=$(docker exec "$NAME" id -u)
  check "Roda como usuário não-root (uid=${UID_IN})" [ "$UID_IN" != 0 ]
  check "Volume /data gravável pelo usuário do app" docker exec "$NAME" sh -c "touch /data/.w && rm /data/.w"
else
  BASE="${MCP_URL%/}"
  PUBLIC_URL="$BASE"
fi

echo "▶ Endpoints HTTP (${BASE})"

PRM=$(curl -fsS "${BASE}/.well-known/oauth-protected-resource/mcp" || echo '{}')
RESOURCE=$(printf '%s' "$PRM" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("resource",""))')
check "Metadados do recurso: resource = ${PUBLIC_URL}/mcp" [ "$RESOURCE" = "${PUBLIC_URL}/mcp" ]
check "Escopo adwords anunciado" contains "$PRM" "auth/adwords"

ASM=$(curl -fsS "${BASE}/.well-known/oauth-authorization-server" || echo '{}')
check "Servidor de autorização com registro dinâmico (DCR)" contains "$ASM" registration_endpoint
check "PKCE S256 suportado" contains "$ASM" S256

CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${BASE}/mcp" \
  -H 'content-type: application/json' -H 'accept: application/json, text/event-stream' -d '{}' || true)
check "POST /mcp sem token responde 401 (atual: ${CODE})" [ "$CODE" = 401 ]

WWW=$(curl -s -D - -o /dev/null -X POST "${BASE}/mcp" -H 'content-type: application/json' -d '{}' | tr -d '\r' | grep -i '^www-authenticate' || true)
check "Cabeçalho WWW-Authenticate: Bearer" icontains "$WWW" bearer

if [ -z "$MCP_URL" ]; then
  # Registro dinâmico grava no armazenamento — só no container de teste, nunca no seu deploy.
  DCR=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${BASE}/register" -H 'content-type: application/json' \
    -d '{"redirect_uris":["https://claude.ai/api/mcp/auth_callback"],"client_name":"smoke-test-client","token_endpoint_auth_method":"none","grant_types":["authorization_code","refresh_token"],"response_types":["code"]}' || true)
  check "Registro dinâmico de cliente (callback do Claude) = 201 (atual: ${DCR})" [ "$DCR" = 201 ]

  echo "▶ Armazenamento OAuth"
  FILES=$(docker exec "$NAME" sh -c 'find /data/oauth -type f | wc -l')
  check "Registro persistido em /data/oauth (${FILES} arquivos)" [ "$FILES" -gt 0 ]
  check "Dados criptografados em disco (sem texto puro)" not docker exec "$NAME" grep -rq smoke-test-client /data/oauth

  docker restart "$NAME" >/dev/null
  for _ in $(seq 1 30); do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "$NAME")" = healthy ] && break; sleep 2
  done
  FILES2=$(docker exec "$NAME" sh -c 'find /data/oauth -type f | wc -l')
  check "Dados sobrevivem a reinício (${FILES2} arquivos)" [ "$FILES2" -ge "$FILES" ]
fi

echo
if [ "$FAILS" -eq 0 ]; then
  echo "✅ Todos os testes passaram"
else
  echo "❌ ${FAILS} teste(s) falharam"
  exit 1
fi
