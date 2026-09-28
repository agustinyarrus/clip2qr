# clip2qr

Dibuja en la terminal un código QR con lo que hay en el portapapeles. Para pasar una URL (o una clave de Wi-Fi, o un texto) de la PC al teléfono sin mandarte un mensaje a vos mismo ni subir nada a ningún lado. Un único `clip2qr.exe` portable escrito en Go puro, con un codificador QR propio.

```powershell
clip2qr                          # QR de lo que haya en el portapapeles
clip2qr --text "https://…"       # de un texto puntual
echo hola | clip2qr -            # de la entrada estándar
clip2qr -e h -o wifi.png         # corrección alta y además guardado como PNG
```

Así se ve `clip2qr --text "https://github.com/agustinyarrus/clip2qr"` (salida real, sin colores; con el teléfono se lee directo de la pantalla):

```
  clip2qr  ·  convierte el portapapeles en un QR                                             1.0.0


                                 █████████████████████████████████
                                 ██ ▄▄▄▄▄ ██▀██ █▄▀ ▀▀▄ █ ▄▄▄▄▄ ██
                                 ██ █   █ █ █▀▄ ▀█▄█▀██ █ █   █ ██
                                 ██ █▄▄▄█ █ ▄▄ ▀▀▄▀▄██▄ █ █▄▄▄█ ██
                                 ██▄▄▄▄▄▄▄█ █▄█ █▄▀ █ ▀ █▄▄▄▄▄▄▄██
                                 ██ ▀▄   ▄███▄▀▀▄ █▀ ▀▀▀█   ▄▄█▀██
                                 ██▄▀ ▀ ▀▄ ▄  ▄██▀▄▄█▄█▄███▄▀█▀███
                                 ██▀▄   ▄▄▀▄▀   ▄ ▄▀ ▀▀▀▀▀▀▀▄▄█▀██
                                 ███ ▀▄ ▄▄██  █ ▄█▄ ▄▀▀  ▀▀ ▄▄▀███
                                 ██ ██ █ ▄  ▄ █ ▀███ █ █ ▀ ▀▄ █▀██
                                 ██ █▄▄▀ ▄▀██ ▄▀ ▄▄▄█▄█ ▀ ▄▄█▄▀███
                                 ██▄█▄█▄▄▄█  ▄▄ █▄▄ ▄▀▄ ▄▄▄ ▀   ██
                                 ██ ▄▄▄▄▄ █▀ ▄ ██▀  █▄  █▄█ ▄▄▀███
                                 ██ █   █ █ ▄  █▀▀▄ ▄█▀ ▄▄▄▄▀   ██
                                 ██ █▄▄▄█ █▄▀▀▀ █ ▄█▄ ▄  ▄ ▄ ▄ ███
                                 ██▄▄▄▄▄▄▄█▄▄█▄██▄▄▄▄█▄██▄▄▄█▄████
                                 ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀


  ── clip2qr ──
    Contenido   https://github.com/agustinyarrus/clip2qr
    Longitud    40 caracteres
    Fuente      argumento --text
    Versión QR  3 (29×29)
    Corrección  nivel M
```

(En la consola los bloques van pintados sobre fondo negro; según la fuente del navegador, acá pueden verse líneas finas entre renglones que en la terminal no están.)

## Qué hace

- **Codificador QR propio, sin dependencias**: modos numérico, alfanumérico y byte (UTF-8), versiones 1 a 40, niveles de corrección L, M, Q y H, Reed–Solomon sobre GF(256) y la mejor de las 8 máscaras según las reglas de penalización del estándar. Elige solo el modo más compacto y la versión más chica en la que entra el texto.
- **Medios bloques** (`▀ ▄ █`): cada carácter son dos módulos apilados, así el código sale cuadrado y ocupa la mitad de líneas. Se centra en la ventana.
- **Pensado para consolas oscuras**: por defecto invierte claro y oscuro para que el lector del teléfono vea tinta oscura sobre fondo claro; `-i` es para terminales de fondo claro.
- **De dónde sale el texto**: el portapapeles (por la API de Windows, en UTF-16), `--text`, un argumento suelto, o la entrada estándar con `-` o `--stdin`.
- **PNG opcional** con `-o`: escala de `--scale` píxeles por módulo y al menos 4 módulos de borde (lo que pide el estándar), escrito de forma atómica.
- **Todo local**: el texto no sale de la máquina.

## Instalación

