# Corne vs Sofle v2

Gerado do `keymap-dump.json` (lido da EEPROM). VIA protocolo 9.

## Diferenca fisica

| | Sofle v2 | Corne | delta |
|---|---|---|---|
| grid por metade | 6x4 = 24 | 6x3 = 18 | -6 |
| polegares por metade | 5 | 3 | -2 |
| **total** | **58** | **42** | **-16** |
| encoders | 2 | 0 | -2 |

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

1. **Camada 1, posicao do A, esta como `1` e nao `Shift+1`** — o resto da fileira
   e toda `Shift+N` (`@ # $ % ^ & * ( )`). Como esta, sai o digito `1`, que ja
   existe na linha de cima, e o `!` nao existe em lugar nenhum.
2. **Sem Super esquerdo na camada 0** — so RGUI no polegar direito.
3. **CAPS ocupa um polegar** nas camadas 0 e 1. Candidata a ceder o lugar.
4. **Camadas sao TG (toggle), nao MO (momentaneo)**.
5. **PrintScreen na camada 3**, alcancavel so via camada 1 + TG(3).
6. **Layout do sistema**: `us` e `br` configurados. O keymap foi desenhado para
   `us`. Alternativa avaliada e nao aplicada: layout unico `us(altgr-intl)`.

## Nota sobre backup

O `.vil` cobre mais que o `keymap-dump.json`: tap dance e key override ficam
em outra regiao da EEPROM e nao aparecem na API VIA que o dump usa.
