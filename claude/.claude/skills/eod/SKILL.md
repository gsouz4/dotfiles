---
name: eod
description: Consolidate today's raw work log (captured automatically by the Stop hook) into a clean daily note in the Obsidian vault, with a ready-to-read block for the daily standup. Use when the user says "eod", "fecha o dia", "end of day", "consolida o dia", "resumo do dia", "prepara a daily", "o que fiz hoje". Accepts an optional date (YYYY-MM-DD) or "ontem".
---

# EOD

Transforma o log bruto do dia em uma nota diária limpa em `~/vault/work/daily/`.

## Fontes

1. **Log bruto**: `~/vault/work/raw/{date}.jsonl`. Uma linha por turno relevante do Claude Code, gravada pelo hook `~/.claude/hooks/worklog-capture.sh`. Campos: `ts`, `project`, `cwd`, `branch`, `prompt`, `tools`, `edits`, `bash`, `commits`, `summary`.
   No mesmo arquivo há linhas com `kind: "tap"`, gravadas pelo `nfc-tap` quando o usuário encosta o celular numa NFC tag. Campos: `ts`, `tag`, `label`, `action` (`start`, `end`, `event`), `duration_min` (só em `end`), `note`. São marcadores de contexto (foco, reunião, pausa), não trabalho em si.
2. **Commits manuais**: para cada `cwd` distinto no log bruto que seja um repo git, rode `git -C {cwd} log --since="{date} 00:00" --until="{date} 23:59" --author="$(git config user.name)" --format="%h %s"`. Isso pega o que foi commitado fora do Claude.
3. **Nota existente**: se `~/vault/work/daily/{date}.md` já existir, leia antes. Preserve o que o usuário escreveu à mão (blocos `## Bloqueios` e `## Notas`), reescreva só as seções geradas.

Data padrão: hoje. `ontem` resolve para o dia anterior. Se não houver log bruto nem commits para a data, diga isso e não crie arquivo.

## Como consolidar

O objetivo é reduzir, não transcrever. Regra de bolso: um dia de trabalho vira 3 a 8 bullets em `## Feito`.

- Agrupe por projeto (`project`). Dentro do projeto, agrupe turnos que tratam da mesma coisa (mesmo arquivo, mesmo assunto no prompt) em um bullet só.
- Cada bullet diz o resultado, não o processo. "Corrigi validação de OTP no fluxo sem login" e não "editei o arquivo X, rodei testes, editei de novo".
- Análises e investigações contam como trabalho. Se um turno só leu código e respondeu uma pergunta, registre a conclusão em uma linha.
- Se houver `commits`, use a mensagem do commit como base do bullet. Commit é a melhor descrição que existe do que foi feito.
- Se o prompt mencionar um ID de ticket (`PROJ-123`, `#456`), mantenha o ID no início do bullet. O `/sprint-recap` agrupa por ele.
- Ignore turnos de configuração do próprio Claude Code, ajustes de skill, ou conversa sem entrega, a menos que tenham consumido parte relevante do dia.
- Não invente. Se o log estiver ambíguo, escreva o que dá pra afirmar e só.
- Se houver linhas `kind: "tap"`, some as durações dos `end` por `label` e escreva uma seção `## Ritmo` com uma linha por label ("Foco: 3 blocos, 2h40"). Eventos com `note` viram uma linha só se a nota disser algo útil. Use os horários de foco/reunião para dar contexto ao `## Feito` quando bater com os turnos (ex.: reunião no meio da tarde explica um buraco). Sem taps, não crie a seção.

## Estilo

Mesmo estilo das outras notas do vault. Informal, direto, sem corporativês. Português para o texto, inglês só para termos técnicos. Frases curtas. Sem travessão. Sem emoji.

## Formato da nota

```markdown
---
tags: [work, daily]
created: {date}
projects: [{lista de projetos}]
---

# {date} ({dia da semana em pt})

## Feito
- [{PROJ-123}] {resultado}
- {resultado}

## Para a daily
Ontem: {1 a 3 frases, o que importa pro time ouvir}
Hoje: {o que ficou aberto e vira próximo passo, se dá pra inferir. Senão "a definir"}
Bloqueios: {se houver algo no log ou na seção do usuário. Senão "nenhum"}

## Pendências
- {coisa que ficou pela metade, teste falhando, TODO mencionado no summary}

## Ritmo
- {só se houver taps: "Foco: N blocos, HhMM", "Reunião: ..."}

## Bloqueios

## Notas
```

`## Bloqueios` e `## Notas` ficam vazios para o usuário preencher à mão. Nunca sobrescreva o conteúdo deles.

## Depois de gravar

Mostre no terminal só o bloco `## Para a daily` e o caminho do arquivo. Não repita a nota inteira.

O log bruto em `raw/` não é apagado. Ele não aparece no Obsidian (não é `.md`) e serve de auditoria se a nota precisar ser refeita.