Con [Go](https://go.dev/dl) 1.24 o más nuevo (el `go.mod` pide 1.26 y Go descarga sola esa versión la primera vez):

```powershell
go install github.com/agustinyarrus/clip2qr@latest
```

O desde el código, con la versión y el commit estampados en el exe:

```powershell
git clone https://github.com/agustinyarrus/clip2qr
cd clip2qr
.\build.ps1          # compila a dist\clip2qr.exe
.\build.ps1 -Test    # antes corre go vet y todos los tests
```

No tiene módulos externos: solo la biblioteca estándar de Go. Es una herramienta de Windows (el portapapeles se lee por `user32`).

## Uso

`clip2qr --help` (salida real, sin colores):

```
  clip2qr  ·  convierte el portapapeles en un QR en la terminal                              1.0.0

  uso
    clip2qr                  QR de lo que haya en el portapapeles
    clip2qr "texto o URL"    QR de un texto puntual
    echo hola | clip2qr -    QR de la entrada estándar

  contenido
        --text TEXTO      usar este texto en vez del portapapeles
        --stdin           leer el texto de la entrada estándar

  código
    -e, --level l|m|q|h   corrección de errores (más alto = más robusto y más denso) (m)
    -q, --quiet N         módulos de borde claro alrededor (2)
    -i, --invert          invertir claro/oscuro (para terminales de fondo claro)

  guardar
    -o, --png ARCHIVO     además, guardar el QR como PNG
    -s, --scale N         píxeles por módulo en el PNG (8)

  general
    -h, --help            muestra esta ayuda
    -V, --version         muestra la versión
        --no-color        salida sin colores (también respeta NO_COLOR)
```

Flags al estilo GNU (`-e h`, `--level=h`, `--`); un flag mal escrito sugiere el más parecido ("¿quisiste decir --level?"). Si la salida no es una consola (un pipe o un archivo), no se emite ningún escape de color; también respeta `NO_COLOR`.

Códigos de salida: `0` todo bien · `2` línea de comandos inválida · `3` no se pudo (el portapapeles no tiene texto, o el texto no entra ni en la versión 40).

## Cómo se verifica

clip2qr no se contrasta consigo misma sino con un decodificador independiente, [zxing-cpp](https://github.com/zxing-cpp/zxing-cpp):

| Qué | Oráculo | Resultado |
|---|---|---|
| El codificador | `gen.go` emite 72 PNG: 15 textos × 4 niveles (numérico, alfanumérico, byte con UTF-8, hebreo y japonés) y los 12 textos más largos que entran en la versión 40, uno por modo y nivel; `decode.py` los lee con zxing-cpp | 72 de 72 |
| El dibujo de la terminal | `terminal_check.py` reconstruye la matriz desde los medios bloques que imprime `clip2qr.exe` y la decodifica con zxing-cpp | 15 de 15 (5 textos, normal, invertido y nivel H) |

Además hay 56 tests de Go (`go test ./...`): entre ellos, el vector de Reed–Solomon que fija el orden del polinomio generador (ese orden fue el bug que al principio impedía leer cualquier código) y los límites de capacidad de la versión 40 de la norma, por modo y nivel. El detalle y cómo correr cada oráculo: [docs/VERIFICACION.md](docs/VERIFICACION.md).

## Cómo está hecho

```
main.go              el punto de entrada: abre la consola, llama a clip2qr.Main y sale con su código
internal/
  clip2qr/           la herramienta: de dónde sale el texto, el dibujo centrado, el PNG y la tarjeta
  qr/                el codificador: modos, tablas, GF(256), Reed–Solomon, BCH, máscaras, dibujo
    _oracle/         gen.go, decode.py y terminal_check.py, contra zxing-cpp
  win/desk/          portapapeles y modo de la consola por syscall
  fsx/               escritura atómica del PNG
  cli/               flags estilo GNU, ayuda, sugerencias por distancia de edición
  tui/               consola: paleta, tarjetas, formato es-AR
  textdist/          distancia de Damerau–Levenshtein
  version/           versión y commit, estampados por build.ps1
```

La arquitectura y los detalles del codificador: [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md). Lo que falta: [docs/PENDIENTE.md](docs/PENDIENTE.md).

## Origen

clip2qr nació dentro de navaja, una suite de herramientas de consola para Windows que compartían un núcleo (la consola, los flags, el portapapeles). Desde la 1.0.0 es un proyecto propio: se llevó ese núcleo y la historia de git de sus archivos.

## Licencia

[MIT](LICENSE).
