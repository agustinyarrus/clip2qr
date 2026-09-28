//go:build windows

// clip2qr dibuja un código QR del portapapeles (o de un texto) en la terminal.
package main

import (
	"os"

	"github.com/agustinyarrus/clip2qr/internal/clip2qr"
	"github.com/agustinyarrus/clip2qr/internal/tui"
	"github.com/agustinyarrus/clip2qr/internal/version"
)

func main() {
	t := tui.Open()
	defer t.Close()
	os.Exit(clip2qr.Main(t, version.String(), os.Args[1:]))
}
