<p align="right"><sub><b>English</b> · <a href="ARQUITECTURA.md">Español</a></sub></p>

# Architecture

## Principles

- **Pure Go, no CGO and no external modules.** clip2qr builds into a single static `.exe`. Calls into Windows go through `syscall`, with no C bindings.
- **One responsibility per package.** The encoder (`qr`) knows nothing about consoles or clipboards: it takes bytes and returns a matrix of modules. The tool (`internal/clip2qr`) decides where the text comes from, how it's drawn and what gets saved.
- **Validate at the boundary.** Flags are interpreted and validated once, when parsing (level, border, scale); inside, the values are already of the right type.
- **Atomic writes.** The PNG goes to a temporary file in the same folder and is renamed at the end: a crash never leaves a half-written file or overwrites the previous one.
- **Visual output that degrades.** Pastel colors on black and a summary card in the console; plain text without a single escape code when the output is a pipe or a file.

## The path of a run

1. `main.go` opens the console (`tui.Open`), calls `clip2qr.Main` with the version and exits with the code it returns.
2. `cli` interprets the arguments; `--help`, `--version` and usage errors end there.
3. **The text**, in this order: `--text`, standard input (`--stdin` or `-`), the loose arguments joined with spaces, and if there's none of that, the clipboard. An empty or whitespace-only text is an error, not an empty QR.
4. `qr.Encode` builds the matrix with the requested level and the best mask.
5. **The drawing**: `TerminalLines` turns the matrix into lines of half blocks with the requested border, and the tool centers them in the window's width. By default it inverts: on a dark console the light module is painted and the dark one is left in the background color, which is what a reader expects to see.
6. With `-o`, the PNG: `--scale` pixels per module and a border of at least 4 modules, the minimum the standard asks for (in the terminal 2 are used to save room).
7. The final card shows the content (cut at 48 characters, with line breaks as `⏎`), the length, where it came from, the version and the side, the level and the PNG if one was saved.

## qr: the encoder

**Data**

- **Mode**: the most compact one that covers the whole text is picked: numeric (3 digits in 10 bits), alphanumeric (2 characters from the set of 45 in 11 bits) or byte (UTF-8 as is). Lowercase letters aren't in the alphanumeric set: a lowercase URL goes in byte mode.
- **Version**: the smallest one that fits the mode indicator, the count (whose length depends on the mode and on the version band: 1–9, 10–26, 27–40) and the data. If it doesn't fit even in 40, `ErrTooLong`.
- **Padding**: a terminator of up to 4 zeros, byte alignment and the alternating `0xEC 0x11` bytes until the capacity is filled.

**Tables**

- Only three base arrays: total codewords per version, correction per block and number of blocks, per version and level. The split into two groups of blocks (those in the second carry one more data codeword) is derived with the standard's rule instead of tabulating the 160 combinations by hand: less surface for a transcription mistake.

**Error correction**

- **GF(256)** with the polynomial `x⁸+x⁴+x³+x²+1` (0x11d) and exponent and logarithm tables: a multiplication is two lookups.
- **Reed–Solomon**: the generator polynomial is memoized per degree, with the leading coefficient first; that order was the bug that made the codes unreadable (see [VERIFICACION.en.md](VERIFICACION.en.md)).
- **Interleaving**: the data codewords are taken column by column across the blocks, and then the correction ones the same way. That way a burst of damage (a smudge, a glare on the screen) is spread across several blocks and each one can correct it.

**Matrix**

- Finder patterns with their separators, alignment patterns (from version 2), timing lines and the fixed dark module.
- Format information (level and mask) with BCH(15,5) and the standard's XOR mask, in its two copies; version information with BCH(18,6) from version 7.
- Placing the data in a zigzag two columns at a time, bottom to top and top to bottom, dodging column 6 and the reserved modules.
- **Mask**: all 8 are tried and the one with the lowest penalty is kept according to the four rules: runs of 5 or more equal modules, 2×2 blocks, patterns that look like a finder and the imbalance between light and dark. It costs O(8 · n²) with n the side of the matrix.

**Outputs**

- `TerminalLines`: two rows of modules per line with `▀`, `▄`, `█` and space.
- `Image`: a grayscale image of `escala` pixels per module, with the requested border.

## The core

### win/desk: the clipboard and the console

- The clipboard is read as `CF_UNICODETEXT` (UTF-16) and decoded to UTF-8. Opening it is retried for a few moments, because another program may be holding it.
- The clipboard's memory is copied with `RtlMoveMemory` into a Go buffer, capped at 16 million characters: a native pointer is never reinterpreted as a Go pointer.
- `user32.dll` is loaded by its absolute System32 path. With the bare name, `LoadLibrary` would look next to the exe first, and a DLL planted there would win.
- The wrapper for the calls carries `//go:uintptrescapes`: without that directive, a buffer that travels as a `uintptr` can end up on the goroutine's stack, and if the stack grows between the conversion and the call, Windows writes to the old stack.
- It also provides the console's mode and size, which `tui` uses. It's small on purpose: a test (`internal/tui/deps_test.go`) checks with `go list -deps` that neither `tui` nor the exe load `net`, `net/netip` or `os/exec`.

### tui

- A pastel palette on black, header, summary card (background barely tinted, no borders) and es-AR formatting (thousands with a period, decimals with a comma).
- The window's width (the QR centering uses it): without a console it's `COLUMNS` or, if that isn't set, 100 columns; never more than 180.
- Without a console, or with `--no-color` or `NO_COLOR`, no color escape codes at all.
- **Lines that don't fit**: errors (`✗`) are wrapped by words at the window's width, with the extra lines aligned after the mark (`Term.Marked`); into a pipe they go whole. Before, the console cut them wherever they fell.
- It also brings the live progress region and the tables that give up width, which clip2qr doesn't use.

### cli

- GNU-style flags: `-e h`, `--level=h`, `-o x`, `--png=x`, `--`.
- Typed binders with validation: bounded integers (`--quiet` 0–10, `--scale` 1–64) and enums (`--level`).
- The help is generated with the same visual language as the rest of the output, at the window's real width.
- A misspelled flag suggests the closest one by Damerau–Levenshtein distance (`textdist`): dynamic programming in O(n·m) with three rolling rows, and swapping two letters counts as a single error.

### fsx

- `WriteAtomic`: a temporary file in the same folder and a rename at the end, retrying with exponential backoff if an antivirus or a viewer holds the destination open for a moment.

### version

`Version` and `Commit` are variables that `build.ps1` overrides with `-ldflags -X`: `clip2qr --version` says `1.0.0+abc1234`. Built with `go install`, it says `1.0.0`.

<!-- i18n source=ARQUITECTURA.md sha256=9980c5049eee -->
