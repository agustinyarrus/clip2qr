<p align="right"><sub><b>English</b> · <a href="LEEME.md">Español</a></sub></p>

# The clip2qr demo

`demo.gif` and `demo.webm` are a real recording, not a mockup: a 100×30 terminal runs
clip2qr built from this repo with a URL. What you see is the real output of that run, and the
code can be read: the last frame of the GIF, run through zxing-cpp, gives
`https://github.com/agustinyarrus/clip2qr`.

| Moment | What you see |
|---|---|
| 0 to 4.4 s | `clip2qr --text "https://github.com/agustinyarrus/clip2qr"` is typed |
| 4.5 s to the end | the QR (version 3, 29×29 modules, level M) in half blocks and the card: content, length, where the text came from, version and correction |

With the command and the prompt that comes back, the session takes 34 lines (the header, the QR with its
border and the card with its margin) and the window has 30: when it ends, the screen scrolls up four
lines and the last frame shows the QR and the card in full, without the command line or the
header. That's what any terminal of that size does.

## What's here

| File | What it's for |
|---|---|
| `demo.tape` | the [VHS](https://github.com/charmbracelet/vhs) script: it sets up the scene off camera, records and tears it down |
| `preparar.ps1` | builds clip2qr from this repo into `.escena\bin` (or deletes it with `-Limpiar`) |
| `demo.gif` · `demo.webm` | the recording: 8.6 s at 25 frames per second, 1078×644, 96 KB and 68 KB |
| `demo.png` | the last frame, the QR with the card, paletted like the GIF (for those who ask for less motion; it also reads with zxing-cpp) |

## Re-recording with VHS

You need Windows, PowerShell 7 and Go, and also:

```powershell
winget install --scope user charmbracelet.vhs tsl0922.ttyd Gyan.FFmpeg
```

**Watch out for the VHS version.** 0.12.0 (winget's as of Sep 28, 2026) records the frames but
generates neither the GIF nor the WebM, without giving an error: it cancels the recording's context and passes it to
ffmpeg. It's fixed in 0.12.1:

```powershell
go install github.com/charmbracelet/vhs@v0.12.1     # needs Go 1.26.7+; Go downloads that version on its own
```

VHS draws the terminal in a windowless Chrome or Edge: it uses whichever is installed, it doesn't download
Chromium. Then, from this folder:

```powershell
Remove-Item Env:NO_COLOR -ErrorAction SilentlyContinue     # if your environment defines it, the demo comes out without color
vhs demo.tape                                             # demo.gif and demo.webm
ffmpeg -y -sseof -0.5 -i demo.gif -frames:v 1 -vf "split[a][b];[a]palettegen[p];[b][p]paletteuse=dither=none" demo.png
```

It takes about 20 seconds. Always look at the result before publishing it: individual frames with
`ffmpeg -ss 6 -i demo.gif -frames:v 1 cuadro.png`, and that the QR reads (with the phone, or with
`python -c "import zxingcpp; from PIL import Image; print(zxingcpp.read_barcodes(Image.open('demo.png'))[0].text)"`
and the packages from [`requirements.txt`](../internal/qr/_oracle/requirements.txt)).

### What the scene does, and why

- **Nothing from your machine on screen.** The text goes with `--text`: plain clip2qr would read the
  clipboard of whoever is recording. Neither the header nor the card shows a path.
- **clip2qr from this repo.** `preparar.ps1` builds it without a stamped commit: the header says
  `v1.0.0`, not `v1.0.0+abc1234`.
- **The prompt is `>` and nothing else**, without history suggestions (they'd be the recorder's), with
  the command line's colors in clip2qr's palette. The tape sets them off camera.

### Style

The same as the family's other demos: background `#0b0b0f`, text `#cdd6f4` and the accents from
`internal/tui/color.go` as the theme's ANSI colors; Cascadia Mono 16; 1078×644 px, which with a 24 px
margin gives 100×30. Typing at 60 to 85 ms per key. 25 frames per second: at 50, the browser can't
capture every frame in time and the video comes out sped up.

## Without VHS

The same session can be recorded by hand, with a screen recorder like
[ScreenToGif](https://www.screentogif.com) on a 100×30 terminal with a `#0b0b0f` background and
Cascadia Mono (`wt --size 100,30 pwsh -NoProfile`). From this folder:

```powershell
$env:Path = (.\preparar.ps1) + ";$env:Path"      # builds clip2qr and puts it first on the PATH
clip2qr --text "https://github.com/agustinyarrus/clip2qr"
.\preparar.ps1 -Limpiar
```

<!-- i18n source=LEEME.md sha256=935317390836 -->
