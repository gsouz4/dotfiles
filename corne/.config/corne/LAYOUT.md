# Layout atual do Corne

Lido da EEPROM via raw HID.
VIA protocolo 9, 8 camadas.

### Camada 0  — 46 teclas
```
L0       ESC         Q         W         E         R         T  |       RCTL         Y         U         I         O         P
L1       TAB         A         S         D         F         G  |        DEL         H         J         K         L      SCLN
L2      LSFT         Z         X         C         V         B  |        ---         N         M      COMM       DOT      SLSH
L3      LALT      CAPS       ---      LCTL     TG(1)       ENT  |        SPC     TG(2)      RGUI      BSPC      QUOT      RSFT
```

### Camada 1  — 45 teclas
```
L0       TAB         1         2         3         4         5  |       RCTL         6         7         8         9         0
L1      LCTL         1    SFT(2)    SFT(3)    SFT(4)    SFT(5)  |       RALT      LEFT      DOWN        UP      RGHT      SCLN
L2      LSFT       EQL      MINS  SFT(EQL)      LBRC      TRNS  |        ---         N      RBRC      COMM       DOT      SLSH
L3      LCTL      CAPS       ---      LGUI     TG(1)       SPC  |        ENT     TG(3)      RGUI      BSPC      QUOT       ESC
```

### Camada 2  — 19 teclas
```
L0       GRV        F1        F2        F3        F4        F5  |       TRNS        F6        F7        F8        F9       F10
L1      TRNS      TRNS      LALT      TRNS      TRNS      TRNS  |       TRNS      LEFT      DOWN        UP      RGHT      TRNS
L2      TRNS      TRNS      TRNS      TRNS      TRNS      TRNS  |       TRNS      TRNS      TRNS      TRNS      TRNS      BSLS
L3      TRNS      TRNS      TRNS      TRNS      TRNS      TRNS  |       TRNS      TRNS      TRNS       F11       F12      TRNS
```

### Camada 3  — 1 teclas
```
L0      TRNS      TRNS      PSCR      TRNS      TRNS      TRNS  |       TRNS      TRNS      TRNS      TRNS      TRNS      TRNS
L1      TRNS      TRNS      TRNS      TRNS      TRNS      TRNS  |       TRNS      TRNS      TRNS      TRNS      TRNS      TRNS
L2      TRNS      TRNS      TRNS      TRNS      TRNS      TRNS  |       TRNS      TRNS      TRNS      TRNS      TRNS      TRNS
L3      TRNS      TRNS      TRNS      TRNS      TRNS      TRNS  |       TRNS      TRNS      TRNS      TRNS      TRNS      TRNS
```

### Camada 4  (vazia)

### Camada 5  (vazia)

### Camada 6  (vazia)

### Camada 7  (vazia)
