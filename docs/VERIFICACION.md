# Verificación

La regla: clip2qr se contrasta con algo **independiente**. Un QR que solo entiende el propio codificador no prueba nada; zxing-cpp, un decodificador independiente y muy usado, sí.

## Tests de Go

```powershell
go test ./...
.\build.ps1 -Test     # go vet + go test y después compila
```

56 tests en `cli`, `fsx`, `textdist`, `tui`, `win/desk` y `qr`. Los de `qr`:

- `TestReedSolomonVector`: los bytes de corrección de "HELLO" en 1-M, verificados con un decodificador externo. Es la guardia contra la regresión del orden del polinomio generador (abajo, la lección).
- `TestCapacidadVersion40`: los límites de la versión 40 de la tabla 7 de ISO/IEC 18004, por modo (numérico, alfanumérico, byte) y nivel. El texto más largo que entra da versión 40 y uno más da error: prueba juntas las tablas de capacidad, el largo del indicador de cuenta y la elección de versión en el borde de arriba.
- La detección de modo, la elección de versión, el lado `17 + 4v`, la máscara en 0..7, los tres buscadores, el módulo oscuro fijo y que un dato imposible da error y no un pánico.

Hay también un test de dependencias: `go list -deps` sobre `tui` y el exe no puede traer `net`, `net/netip` ni `os/exec`.

## Oráculos

Requisitos: Python 3 con `pip install zxing-cpp pillow`.

### El codificador contra zxing-cpp

```powershell
go run .\internal\qr\_oracle\gen.go <carpeta>          # los PNG y un manifest.json con el texto de cada uno
python .\internal\qr\_oracle\decode.py <carpeta>       # zxing-cpp los decodifica y compara
```

`gen.go` emite 72 códigos:

- 15 textos × 4 niveles: una URL, dígitos, mayúsculas con los nueve símbolos del modo alfanumérico, español con tildes, ñ y raya, una red Wi-Fi, una vCard, hebreo con japonés, `tel:` y `mailto:`, repeticiones largas en cada modo y un solo carácter;
- los 12 textos más largos que entran en la versión 40, uno por modo y por nivel.

Resultado: 72 de 72, de la versión 1 a la 40.

### El dibujo de la terminal contra zxing-cpp

```powershell
clip2qr --text "hola" --no-color | python .\internal\qr\_oracle\terminal_check.py "hola"
clip2qr --text "hola" --no-color -i | python .\internal\qr\_oracle\terminal_check.py "hola" --invert
```

El PNG no es lo que se escanea casi nunca: lo que lee el teléfono es la pantalla. `terminal_check.py` toma la salida real de `clip2qr.exe`, reconstruye la matriz desde los medios bloques (cada carácter son dos módulos), la pasa a imagen y la decodifica con zxing-cpp. Así se prueban juntos el recorrido de `TerminalLines`, la inversión y el borde.

Resultado: 15 de 15 (cinco textos, de "hola" a 300 letras, cada uno normal, invertido y con nivel H y borde 4). Con un texto esperado distinto, el guion falla, como tiene que ser.

**Lección:** al principio ningún código se podía leer. Comparando la matriz módulo a módulo con la de `segno` (otro codificador, en Python) se vio que los datos coincidían y la corrección no: el polinomio generador de Reed–Solomon estaba en orden inverso. `TestReedSolomonVector` fija ahora los bytes correctos de un vector conocido.

## Corrida del 28/09/2026, ya como proyecto propio

Con el `clip2qr.exe` que compila este repo (1.0.0), en Windows 11 con Go 1.26.4 y zxing-cpp 3:

| Qué | Resultado |
|---|---|
| `gofmt -l .`, `go vet ./...` | limpios |
| `go test ./...` | 56 de 56 |
| `gen.go` + `decode.py` | 72 de 72, doce de ellos en la versión 40 |
| `terminal_check.py` | 15 de 15 |
| `--png` de una URL, leído por zxing-cpp | el mismo texto |

Lo que no se prueba automáticamente es leer el portapapeles de verdad: ni los tests ni los oráculos tocan el portapapeles de quien los corre.
