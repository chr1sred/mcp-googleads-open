# mcp-googleads-open
# Imagem de deploy self-hosted do servidor MCP oficial do Google Ads
# (https://github.com/googleads/google-ads-mcp), pronta para CapRover/Docker.

FROM python:3.12-slim

# Versão do servidor oficial publicada no PyPI. Atualize aqui (ou via build-arg
# no CapRover) e faça redeploy para subir de versão.
ARG GOOGLE_ADS_MCP_VERSION=0.0.5

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8080 \
    GOOGLE_ADS_MCP_STORAGE_TYPE=filetree \
    GOOGLE_ADS_MCP_STORAGE_PATH=/data/oauth

RUN pip install "google-ads-mcp==${GOOGLE_ADS_MCP_VERSION}" \
    && useradd --create-home --uid 10001 mcp \
    && mkdir -p /data/oauth \
    && chown -R mcp:mcp /data

COPY --chown=mcp:mcp scripts/healthcheck.py /usr/local/bin/healthcheck.py

USER mcp
WORKDIR /home/mcp

# Tokens OAuth (criptografados) ficam aqui. Mapeie para um volume persistente.
VOLUME ["/data"]

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ["python", "/usr/local/bin/healthcheck.py"]

CMD ["google-ads-mcp"]
