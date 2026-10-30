# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Não lançado / Unreleased]

### Adicionado / Added
- Dockerfile empacotando `google-ads-mcp==0.0.5` (PyPI), usuário não-root, volume `/data` e healthcheck.
- `captain-definition` para deploy no CapRover.
- `docker-compose.yml` como alternativa sem CapRover.
- Ajustes de nginx para Streamable HTTP/SSE (`caprover/nginx-location.conf`).
- `scripts/gen-secrets.py` para gerar a chave JWT e a chave de criptografia dos tokens.
- Documentação completa em PT-BR e EN-US.
