# Arquitectura

## Principios

- **Go puro, sin CGO y sin módulos externos.** clip2qr compila a un único `.exe` estático. Las llamadas a Windows van por `syscall`, sin bindings de C.
- **Una responsabilidad por paquete.** El codificador (`qr`) no sabe nada de consolas ni de portapapeles: recibe bytes y devuelve una matriz de módulos. La herramienta (`internal/clip2qr`) decide de dónde sale el texto, cómo se dibuja y qué se guarda.
- **Validar en la frontera.** Los flags se interpretan y validan una sola vez al parsear (nivel, borde, escala); adentro los valores ya son del tipo correcto.
- **Escritura atómica.** El PNG va a un temporal en la misma carpeta y se renombra al final: un corte nunca deja un archivo a medias ni pisa el anterior.
- **Salida visual que degrada.** Colores pastel sobre negro y tarjeta de resumen en la consola; texto plano sin un solo escape cuando la salida es un pipe o un archivo.

## El recorrido de una corrida

1. `main.go` abre la consola (`tui.Open`), llama a `clip2qr.Main` con la versión y sale con el código que devuelve.
2. `cli` interpreta los argumentos; `--help`, `--version` y los errores de uso terminan ahí.
3. **El texto**, en este orden: `--text`, la entrada estándar (`--stdin` o `-`), los argumentos sueltos unidos por espacios, y si no hay nada de eso, el portapapeles. Un texto vacío o solo con espacios es un error, no un QR vacío.
4. `qr.Encode` arma la matriz con el nivel pedido y la mejor máscara.
5. **El dibujo**: `TerminalLines` convierte la matriz en líneas de medios bloques con el borde pedido, y la herramienta las centra en el ancho de la ventana. Por defecto invierte: en una consola oscura el módulo claro se pinta y el oscuro queda del color del fondo, que es lo que un lector espera ver.
6. Con `-o`, el PNG: `--scale` píxeles por módulo y un borde de al menos 4 módulos, el mínimo que pide el estándar (en la terminal se usan 2 para ahorrar lugar).
7. La tarjeta final muestra el contenido (recortado a 48 caracteres, con los saltos de línea como `⏎`), la longitud, de dónde salió, la versión y el lado, el nivel y el PNG si se guardó.

## qr: el codificador

**Datos**

- **Modo**: se elige el más compacto que cubre el texto entero: numérico (3 dígitos en 10 bits), alfanumérico (2 caracteres del juego de 45 en 11 bits) o byte (UTF-8 tal cual). Las minúsculas no están en el juego alfanumérico: una URL en minúsculas va en modo byte.
- **Versión**: la más chica en la que entran el indicador de modo, la cuenta (cuyo largo depende del modo y de la franja de versiones: 1–9, 10–26, 27–40) y los datos. Si no entra ni en la 40, `ErrTooLong`.
- **Relleno**: terminador de hasta 4 ceros, alineación al byte y los bytes alternados `0xEC 0x11` hasta completar la capacidad.

**Tablas**

- Solo tres arreglos base: codewords totales por versión, corrección por bloque y cantidad de bloques, por versión y nivel. El reparto en dos grupos de bloques (los del segundo llevan un codeword de datos más) se deriva con la regla del estándar en vez de tabular a mano las 160 combinaciones: menos superficie para un error de transcripción.

**Corrección de errores**

- **GF(256)** con el polinomio `x⁸+x⁴+x³+x²+1` (0x11d) y tablas de exponenciales y logaritmos: una multiplicación son dos búsquedas.
- **Reed–Solomon**: el polinomio generador se memoiza por grado, con el coeficiente líder primero; ese orden fue el bug que impedía leer los códigos (ver [VERIFICACION.md](VERIFICACION.md)).
- **Entrelazado**: los codewords de datos se toman columna por columna entre los bloques, y después los de corrección igual. Así una ráfaga de daño (una mancha, un reflejo en la pantalla) se reparte entre varios bloques y cada uno la puede corregir.

**Matriz**

- Patrones de búsqueda con sus separadores, patrones de alineación (desde la versión 2), líneas de sincronización y el módulo oscuro fijo.
- Información de formato (nivel y máscara) con BCH(15,5) y la máscara XOR del estándar, en sus dos copias; información de versión con BCH(18,6) desde la versión 7.
- Colocación de los datos en zigzag de a dos columnas, de abajo hacia arriba y de arriba hacia abajo, esquivando la columna 6 y los módulos reservados.
- **Máscara**: se prueban las 8 y se queda la de menor penalización según las cuatro reglas: tiradas de 5 o más módulos iguales, bloques de 2×2, patrones parecidos a un buscador y el desbalance entre claros y oscuros. Cuesta O(8 · n²) con n el lado de la matriz.

**Salidas**

- `TerminalLines`: dos filas de módulos por renglón con `▀`, `▄`, `█` y espacio.
- `Image`: una imagen en escala de grises de `escala` píxeles por módulo, con el borde pedido.

## El núcleo

### win/desk: el portapapeles y la consola

- El portapapeles se lee en `CF_UNICODETEXT` (UTF-16) y se decodifica a UTF-8. Abrirlo se reintenta unos instantes, porque otro programa puede tenerlo tomado.
- La memoria del portapapeles se copia con `RtlMoveMemory` a un búfer de Go, con un tope de 16 millones de caracteres: nunca se reinterpreta un puntero nativo como puntero de Go.
- `user32.dll` se carga por ruta absoluta de System32. Con el nombre pelado, `LoadLibrary` buscaría primero junto al exe, y un DLL plantado ahí ganaría.
- El envoltorio de las llamadas lleva `//go:uintptrescapes`: sin esa directiva, un búfer que viaja como `uintptr` puede quedar en la pila de la goroutine, y si la pila crece entre la conversión y la llamada, Windows escribe en la pila vieja.
- Además da el modo y el tamaño de la consola, que usa `tui`. Es chico a propósito: un test (`internal/tui/deps_test.go`) comprueba con `go list -deps` que ni `tui` ni el exe cargan `net`, `net/netip` u `os/exec`.

### tui

- Paleta pastel sobre negro, cabecera, tarjeta de resumen (fondo apenas teñido, sin bordes) y formato es-AR (miles con punto, decimales con coma).
- El ancho de la ventana (lo usa el centrado del QR): sin consola vale `COLUMNS` o, si no está, 100 columnas; nunca más de 180.
- Sin consola, o con `--no-color` o `NO_COLOR`, ningún escape de color.
- También trae la región de progreso vivo y las tablas que ceden ancho, que clip2qr no usa.

### cli

- Flags al estilo GNU: `-e h`, `--level=h`, `-o x`, `--png=x`, `--`.
- Binders tipados con validación: enteros acotados (`--quiet` 0–10, `--scale` 1–64) y enumerados (`--level`).
- La ayuda se genera con el mismo lenguaje visual que el resto de la salida, al ancho real de la ventana.
- Un flag mal escrito sugiere el más parecido por distancia de Damerau–Levenshtein (`textdist`): programación dinámica en O(n·m) con tres filas rodantes, y la transposición de dos letras cuenta como un solo error.

### fsx

- `WriteAtomic`: temporal en la misma carpeta y renombre al final, reintentando con espera exponencial si un antivirus o un visor tienen el destino abierto un instante.

### version

`Version` y `Commit` son variables que `build.ps1` pisa con `-ldflags -X`: `clip2qr --version` dice `1.0.0+abc1234`. Compilado con `go install`, dice `1.0.0`.
