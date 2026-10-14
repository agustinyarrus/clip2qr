<p align="right"><sub><b>English</b> · <a href="PENDIENTE.md">Español</a></sub></p>

# To do

clip2qr is finished and verified ([VERIFICACION.en.md](VERIFICACION.en.md)). What follows are improvements, in the order it's best to do them.

## Encoder

- **Mixed-mode segments.** Today a single mode is picked for the whole text: a URL with a long number at the end goes entirely in byte mode. The standard allows splitting the data into segments (numeric, alphanumeric and byte) and picking the cuts with dynamic programming; on mixed texts the code comes out one or two versions smaller, easier to read from afar.
- **ECI for UTF-8.** Byte mode goes without declaring the encoding and readers guess UTF-8 (zxing gets it right in every oracle case, Hebrew and Japanese included). An ECI 26 header would declare it; it's worth adding only when the text isn't ASCII, and measuring first with several phone readers that nothing breaks.
- **Kanji mode**, for Japanese text in Shift JIS: less useful than the previous ones, because almost everything that gets copied is UTF-8.

## Tool

- `--copy`: leave the PNG on the clipboard, to paste it straight into a chat or a document.
- An automated clipboard test that saves the user's content, writes its own, reads it with clip2qr and restores the original, without losing anything if it's interrupted halfway.

## Distribution

- Done: the CI ([`ci.yml`](../.github/workflows/ci.yml)) runs the tests and both zxing-cpp oracles on every push; the 1.0.0 release is ready to publish ([RELEASE.en.md](RELEASE.en.md)).
- Missing: publishing it, and seeing the CI's first run on GitHub (it was simulated on the PC, it didn't run on a real runner).

<!-- i18n source=PENDIENTE.md sha256=53bef709ff43 -->
