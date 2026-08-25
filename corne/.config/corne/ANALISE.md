# Corne — decisoes e pendencias

Gerado do `keymap-dump.json` (lido da EEPROM). VIA protocolo 9.

## Ocupacao das camadas

- camada 0: 46 teclas
- camada 1: 45 teclas
- camada 2: 24 teclas
- camada 3: 1 teclas
- camada 4: 0 teclas (vazia)
- camada 5: 0 teclas (vazia)
- camada 6: 0 teclas (vazia)
- camada 7: 0 teclas (vazia)

## Teclas de camada

Todas sao **MO (momentaneo)** — ativa enquanto segura:

- camada 0, polegar (linha 3 col 4) -> MO(1)
- camada 0, polegar (linha 3 col 7) -> MO(2)
- camada 1, polegar (linha 3 col 7) -> MO(3)

## Fora do escopo (decisao)

Insert, Home, End, PageUp, PageDown — nao usados, deliberadamente sem mapeamento.

## Pendencias em aberto

1. **Sem Super esquerdo na camada 0** — so RGUI no polegar direito. Bloqueia
   atalhos tipo `Super+H`, que cairiam na mesma mao.
2. **CAPS ocupa um polegar** nas camadas 0 e 1. Posicao cara, tecla pouco usada.
   Candidata a ceder lugar para Super esquerdo ou AltGr.
3. **Sem entrada travavel para a camada 1** — so MO. Para digitar sequencias
   longas de numero sem segurar o polegar, faltaria um `TG(1)` ou `OSL(1)`
   numa segunda posicao. MO cobre bem o simbolo solto; nao cobre a sequencia.
4. **PrintScreen na camada 3**, alcancavel so segurando MO(1) e MO(3) juntos.
5. **Troca de workspace** (`Ctrl+Alt+seta`) vive na camada 2 como `LCA(kc)`:
   `A` = anterior, `;` = proximo. Uma tecla + `MO(2)`, sem encadear Ctrl e
   Alt na mao. Antes exigia Ctrl + `MO(2)` + `S`(Alt) + `H`, e qualquer
   ordem errada vazava `Alt+H`/`Ctrl+Alt+H` pro app (abria dialogo de arquivo).
   O `LALT` solto no `S` foi mantido por enquanto; os `LCA(↓ ↑ →)` em `M , .`
   sao sobra da primeira tentativa e podem sair.
6. **Sem teclas de midia** — nenhum KC_MUTE/VOLU/VOLD em camada alguma.
7. **Layout do sistema**: `us` e `br` configurados; o keymap foi desenhado para
   `us`. Alternativa avaliada e nao aplicada: layout unico `us(altgr-intl)`.

## Nota sobre backup

O `.vil` cobre mais que o `keymap-dump.json`: tap dance e key override ficam
em outra regiao da EEPROM e nao aparecem na API VIA que o dump usa.

## Nota sobre keycodes

O QMK renumerou os quantum keycodes em 2023. A faixa 0x52xx hoje e:
`0x5200 TO | 0x5220 MO | 0x5240 DF | 0x5260 TG | 0x5280 OSL | 0x52C0 TT`.
Tabelas antigas leem 0x52xx inteiro como toggle e reportam MO como TG.
