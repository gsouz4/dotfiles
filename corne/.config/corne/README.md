# corne

Configuracao do teclado Corne (Pilot W-CORNE, firmware Vial, VIA protocolo 9).

## Arquivos

| arquivo | o que e |
|---|---|
| `keymap-dump.json` | dump bruto das 8 camadas, lido da EEPROM via raw HID |
| `LAYOUT.md` | as mesmas camadas em formato legivel |
| `ANALISE.md` | comparativo com o Sofle v2 e pendencias |
| `layouts/*.vil` | export do proprio Vial (File > Save Current Layout) |
| `gnome/` | scripts de atalho de workspace (nao aplicados) |

## Backup

O `.vil` e o formato canonico de restauracao: **File > Load Saved Layout** no Vial
grava de volta na EEPROM. O `keymap-dump.json` e um backup independente, caso o
Vial nao consiga abrir o `.vil` — da pra reescrever via raw HID (comando VIA 0x05).

## Por que fazer backup

A EEPROM pode ser zerada por: reflash de firmware (o QMK limpa o keymap dinamico
quando a versao da EEPROM muda), bootmagic acidental ao conectar o cabo, ou
escrita interrompida por queda de energia. Bateria descarregada NAO apaga —
EEPROM e flash sao nao-volateis.

## Ferramentas

O Vial fica em `~/.local/bin/vial` (AppImage + lock de instancia unica).
Regra udev em `/etc/udev/rules.d/99-vial.rules`.

**Importante:** feche o Vial antes de ler a EEPROM por script. Duas coisas
disputando o mesmo `/dev/hidraw` travam o processo em estado D no kernel.
