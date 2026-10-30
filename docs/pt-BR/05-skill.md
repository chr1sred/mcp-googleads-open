# 5. Skill `google-ads-analyst` para o Claude

O servidor MCP dá ao Claude **acesso** às contas (as "mãos"). A skill ensina o Claude **como** analisar bem (o "manual").

| | Sem a skill | Com a skill |
|---|---|---|
| Encontrar a conta | Consulta conta por conta | Acha a MCC e lista tudo em **1 operação** |
| Consultas GAQL | Tenta adivinhar campos, gasta cota com erros | Usa **13 receitas validadas** em conta real |
| Valores | Pode mostrar custo em *micros* ou QS "0" | Converte moeda, %, "sem nota", N/A |
| Relatório | Formato livre | Resumo, tabela, destaques, pontos de atenção e próximos passos, em PT-BR ou EN |
| Cota (2.880/dia) | Sem cuidado | Consultas largas, `limit`, sem repetição |

## Requisitos

- O conector deste projeto já funcionando (guias 1 a 3).
- Claude nos planos **Pro, Max, Team ou Enterprise**, com **execução de código** ativada.

## Instalação

1. Baixe o **`google-ads-analyst.zip`** na [última release](https://github.com/chr1sred/mcp-googleads-open/releases/latest).
2. No Claude: **Settings → Capabilities → Skills → Upload skill** e envie o ZIP.
3. Ative a skill e confira se o conector do Google Ads também está ativado na conversa.

> Em planos Team e Enterprise, o owner da organização pode disponibilizar a skill para todos.

> Como em qualquer skill de terceiros, leia o conteúdo antes de instalar. São só dois arquivos Markdown, sem código executável: [`SKILL.md`](../../skills/google-ads-analyst/SKILL.md) e [`references/gaql-recipes.md`](../../skills/google-ads-analyst/references/gaql-recipes.md).

## Exemplos de uso

```
Quais contas eu tenho na MCC e quais estão ativas?
Como foi a conta X nos últimos 30 dias? Quero o relatório completo.
Compare outubro com setembro na conta X.
Quais termos de pesquisa gastaram sem converter? Sugira negativas.
Quais campanhas estão perdendo parcela de impressões por orçamento?
Quem mexeu na conta X nas últimas duas semanas e o que mudou?
```

## Personalizar

Faça um fork e edite o `SKILL.md`, por exemplo para incluir as metas de CPA dos seus clientes ou o seu modelo de relatório. Depois empacote com:

```bash
scripts/package-skill.sh   # gera dist/google-ads-analyst.zip
```

Valide antes de empacotar:

```bash
python3 tests/validate-skill.py
```
