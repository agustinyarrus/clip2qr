# Pendiente

clip2qr está terminada y verificada ([VERIFICACION.md](VERIFICACION.md)). Lo que sigue son mejoras, en el orden en que conviene hacerlas.

## Codificador

- **Segmentos de modos mezclados.** Hoy se elige un solo modo para todo el texto: una URL con un número largo al final va entera en modo byte. El estándar permite partir el dato en segmentos (numérico, alfanumérico y byte) y elegir los cortes con programación dinámica; en textos mixtos el código sale una o dos versiones más chico, más fácil de leer desde lejos.
- **ECI para UTF-8.** El modo byte va sin declarar la codificación y los lectores adivinan UTF-8 (zxing acierta en todos los casos del oráculo, incluidos hebreo y japonés). Un encabezado ECI 26 lo declararía; conviene agregarlo solo cuando el texto no es ASCII, y medir antes con varios lectores de teléfono que no se rompa nada.
- **Modo kanji**, para texto japonés en Shift JIS: menos útil que los anteriores, porque casi todo lo que se copia es UTF-8.

## Herramienta

- `--copy`: dejar el PNG en el portapapeles, para pegarlo directo en un chat o un documento.
- Una prueba automática del portapapeles que guarde el contenido del usuario, escriba uno propio, lo lea con clip2qr y restaure el original, sin perder nada si se corta a mitad de camino.

## Distribución

- Releases en GitHub con el `clip2qr.exe` que genera `build.ps1` y su SHA256.
- Integración continua: `go vet` y `go test` en `windows-latest` con GitHub Actions, y los dos oráculos de zxing-cpp (no necesitan nada de la máquina).
