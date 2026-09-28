# Verificación

La regla: clip2qr se contrasta con algo **independiente**. Un QR que solo entiende el propio codificador no prueba nada; zxing-cpp, un decodificador independiente y muy usado, sí.

## Tests de Go

```powershell
go test ./...
.\build.ps1 -Test     # go vet + go test y después compila
```

58 tests en `cli`, `fsx`, `textdist`, `tui`, `win/desk` y `qr`. Los de `qr`:

- `TestReedSolomonVector`: los bytes de corrección de "HELLO" en 1-M, verificados con un decodificador externo. Es la guardia contra la regresión del orden del polinomio generador (abajo, la lección).
- `TestCapacidadVersion40`: los límites de la versión 40 de la tabla 7 de ISO/IEC 18004, por modo (numérico, alfanumérico, byte) y nivel. El texto más largo que entra da versión 40 y uno más da error: prueba juntas las tablas de capacidad, el largo del indicador de cuenta y la elección de versión en el borde de arriba.
- La detección de modo, la elección de versión, el lado `17 + 4v`, la máscara en 0..7, los tres buscadores, el módulo oscuro fijo y que un dato imposible da error y no un pánico.

Hay también un test de dependencias: `go list -deps` sobre `tui` y el exe no puede traer `net`, `net/netip` ni `os/exec`.

## Oráculos

Requisitos: Python 3 con `pip install -r internal/qr/_oracle/requirements.txt` (zxing-cpp y Pillow, en las versiones con que se verificó).

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
.\internal\qr\_oracle\terminal_all.ps1 -Exe dist\clip2qr.exe      # los 15 casos y el control, de una vez
clip2qr --text "hola" --no-color | python .\internal\qr\_oracle\terminal_check.py "hola"
clip2qr --text "hola" --no-color -i | python .\internal\qr\_oracle\terminal_check.py "hola" --invert
```

El PNG no es lo que se escanea casi nunca: lo que lee el teléfono es la pantalla. `terminal_check.py` toma la salida real de `clip2qr.exe`, reconstruye la matriz desde los medios bloques (cada carácter son dos módulos), la pasa a imagen y la decodifica con zxing-cpp. Así se prueban juntos el recorrido de `TerminalLines`, la inversión y el borde.

Resultado: 15 de 15 (cinco textos: "hola", una URL, una red de Wi-Fi, español con tildes y ñ, y 300 letras; cada uno normal, invertido y con nivel H y borde 4). `terminal_all.ps1` termina con un control: el mismo dibujo con otro texto esperado tiene que fallar, y falla.

**Lección:** al principio ningún código se podía leer. Comparando la matriz módulo a módulo con la de `segno` (otro codificador, en Python) se vio que los datos coincidían y la corrección no: el polinomio generador de Reed–Solomon estaba en orden inverso. `TestReedSolomonVector` fija ahora los bytes correctos de un vector conocido.

## En la CI

Cada push corre [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) en `windows-latest`, con el Go mínimo del `go.mod` (1.26.0): `gofmt`, `go mod tidy -diff`, `go vet ./...` (también con `GOOS=linux`), todas las pruebas con el resumen de [`.github/pruebas.ps1`](../.github/pruebas.ps1), `build.ps1` y el `.exe` con su versión y su commit; con ese `.exe`, los dos oráculos de zxing-cpp (`gen.go` + `decode.py` y `terminal_all.ps1`, con Python 3.12 y los paquetes de [`requirements.txt`](../internal/qr/_oracle/requirements.txt)); y al final `SHA256SUMS` y el `.exe` como artefacto.

La CI no corrió todavía en GitHub (el repo no se publicó). Se validó con [actionlint](https://github.com/rhysd/actionlint) y se simuló en la PC de desarrollo: un clon limpio, Go 1.26.0, cachés vacías, un Python 3.12 recién creado y los pasos `run:` del workflow con el mismo envoltorio de PowerShell que usa el runner. Todos en verde.

## Corrida del 28/09/2026, ya como proyecto propio

Con el `clip2qr.exe` que compila este repo (1.0.0), en Windows 11 con Go 1.27.1 y Python 3.12 con zxing-cpp 3.1.1:

| Qué | Resultado |
|---|---|
| `gofmt -l .`, `go vet ./...` (Windows y Linux) | limpios |
| `go test ./...` | 58 de 58 |
| `gen.go` + `decode.py` | 72 de 72, doce de ellos en la versión 40 |
| `terminal_all.ps1` | 15 de 15, y el control falla como tiene que fallar |
| `--png` de una red de Wi-Fi con nivel H, leído por zxing-cpp | el mismo texto |
| el último cuadro del GIF de la demo, leído por zxing-cpp | la URL exacta |
| la CI simulada con Go 1.26.0 | todos los pasos en verde |

Lo que no se prueba automáticamente es leer el portapapeles de verdad: ni los tests ni los oráculos tocan el portapapeles de quien los corre.
