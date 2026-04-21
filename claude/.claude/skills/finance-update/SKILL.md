---
name: finance-update
description: Process credit card bills, bank statements, or screenshots, extract expenses, update current month snapshot and 6/12-month forecasts in the Obsidian finance vault. Use when the user shares faturas, extratos, prints, or asks to "atualizar finanças", "processar contas", "atualiza fatura", "roda forecast", "atualiza mês". Writes ONLY to ~/vault/finance/.
---

# finance-update

Processa faturas de cartão, extratos bancários e prints. Extrai gastos, atualiza o mês corrente, refaz forecasting 6m e 12m. Escreve **sempre e apenas** em `~/vault/finance/`.

## Quando disparar

Gatilhos: "atualiza finanças", "processa fatura", "atualiza contas", "fatura de [mês]", "extrato do mês", "atualiza forecast", "roda planilha", "fechei o mês", "processa este PDF", "processa estes prints", ou sempre que o usuário compartilhar PDFs de fatura/extrato.

## Escopo duro

**Nunca escreva fora de `~/vault/finance/`.** Se o usuário pedir pra salvar algo fora, recuse e redirecione.

Estrutura obrigatória:
```
~/vault/finance/
├── README.md              (índice — atualizar lista de meses/forecasts)
├── parameters.md          (params que alimentam o forecast — ler antes de rodar)
├── months/YYYY-MM.md      (snapshot mensal)
├── forecasts/6m-YYYY-MM.md
├── forecasts/12m-YYYY-MM.md
├── snapshots/YYYY-MM-resumo.md   (insights estratégicos do mês)
└── investments/*.md       (carteira)
```

## Fonte de parâmetros

**Toda referência a números correntes vem de `~/vault/finance/parameters.md`.** Nunca use valores memorizados. Leia primeiro, aplique depois. Se `parameters.md` está defasado ou incompleto, avise o usuário antes de gerar forecasts.

O script `~/.finance/planilha.py` é ferramenta auxiliar — atualizar constantes no topo a partir do `parameters.md` antes de rodar.

## Fluxo

### 1. Identificar inputs
- PDFs: faturas de cartão ou extratos bancários.
- Imagens/prints: OCR primeiro; se os valores não forem claros, pedir confirmação.
- Texto livre do usuário.

### 2. Processar PDFs
```bash
pdftotext -layout <arquivo.pdf> /tmp/fatura.txt
```
Para PDFs protegidos: `qpdf --password=<senha> --decrypt <in> <out>`.

### 3. Extrair dados
- Cartão: titular, bandeira, vencimento, total, parcelados ativos.
- Extrato: saldo inicial/final, total entradas, total saídas.
- Transações: categorizar (moradia, veículo, alimentação, assinaturas, viagem, saúde, educação, etc).

### 4. Atualizar `parameters.md` (se mudou)
Qualquer valor novo (câmbio, nova fatura, mudança de custo recorrente) → refletir em `parameters.md` antes de gerar os snapshots/forecasts.

### 5. Escrever snapshot do mês em `months/YYYY-MM.md`

Template (campos genéricos — preencher conforme dados reais):

```markdown
---
tags: [finance, mes, YYYY-MM]
created: YYYY-MM-DD
mes: YYYY-MM
---

# {Mês} {Ano} — Balanço Mensal

## TL;DR
- Saldo final do mês
- Total entradas / Total saídas
- Aporte pra investimento/objetivo
- Destaque principal

## Entradas
Tabela fonte → valor.

## Saídas PJ (se aplicável)
Itens do custo da PJ antes do TED.

## Fixas PF
Tabela item → valor, baseada em `parameters.md`.

## Cartões pagos no mês
Tabela cartão → valor → variação vs meta.

## Pix/Transferências recorrentes
Tabela pessoa/destino → enviado → recebido → líquido.

## Assinaturas ativas
Tabela item → valor → observação.

## Viagens do mês
Se houver. Compras novas, parcelas, gastos em moeda estrangeira.

## Parcelados ativos
Tabela item → valor/parcela → parcelas restantes → mês final.

## Onde foi o dinheiro (top categorias)
Top 10 categorias com R$ e %.

## Insights
- Surpresas
- Metas batidas
- Estouros
- Padrões

## Saldo final e destinação
Saldo conta / aportes investimento / colchão mantido.
```

