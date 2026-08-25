# Layout atual do Corne

Lido da EEPROM via raw HID.
VIA protocolo 9, 8 camadas.

### Camada 0  — 46 teclas
```
L0       ESC         Q         W         E         R         T  |      TG(1)         Y         U         I         O         P
L1       TAB         A         S         D         F         G  |        DEL         H         J         K         L      SCLN
L2      LSFT         Z         X         C         V         B  |        ---         N         M      COMM       DOT      SLSH
L3      LALT      CAPS       ---      LCTL     MO(1)       ENT  |        SPC     MO(2)      RGUI      BSPC      QUOT      RSFT
```

### Camada 1  — 45 teclas
```
L0       TAB         1         2         3         4         5  |      TG(1)         6         7         8         9         0
L1      LCTL    SFT(1)    SFT(2)    SFT(3)    SFT(4)    SFT(5)  |       RALT    SFT(6)    SFT(7)    SFT(8)    SFT(9)    SFT(0)
L2      LSFT       EQL      MINS  SFT(EQL)      LBRC      TRNS  |        ---         N      RBRC      COMM       DOT      SLSH
L3      LCTL      CAPS       ---      LGUI     MO(1)       SPC  |        ENT     MO(3)      RGUI      BSPC      QUOT       ESC
```

### Camada 2  — 24 teclas
```
L0       GRV        F1        F2        F3        F4        F5  |      TRNS        F6        F7        F8        F9       F10
L1      TRNS     C+A+←      LALT      TRNS      TRNS      TRNS  |      TRNS      LEFT      DOWN        UP      RGHT     C+A+→
L2      TRNS      TRNS      TRNS      TRNS      TRNS      TRNS  |       ---      TRNS     C+A+↓     C+A+↑     C+A+→      BSLS
L3      TRNS      TRNS       ---      TRNS      TRNS      TRNS  |      TRNS      TRNS      TRNS       F11       F12      TRNS
```

`C+A+x` = `LCA(KC_x)`, Ctrl+Alt+seta numa tecla so (troca de workspace no GNOME).

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
