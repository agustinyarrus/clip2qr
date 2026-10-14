<p align="right"><sub><b>English</b> · <a href="release-v1.0.0.md">Español</a></sub></p>

# clip2qr 1.0.0

The first version of clip2qr as a project of its own. It used to live in navaja, the suite of console tools for Windows; the code is the one that was tested there, with new tests at the standard's top edge (the version 40 limits, per mode and per level), the header with the version and its `v`, and errors that don't fit in the window wrapped by words. Now it has its own repo, its version number, its CI and its demo.

clip2qr is for getting something from the PC to the phone without sending yourself a message: you copy a URL, a Wi-Fi password or a text, run `clip2qr` and scan it with the camera straight from the terminal.

## What it brings

**A QR of the clipboard, in the terminal.** Plain `clip2qr` takes whatever is on the clipboard; `--text "…"`, a loose argument or standard input (`-`, `--stdin`) work too. The code is drawn with half blocks (`▀ ▄ █`): each character is two modules, so it comes out square, takes half the lines and is centered in the window. Below, a card with the content, where it came from, the QR version and the correction level.

**Its own encoder, no dependencies.** Numeric, alphanumeric and byte (UTF-8) modes, versions 1 to 40, levels L, M, Q and H, Reed–Solomon over GF(256) and the best of the 8 masks according to the standard's penalty rules. It picks on its own the most compact mode and the smallest version the text fits in.

**Made for dark consoles.** By default it swaps light and dark, so the phone's reader sees dark ink on a light background; `-i` is for light-background terminals.

**PNG, if needed.** `-o wifi.png` also saves the code as an image, with `--scale` pixels per module and the 4-module border the standard asks for, written atomically.

**All local.** The text never leaves the machine. If the output isn't a console, plain text without a single color escape code. Exit codes: `0` all good, `2` invalid command line, `3` it couldn't be done (the clipboard has no text, or the text doesn't fit even in version 40).

## Download

`clip2qr.exe` is the whole program: 64-bit Windows 10 or 11 (it was tested on Windows 11), a single file, no installer. Copy it to a folder on your `PATH`. Or, with Go:

```powershell
go install github.com/agustinyarrus/clip2qr@v1.0.0
```

To check the download, in the folder where the two files ended up:

```powershell
(Get-FileHash .\clip2qr.exe -Algorithm SHA256).Hash -eq ((Get-Content .\SHA256SUMS) -split '\s+')[0]   # True
```

In Git Bash or WSL, `sha256sum -c SHA256SUMS`. The `.exe` is reproducible: the same tag with the same Go gives the same bytes, so anyone can build it and compare ([how](https://github.com/agustinyarrus/clip2qr/blob/v1.0.0/docs/RELEASE.md#5-el-exe-es-reproducible)).

## How it was verified

- clip2qr isn't checked against itself: zxing-cpp, an independent decoder, reads 72 of 72 codes from the encoder (15 texts by 4 levels, with accents, Hebrew and Japanese, and the 12 longest texts that fit in version 40) and 15 of 15 drawings that clip2qr prints in the terminal, rebuilt from the half blocks: what the phone really scans.
- 58 Go tests, among them the Reed–Solomon vector that pins the order of the generator polynomial (that order was the bug that at first kept any code from being read) and the version 40 limits.
- CI configured for `windows-latest` with the minimum Go from the `go.mod`: formatting, `go vet` (for Linux too), all the tests, both zxing-cpp oracles and the `.exe` with its version and its SHA256. This version was verified with the same sequence on a clean clone, before publishing it.

The details, in [docs/VERIFICACION.md](https://github.com/agustinyarrus/clip2qr/blob/v1.0.0/docs/VERIFICACION.md); the architecture and the encoder step by step, in [docs/ARQUITECTURA.md](https://github.com/agustinyarrus/clip2qr/blob/v1.0.0/docs/ARQUITECTURA.md).

## What's missing

- **Reading the clipboard has no automated test.** Neither the tests nor the oracles touch the clipboard of whoever runs them (that would overwrite what they have copied); the oracles test everything else by passing the text with `--text`.
- **Mixed-mode segments.** Today the whole text goes in a single mode: a URL with a long number at the end goes entirely in byte mode, and the code comes out one or two versions bigger than needed.
- `--copy`, to leave the PNG on the clipboard.

The list, in [docs/PENDIENTE.md](https://github.com/agustinyarrus/clip2qr/blob/v1.0.0/docs/PENDIENTE.md).

<!-- i18n source=release-v1.0.0.md sha256=92fef7471670 -->
