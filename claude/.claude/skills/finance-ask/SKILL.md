---
name: finance-ask
description: Answer questions about personal finances by searching only the ~/vault/finance/ section of the Obsidian vault. Use when the user asks "quanto gastei", "como estou em [mês]", "qual minha despesa fixa", "posso gastar X", "forecast", "carteira", "minha situação financeira", or any question about their money, bills, cards, or investments.
---

# finance-ask

Responde perguntas sobre finanças pessoais lendo **apenas** `~/vault/finance/`. Não mistura com outras pastas do vault.

## Quando disparar

Gatilhos: "quanto gastei", "qual minha despesa", "fatura de [mês]", "como está meu forecast", "posso gastar", "quanto sobra", "minha parcela futura", "carteira", "minhas contas de [mês]", "minha situação financeira", "quanto tenho pra gastar", "próximo mês".

## Escopo duro

- Fonte única de verdade: `~/vault/finance/`.
- Se a resposta depende de dado ausente, responder que precisa rodar `finance-update` primeiro.
- Nunca alucinar valores. Se `parameters.md` está defasado, avisar antes de responder.
- Nunca escrever. Só ler.

## Fluxo

### 1. Reindexar vault (apenas se necessário)
```bash
qmd update -c vault && qmd embed 2>/dev/null
```

### 2. Buscar apenas dentro de `~/vault/finance/`
```bash
qmd query -c vault "termo de busca" -n 10 2>&1 | head -50
```
Filtrar resultados fora de `finance/`. Ou usar rg direto:
```bash
rg -l "termo" ~/vault/finance/ --type md
```

### 3. Ordem de leitura por tipo de pergunta

- **Valor corrente / taxa / custo** → `parameters.md` primeiro.
- **Mês específico** → `months/YYYY-MM.md`.
- **Projeção futura** → `forecasts/{6m,12m}-YYYY-MM.md` mais recente.
- **Insight estratégico** → `snapshots/YYYY-MM-resumo.md`.
- **Investimentos** → `investments/*.md`.
- Se faltar contexto, ler também `README.md` pra identificar o que existe.

### 4. Formato de resposta

- **Número direto no topo** (resposta direta à pergunta).
- Contexto curto (1-3 linhas).
- Tabela quando há comparação ou múltiplos itens.
- Link Obsidian pro arquivo consultado (`Ver [[months/YYYY-MM]]`).

### 5. Padrões comuns

**"Posso gastar R$ X?"**
- Ler mês atual + forecast 6m + `parameters.md`.
- Calcular impacto: cabe no teto do cartão? afeta aportes de longo prazo?
- Responder: sim/não/depende, com justificativa curta.

**"Como estou em relação ao objetivo de longo prazo?"**
- Ler forecasts mais recentes + investimentos.
- Comparar acumulado vs alvo registrado em `parameters.md`.

**"Quanto sobra este mês?"**
- Ler `months/YYYY-MM.md` atual.
- Se mês em aberto, estimar com base em fixas + cartões parciais.

### 6. Nunca

- ❌ Fazer cálculo sem ler `parameters.md`.
- ❌ Inventar valor.
- ❌ Ler/escrever fora de `~/vault/finance/`.
- ❌ Usar notas de outras pastas (`inbox/`, `projects/`, etc).
- ❌ Rodar script ou modificar arquivos (isso é `finance-update`).

### Leitura auxiliar permitida
- `~/.finance/planilha.py` — pode **ler** se `parameters.md` estiver incompleto, mas nunca editar. Nunca escrever em `~/.finance/`.

## Voz / estilo

- Português informal, direto.
- Valores no padrão brasileiro (R$ 1.234,56).
- Resposta objetiva — entregar o número antes de explicar.
- Emoji só em header/status (✅ ⚠️ ❌).
- Nunca mencionar AI/Claude.

## Exemplos de pergunta → fluxo

### "Quanto gastei em [mês]?"
1. `ls ~/vault/finance/months/`
2. Ler `months/YYYY-MM.md`
3. Responder: total saídas + breakdown por bloco (entradas, fixas, cartões, pix, etc).

### "Posso gastar R$ X em Y?"
1. Ler `months/{atual}.md` pra ver cartão em curso.
2. Ler `parameters.md` pra metas.
3. Ler `forecasts/6m-{mais recente}.md` pra impacto futuro.
4. Responder: cabe / não cabe / cabe com ajuste.

### "Minha carteira"
1. `ls ~/vault/finance/investments/`
2. Ler arquivos relevantes.
3. Listar posições + última atualização.

### "Impacto de [evento] no plano de [objetivo]"
1. Ler `forecasts/12m-{mais recente}.md`.
2. Isolar meses relevantes.
3. Mostrar projeção e alertas.
