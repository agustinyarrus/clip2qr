# clip2qr 1.0.0

La primera versión de clip2qr como proyecto propio. Antes vivía en navaja, la suite de herramientas de consola para Windows; el código es el que se probó ahí, con pruebas nuevas en el borde de arriba de la norma (los límites de la versión 40, por modo y por nivel) y la cabecera con la versión con su `v`. Ahora tiene su repo, su número de versión, su CI y su demo.

clip2qr es para pasar algo de la PC al teléfono sin mandarte un mensaje a vos mismo: copiás una URL, una clave de Wi-Fi o un texto, corrés `clip2qr` y lo escaneás con la cámara directo de la terminal.

## Qué trae

**Un QR del portapapeles, en la terminal.** `clip2qr` a secas toma lo que hay en el portapapeles; `--text "…"`, un argumento suelto o la entrada estándar (`-`, `--stdin`) también sirven. El código se dibuja con medios bloques (`▀ ▄ █`): cada carácter son dos módulos, así sale cuadrado, ocupa la mitad de renglones y se centra en la ventana. Abajo, una tarjeta con el contenido, de dónde salió, la versión del QR y el nivel de corrección.

**Un codificador propio, sin dependencias.** Modos numérico, alfanumérico y byte (UTF-8), versiones 1 a 40, niveles L, M, Q y H, Reed–Solomon sobre GF(256) y la mejor de las 8 máscaras según las reglas de penalización del estándar. Elige solo el modo más compacto y la versión más chica en la que entra el texto.

**Pensado para consolas oscuras.** Por defecto invierte claro y oscuro, para que el lector del teléfono vea tinta oscura sobre fondo claro; `-i` es para terminales de fondo claro.

**PNG, si hace falta.** `-o wifi.png` además guarda el código como imagen, con `--scale` píxeles por módulo y el borde de 4 módulos que pide el estándar, escrito de forma atómica.

**Todo local.** El texto no sale de la máquina. Si la salida no es una consola, texto plano sin un solo escape de color. Códigos de salida: `0` todo bien, `2` línea de comandos inválida, `3` no se pudo (el portapapeles no tiene texto, o el texto no entra ni en la versión 40).

## Descargar

`clip2qr.exe` es el programa entero: Windows 10 u 11 de 64 bits (se probó en Windows 11), un solo archivo, sin instalador. Copialo a una carpeta del `PATH`. O, con Go:

```powershell
go install github.com/agustinyarrus/clip2qr@v1.0.0
```

Para comprobar la descarga, en la carpeta donde quedaron los dos archivos:

```powershell
(Get-FileHash .\clip2qr.exe -Algorithm SHA256).Hash -eq ((Get-Content .\SHA256SUMS) -split '\s+')[0]   # True
```

En Git Bash o WSL, `sha256sum -c SHA256SUMS`. El `.exe` es reproducible: la misma etiqueta con el mismo Go da los mismos bytes, así que cualquiera puede compilarla y comparar ([cómo](https://github.com/agustinyarrus/clip2qr/blob/v1.0.0/docs/RELEASE.md#5-el-exe-es-reproducible)).

## Cómo se verificó

- clip2qr no se contrasta consigo misma: zxing-cpp, un decodificador independiente, lee 72 de 72 códigos del codificador (15 textos por 4 niveles, con tildes, hebreo y japonés, y los 12 textos más largos que entran en la versión 40) y 15 de 15 dibujos que clip2qr imprime en la terminal, reconstruidos desde los medios bloques: lo que de verdad escanea el teléfono.
- 57 pruebas de Go, entre ellas el vector de Reed–Solomon que fija el orden del polinomio generador (ese orden fue el bug que al principio impedía leer cualquier código) y los límites de la versión 40.
- CI en `windows-latest` con el Go mínimo del `go.mod`: formato, `go vet` (también para Linux), todas las pruebas, los dos oráculos de zxing-cpp y el `.exe` con su versión y su SHA256.

El detalle, en [docs/VERIFICACION.md](https://github.com/agustinyarrus/clip2qr/blob/v1.0.0/docs/VERIFICACION.md); la arquitectura y el codificador paso a paso, en [docs/ARQUITECTURA.md](https://github.com/agustinyarrus/clip2qr/blob/v1.0.0/docs/ARQUITECTURA.md).

## Lo que falta

- **Leer el portapapeles no tiene prueba automática.** Ni las pruebas ni los oráculos tocan el portapapeles de quien los corre (sería pisarle lo que tiene copiado); los oráculos prueban todo lo demás pasando el texto con `--text`.
- **Segmentos de modos mezclados.** Hoy todo el texto va en un solo modo: una URL con un número largo al final va entera en modo byte, y el código sale una o dos versiones más grande de lo necesario.
- `--copy`, para dejar el PNG en el portapapeles.

La lista, en [docs/PENDIENTE.md](https://github.com/agustinyarrus/clip2qr/blob/v1.0.0/docs/PENDIENTE.md).
