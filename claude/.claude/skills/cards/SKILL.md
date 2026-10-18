---
name: cards
description: Revisão em flashcards dos conceitos do projeto de estudo CHIP-8 em OCaml — arquitetura de computadores (PC, endianness, endereçamento, ciclo fetch-decode-execute) e OCaml (módulos, .mli, recursão, tipos). Lê o NOTES.md do projeto e prioriza o que o usuário errou nas sessões anteriores. Use no início de qualquer sessão de estudo do CHIP-8, e sempre que ele disser "cards", "me dá um refresh", "refresh", "revisar", "me pergunta", "quiz", "o que eu já estudei", "reaquece", ou abrir o projeto depois de dias parado. Use também quando ele pedir pra ser testado ou disser que esqueceu o que tinha visto.
---

# Cards — revisão do CHIP-8

Revisão curta antes de estudar: 5 a 7 cards, uns 5 minutos, terminando com o próximo passo do projeto.

O usuário está aprendendo arquitetura de computadores construindo um emulador CHIP-8 em OCaml, **sem copiar código**. A revisão segue a mesma regra: você pergunta, ele responde, você confirma ou corrige.

**Nunca entregue código pronto — nem como "resposta certa".** Se o card for sobre uma construção de OCaml, o que se espera é o conceito em palavras. "É um `let ... in` porque eu quero guardar o valor, não descartar" é resposta completa; a linha escrita não acrescenta nada e tira dele a chance de escrever sozinho depois.

## Arquivos

| | |
|---|---|
| Notas (fonte dos cards) | `/home/gsouza/Documents/chip8/NOTES.md` |
| Estado (histórico) | `~/.claude/data/chip8-cards.json` |

Leia as notas **sempre**, no começo de toda sessão. Elas crescem a cada estudo, e cards derivados delas ficam automaticamente atualizados. Não mantenha um baralho fixo escrito nesta skill — ele envelhece e passa a perguntar coisas que o usuário já superou.

Se o estado não existir, crie o diretório e comece com `{"cards": {}, "ultima_sessao": null}`.

## Como montar o baralho

Extraia candidatos das seções conceituais do `NOTES.md` — as que explicam *por quê*, não as de checklist. Hoje isso significa coisas como big-endian, PC, endereço vs tamanho, "tipo não pega tudo", e a lista de aprendizados de OCaml. Conforme ele avançar, vão aparecer seções novas (decode, quirks, timers); use as que existirem no momento.

Um bom card:

- **Pergunta o porquê ou o que aconteceria se**, não a definição decorada. "Por que o PC anda de 2 em 2?" vale mais que "o que é o PC?"
- **Cabe numa resposta falada de 20 segundos**
- **Tem um erro conhecido por trás.** As notas registram o que ele errou na prática (somar bytes em vez de deslocar, comparar endereço com tamanho, `read_byte` lendo o campo errado). Esses são os cards mais valiosos, porque já provaram que pegam
- **Não depende de decorar sintaxe.** `lsl` desloca, `lor` combina — o que importa é saber *quando* e *por quê*

Exemplos do estilo, com o que conta como acerto:

> **P:** Você lê `A2` e `2A` da memória. Por que somar os dois não dá a instrução?
> **Acerto:** soma empilha os dois na mesma faixa de valor; é preciso mover o primeiro pra faixa de cima (× 256 / `lsl 8`) e só então encaixar o segundo.

> **P:** O que acontece se o PC andar de 1 em 1 em vez de 2 em 2?
> **Acerto:** leitura desalinhada — metade de uma instrução colada na metade da seguinte, e a máquina executa lixo.

> **P:** Por que `rom_end` devolve um endereço em vez do tamanho da ROM?
> **Acerto:** o PC é endereço; comparar com um comprimento mistura unidades. E deixa o `0x200` escondido dentro do módulo.

> **P:** Você cria um `memory.mli`. O módulo fica mais aberto ou mais fechado?
> **Acerto:** mais fechado — sem `.mli` tudo é público, o arquivo subtrai.

## Como conduzir

**Um card por vez.** Faça a pergunta e pare. Esperar a resposta é o ponto todo do exercício — uma lista de 7 perguntas de uma vez vira leitura passiva, e ele não recupera nada da memória.

**Aceite a resposta em palavras dele.** Conceito certo com vocabulário torto é acerto. Não cobre os termos exatos das notas.

**Meio-acerto existe.** Se ele pegou a ideia mas errou uma peça, conte como erro (pra voltar), mas diga o que ele acertou antes de corrigir.

**Na correção, reaproveite a explicação que funcionou.** As notas guardam as analogias que fizeram a ficha cair — a colagem decimal `12 × 100 + 34 = 1234` pro deslocamento, o dedo na linha do livro pro PC. Se ele errar, retome por ali em vez de inventar uma explicação nova; o que já funcionou uma vez tende a funcionar de novo.

**Não vire aula.** Corrigiu, seguiu. Se um assunto revelar um buraco grande, anote e ofereça atacar durante a sessão — não gaste a revisão inteira nele.

## Priorização

Monte os 5–7 cards nesta ordem:

1. **Errados na última sessão** — o que falhou volta primeiro
2. **Errados alguma vez, ainda com menos de 2 acertos seguidos** — precisa consolidar
3. **Nunca vistos** — conceito novo que entrou nas notas desde a última revisão
4. **Acertados há mais tempo** — só pra não enferrujar; no máximo 2 por sessão

Quando um card tiver 3 acertos seguidos, aposente-o: pare de sorteá-lo, mas mantenha no estado. Se o conceito reaparecer errado num card vizinho, traga de volta.

## Estado

Depois de cada card, atualize `~/.claude/data/chip8-cards.json`:

```json
{
  "cards": {
    "byte-alto-precisa-deslocar": {
      "pergunta": "Por que somar os dois bytes não dá a instrução?",
      "acertos": 2,
      "erros": 1,
      "seguidos": 2,
      "ultima": "2026-09-20"
    }
  },
  "ultima_sessao": "2026-09-20"
}
```

O id é um slug do **conceito**, não da frase. Ao montar o baralho, reaproveite o id existente quando a ideia for a mesma, mesmo perguntando com outras palavras — senão o histórico se fragmenta e a priorização deixa de funcionar.

Grave o arquivo **ao fim da sessão**, de uma vez. Escrever a cada card interrompe o ritmo.

## Fechamento

Termine com duas coisas, curtas:

1. **Um placar honesto** em uma linha — acertos, e qual conceito volta na próxima
2. **O "onde parei"** das notas: o próximo passo concreto do projeto

O segundo é o ponto da skill. A revisão não é o estudo; é o aquecimento que entrega ele na primeira linha de código do dia.

Se ele errou algo que bloqueia justamente o próximo passo (por exemplo, esqueceu como extrair nibbles e o próximo passo é o decode), diga isso explicitamente — é a informação mais útil da sessão inteira.
