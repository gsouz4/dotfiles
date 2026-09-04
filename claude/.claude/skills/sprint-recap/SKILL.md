---
name: sprint-recap
description: Consolidate the daily work notes of a date range into a sprint summary note in the Obsidian vault, grouped by ticket and project, ready for sprint review or retro. Use when the user says "sprint recap", "resumo da sprint", "fecha a sprint", "o que fiz na sprint", "review da sprint", "recap das últimas 2 semanas". Accepts a range (YYYY-MM-DD..YYYY-MM-DD), "últimos N dias", or a sprint name.
---

# Sprint recap

Consolida as notas diárias de `~/vault/work/daily/` em uma nota de sprint em `~/vault/work/sprints/`.

## Intervalo

- `2026-08-20..2026-09-02`: usa as duas datas, inclusivas.
- `últimos 10 dias` ou `last 2 weeks`: conta a partir de hoje.
- Sem argumento: pergunte o intervalo. Não assuma duração de sprint.

## Fontes, em ordem

1. `~/vault/work/daily/{date}.md` para cada dia do intervalo. É a fonte principal, já consolidada.
2. Para dias sem nota diária mas com `~/vault/work/raw/{date}.jsonl`, avise que o dia não foi consolidado e ofereça rodar `/eod {date}` antes. Se o usuário preferir seguir, use o bruto direto com as mesmas regras do `/eod`.
3. Commits: para cada projeto que aparecer, rode `git log --since --until --author` no repo (o `cwd` está no bruto) para conferir se algo escapou.

## Como consolidar

Aqui o zoom é maior que no dia. Bullets de dias diferentes sobre o mesmo ticket ou tema viram um item só, com o arco inteiro: o que era, o que foi feito, como terminou.

- Agrupe primeiro por ticket (`PROJ-123`, `#456`) quando existir. Depois por projeto. Trabalho sem ticket entra em "Sem ticket" dentro do projeto.
- Cada item tem estado: `entregue`, `em andamento`, `bloqueado`, `descartado`. Infira do último dia em que apareceu.
- Junte as `## Pendências` e `## Bloqueios` dos dias. O que se repetiu por vários dias merece destaque na retro.
- Uma seção curta de aprendizados só se houver algo real nas notas. Não force.
- Não invente. Se um item aparece um dia e some, marque como "em andamento, sem atualização desde {date}".

## Estilo

Igual às outras notas do vault. Direto, sem corporativês, frases curtas, sem travessão, sem emoji. Português no texto, inglês só em termos técnicos.

## Formato

Arquivo: `~/vault/work/sprints/{start}_{end}.md`. Se o usuário der um nome de sprint, use `{start}_{end}-{slug}.md`.

```markdown
---
tags: [work, sprint]
created: {hoje}
range: [{start}, {end}]
projects: [{lista}]
---

# Sprint {start} a {end}

## Resumo
{2 a 4 frases. O que essa sprint entregou, dito pra alguém que não acompanhou}

## Por ticket
### PROJ-123 {título curto} `entregue`
- {arco do trabalho em 1 a 3 bullets}

### Sem ticket ({projeto})
- {item} `estado`

## Ficou aberto
- {pendências e bloqueios que seguem pra próxima}

## Para a retro
- {o que travou mais de um dia, o que foi mais rápido que o esperado, padrão que se repetiu}

## Dias
{lista de links [[work/daily/YYYY-MM-DD]] dos dias cobertos, um por linha}
```

## Depois de gravar

Mostre o `## Resumo` e o caminho do arquivo. Não repita a nota inteira.
