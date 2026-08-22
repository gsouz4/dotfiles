# Corne vs Sofle v2

Gerado do `keymap-dump.json` (lido da EEPROM). VIA protocolo 9.

## Diferenca fisica

| | Sofle v2 | Corne | delta |
|---|---|---|---|
| grid por metade | 6x4 = 24 | 6x3 = 18 | -6 |
| polegares por metade | 5 | 3 | -2 |
| **total** | **58** | **42** | **-16** |
| encoders | 2 | 0 | -2 |

A fileira perdida e a numerica. Os 4 polegares a menos sao o outro aperto.

## Ocupacao das camadas

- camada 0: 46 teclas
- camada 1: 45 teclas
- camada 2: 19 teclas
- camada 3: 1 teclas
- camada 4: 0 teclas (vazia)
- camada 5: 0 teclas (vazia)
- camada 6: 0 teclas (vazia)
- camada 7: 0 teclas (vazia)

## Cobertura

Configurado:
- `=` igual
- `\` barra invertida
- `` ` `` crase
- `[`
- `]`
- PrintScreen
- F1-F12
- LGUI (Super esq)
- RALT (AltGr)

Deliberadamente fora (nao usados):
- Insert
- Home
- PageUp
- End
- PageDown

## Pendencias em aberto

1. **Sem Super esquerdo na camada 0** — so RGUI no polegar direito. Bloqueia
   atalhos do tipo `Super+H`, que cairiam na mesma mao.
2. **CAPS ocupa um polegar** nas camadas 0 e 1. Posicao cara, tecla pouco usada.
   Candidata a ceder o lugar pro Super esquerdo ou pro AltGr.
3. **Camadas sao TG (toggle), nao MO (momentaneo)** — para a camada 1, usada o
   tempo todo, MO tende a errar menos.
4. **PrintScreen esta na camada 3**, alcancavel so via camada 1 + TG(3).
   Quatro acoes para um print. A camada 2 tem espaco e fica a um toque.
5. **LALT na posicao do S da camada 2** — provavel sobra do layout de fabrica.
6. **Layout do sistema**: `us` e `br` configurados. O keymap foi desenhado para
   `us`; em `br` os simbolos `[ ] \ ; ' /` saem diferentes. Alternativa avaliada
   e nao aplicada: layout unico `us(altgr-intl)`.
