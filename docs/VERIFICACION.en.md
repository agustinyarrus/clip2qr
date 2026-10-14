<p align="right"><sub><b>English</b> · <a href="VERIFICACION.md">Español</a></sub></p>

# Verification

The rule: clip2qr is checked against something **independent**. A QR that only its own encoder understands proves nothing; zxing-cpp, an independent and widely used decoder, does.

## Go tests

```powershell
go test ./...
.\build.ps1 -Test     # go vet + go test and then builds
```

58 tests in `cli`, `fsx`, `textdist`, `tui`, `win/desk` and `qr`. The ones in `qr`:

- `TestReedSolomonVector`: the correction bytes of "HELLO" at 1-M, verified with an external decoder. It's the guard against the regression in the order of the generator polynomial (below, the lesson).
- `TestCapacidadVersion40`: the version 40 limits from table 7 of ISO/IEC 18004, per mode (numeric, alphanumeric, byte) and level. The longest text that fits gives version 40 and one more gives an error: it tests together the capacity tables, the length of the count indicator and the choice of version at the top edge.
- Mode detection, version choice, the `17 + 4v` side, the mask in 0..7, the three finders, the fixed dark module and that impossible data gives an error and not a panic.

There's also a dependency test: `go list -deps` on `tui` and the exe can't pull in `net`, `net/netip` or `os/exec`.

## Oracles

Requirements: Python 3 with `pip install -r internal/qr/_oracle/requirements.txt` (zxing-cpp and Pillow, in the versions it was verified with).

### The encoder against zxing-cpp

```powershell
go run .\internal\qr\_oracle\gen.go <carpeta>          # the PNGs and a manifest.json with the text of each one
python .\internal\qr\_oracle\decode.py <carpeta>       # zxing-cpp decodes them and compares
```

`gen.go` emits 72 codes:

- 15 texts × 4 levels: a URL, digits, uppercase with the nine symbols of alphanumeric mode, Spanish with accents, ñ and em dash, a Wi-Fi network, a vCard, Hebrew with Japanese, `tel:` and `mailto:`, long repetitions in each mode and a single character;
- the 12 longest texts that fit in version 40, one per mode and per level.

Result: 72 of 72, from version 1 to 40.

### The terminal drawing against zxing-cpp

```powershell
.\internal\qr\_oracle\terminal_all.ps1 -Exe dist\clip2qr.exe      # the 15 cases and the control, in one go
clip2qr --text "hola" --no-color | python .\internal\qr\_oracle\terminal_check.py "hola"
clip2qr --text "hola" --no-color -i | python .\internal\qr\_oracle\terminal_check.py "hola" --invert
```

The PNG is almost never what gets scanned: what the phone reads is the screen. `terminal_check.py` takes the real output of `clip2qr.exe`, rebuilds the matrix from the half blocks (each character is two modules), turns it into an image and decodes it with zxing-cpp. That way `TerminalLines`' path, the inversion and the border are tested together.

Result: 15 of 15 (five texts: "hola", a URL, a Wi-Fi network, Spanish with accents and ñ, and 300 letters; each one normal, inverted and at level H with border 4). `terminal_all.ps1` ends with a control: the same drawing with a different expected text has to fail, and it fails.

**Lesson:** at first no code could be read. Comparing the matrix module by module with `segno`'s (another encoder, in Python) showed that the data matched and the correction didn't: the Reed–Solomon generator polynomial was in reverse order. `TestReedSolomonVector` now pins the correct bytes of a known vector.

## In the CI

Every push runs [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) on `windows-latest`, with the minimum Go from the `go.mod` (1.26.0): `gofmt`, `go mod tidy -diff`, `go vet ./...` (also with `GOOS=linux`), all the tests with the summary from [`.github/pruebas.ps1`](../.github/pruebas.ps1), `build.ps1` and the `.exe` with its version and its commit; with that `.exe`, both zxing-cpp oracles (`gen.go` + `decode.py` and `terminal_all.ps1`, with Python 3.12 and the packages from [`requirements.txt`](../internal/qr/_oracle/requirements.txt)); and at the end `SHA256SUMS` and the `.exe` as an artifact.

The CI hadn't run on GitHub yet (the repo hadn't been published). It was validated with [actionlint](https://github.com/rhysd/actionlint) and simulated on the development PC: a clean clone, Go 1.26.0, empty caches, a freshly created Python 3.12 and the workflow's `run:` steps with the same PowerShell wrapper the runner uses. All green.

## Run of Sep 28, 2026, already as a project of its own

With the `clip2qr.exe` this repo builds (1.0.0), on Windows 11 with Go 1.27.1 and Python 3.12 with zxing-cpp 3.1.1:

| What | Result |
|---|---|
| `gofmt -l .`, `go vet ./...` (Windows and Linux) | clean |
| `go test ./...` | 58 of 58 |
| `gen.go` + `decode.py` | 72 of 72, twelve of them at version 40 |
| `terminal_all.ps1` | 15 of 15, and the control fails as it should |
| `--png` of a Wi-Fi network at level H, read by zxing-cpp | the same text |
| the last frame of the demo GIF, read by zxing-cpp | the exact URL |
| the CI simulated with Go 1.26.0 | every step green |

What isn't tested automatically is reading the real clipboard: neither the tests nor the oracles touch the clipboard of whoever runs them.

<!-- i18n source=VERIFICACION.md sha256=759102b74f96 -->