### 6. Forecast 6 meses em `forecasts/6m-YYYY-MM.md`

Template:

```markdown
---
tags: [finance, forecast, 6m, YYYY-MM]
created: YYYY-MM-DD
---

# Forecast 6 meses — a partir de {Mês}/{Ano}

## Premissas
Listar premissas usadas (câmbio, renda ativa/inativa, metas de cartão, bônus esperados).

## Tabela mensal
| Mês | Entrada | Saídas | Sobra | Aporte | Acumulado |

## Riscos
Lista curta de riscos materiais.

## Oportunidades
Lista curta (fim de parcelas, bônus esperados, cortes possíveis).

## Regras do período
Disciplinas acordadas.
```

### 7. Forecast 12 meses em `forecasts/12m-YYYY-MM.md`

Mesma estrutura do 6m, estendida pra 12 meses, com foco em:
- Projeção anual total
- Eventos trimestrais
- Impacto no(s) objetivo(s) de longo prazo registrados em `parameters.md`

### 8. Snapshot estratégico em `snapshots/YYYY-MM-resumo.md`

Resumo < 1 página:
- Status geral (✅/⚠️/❌)
- 3 decisões principais do mês
- 3 itens pra observar no próximo mês
- Estado atual dos objetivos de longo prazo
- Referências (links pros arquivos completos)

### 9. Atualizar `README.md`
Incluir o novo mês na seção "Meses processados" e os novos forecasts na seção "Forecasts ativos".

### 10. Indexar qmd
```bash
qmd update -c vault && qmd embed 2>/dev/null
```

### 11. Confirmar ao usuário
Resumo curto: arquivos criados/atualizados + TL;DR do mês + próximo passo sugerido.

## Rodando o script

`~/.finance/planilha.py` é a ferramenta de simulação. Não versionado. Constantes no topo.

1. Ler `~/vault/finance/parameters.md` (fonte de verdade).
2. Sincronizar constantes do script (editar direto ou copiar pra `/tmp/planilha-run.py` e ajustar).
3. `python3 ~/.finance/planilha.py > /tmp/planilha-out.txt`.
4. Incorporar outputs nos arquivos do vault.

**Outputs temporários em `/tmp/` apenas.** Nunca salvar output persistente fora de `~/.finance/` (bruto) ou `~/vault/finance/` (notas).

## Voz / estilo

- Português informal, direto, sem AI-speak.
- Valores no padrão brasileiro (R$ 1.234,56).
- Tabelas em markdown pra tudo numérico.
- Comentários curtos. Sem enrolação.
- Emoji só em headers/status (✅ ⚠️ ❌ 🔴 🟡 🟢). Não no corpo.
- Nunca mencionar AI/Claude nos arquivos.
- **Nunca hardcodar valores, nomes, empresas ou estruturas específicas do usuário nos arquivos da skill.** Todos os dados concretos vivem no vault ou no script local.

## Erros a evitar

- ❌ Escrever fora de `~/vault/finance/`.
- ❌ Rodar o script com valores default sem checar `parameters.md`.
- ❌ Gerar forecast sem ler primeiro o mês atual + parâmetros.
- ❌ Misturar entradas eventuais (bônus, reembolso) com renda base.
- ❌ Duplicar um item em duas categorias (ex: se está em Fixas, não repete em Cartões).
- ❌ Extrapolar meses futuros sem base histórica mínima.
- ❌ Inventar dados — se falta informação, perguntar ao usuário.
