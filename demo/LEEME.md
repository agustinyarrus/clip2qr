# La demo de clip2qr

`demo.gif` y `demo.webm` son una grabación de verdad, no un mockup: una terminal de 100×30 corre
clip2qr compilado desde este repo con una URL. Lo que se ve es la salida real de esa corrida, y el
código se lee: el último cuadro del GIF, pasado por zxing-cpp, da
`https://github.com/agustinyarrus/clip2qr`.

| Momento | Qué se ve |
|---|---|
| 0 a 4,4 s | se escribe `clip2qr --text "https://github.com/agustinyarrus/clip2qr"` |
| 4,5 s al final | el QR (versión 3, 29×29 módulos, nivel M) en medios bloques y la tarjeta: contenido, longitud, de dónde salió el texto, versión y corrección |

Con el comando y el prompt que vuelve, la sesión ocupa 34 renglones (la cabecera, el QR con su
borde y la tarjeta con su margen) y la ventana tiene 30: al terminar, la pantalla sube cuatro
renglones y el último cuadro muestra el QR y la tarjeta enteros, sin la línea del comando ni la
cabecera. Es lo que hace cualquier terminal de ese tamaño.

## Qué hay acá

| Archivo | Para qué |
|---|---|
| `demo.tape` | el guion de [VHS](https://github.com/charmbracelet/vhs): prepara la escena fuera de cámara, graba y la desarma |
| `preparar.ps1` | compila clip2qr de este repo a `.escena\bin` (o la borra con `-Limpiar`) |
| `demo.gif` · `demo.webm` | la grabación: 8,6 s a 25 cuadros por segundo, 1078×644, 96 KB y 68 KB |
| `demo.png` | el último cuadro, el QR con la tarjeta, en paleta como el GIF (para quien pide menos movimiento; también se lee con zxing-cpp) |

## Regrabar con VHS

Hace falta Windows, PowerShell 7 y Go, y además:

```powershell
winget install --scope user charmbracelet.vhs tsl0922.ttyd Gyan.FFmpeg
```

**Ojo con la versión de VHS.** La 0.12.0 (la de winget al 28/9/2026) graba los cuadros pero no
genera ni el GIF ni el WebM, sin dar error: cancela el contexto de la grabación y se lo pasa a
ffmpeg. Está arreglado en la 0.12.1:

```powershell
go install github.com/charmbracelet/vhs@v0.12.1     # pide Go 1.26.7+; Go baja solo esa versión
```

VHS dibuja la terminal en un Chrome o Edge sin ventana: usa el que esté instalado, no baja
Chromium. Después, desde esta carpeta:

```powershell
Remove-Item Env:NO_COLOR -ErrorAction SilentlyContinue     # si tu entorno lo define, la demo sale sin color
vhs demo.tape                                             # demo.gif y demo.webm
ffmpeg -y -sseof -0.5 -i demo.gif -frames:v 1 -vf "split[a][b];[a]palettegen[p];[b][p]paletteuse=dither=none" demo.png
```

Tarda unos 20 segundos. Mirá siempre el resultado antes de publicarlo: cuadros sueltos con
`ffmpeg -ss 6 -i demo.gif -frames:v 1 cuadro.png`, y que el QR se lea (con el teléfono, o con
`python -c "import zxingcpp; from PIL import Image; print(zxingcpp.read_barcodes(Image.open('demo.png'))[0].text)"`
y los paquetes de [`requirements.txt`](../internal/qr/_oracle/requirements.txt)).

### Qué hace la escena, y por qué

- **Nada de tu máquina en pantalla.** El texto va con `--text`: clip2qr a secas leería el
  portapapeles de quien graba. Ni la cabecera ni la tarjeta muestran una ruta.
- **clip2qr de este repo.** `preparar.ps1` lo compila sin commit estampado: en la cabecera dice
  `v1.0.0`, no `v1.0.0+abc1234`.
- **El prompt es `>` y nada más**, sin sugerencias del historial (serían las de quien graba), con
  los colores de la línea de comandos en la paleta de clip2qr. El tape los fija fuera de cámara.

### Estilo

El de las demás demos de la familia: fondo `#0b0b0f`, texto `#cdd6f4` y los acentos de
`internal/tui/color.go` como colores ANSI del tema; Cascadia Mono 16; 1078×644 px, que con 24 px de
margen dan 100×30. Tipeo de 60 a 85 ms por tecla. 25 cuadros por segundo: a 50, el navegador no
llega a capturar cada cuadro a tiempo y el video sale acelerado.

## Sin VHS

La misma sesión se puede grabar a mano, con un grabador de pantalla como
[ScreenToGif](https://www.screentogif.com) sobre una terminal de 100×30 con fondo `#0b0b0f` y
Cascadia Mono (`wt --size 100,30 pwsh -NoProfile`). Desde esta carpeta:

```powershell
$env:Path = (.\preparar.ps1) + ";$env:Path"      # compila clip2qr y lo pone primero en el PATH
clip2qr --text "https://github.com/agustinyarrus/clip2qr"
.\preparar.ps1 -Limpiar
```
