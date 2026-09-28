//go:build ignore

// gen.go emite un lote de PNGs de QR variados (modos, niveles, tamaños) a una
// carpeta, con un manifiesto de qué texto lleva cada uno, para que un
// decodificador externo (zxing) verifique que se leen y coinciden.
package main

import (
	"encoding/json"
	"fmt"
	"image/png"
	"os"
	"path/filepath"
	"strings"

	"github.com/agustinyarrus/clip2qr/internal/qr"
)

func main() {
	out := os.Args[1]
	os.MkdirAll(out, 0o755)

	casos := []string{
		"https://github.com/agustinyarrus/clip2qr",
		"12345678901234567890",
		"HELLO WORLD 123 $%*+-./:",
		"café con leche y medialunas — ñandú",
		"WIFI:S:MiRed;T:WPA;P:clave-secreta-123;;",
		strings.Repeat("A", 300),
		strings.Repeat("dato variado 0123 ", 40),
		"x",
		"BEGIN:VCARD\nFN:Agustín\nEND:VCARD",
		"מבחן unicode 日本語 test",
		strings.Repeat("9", 500),           // numérico largo → versión alta
		strings.Repeat("ABCDE12345 ", 120), // alfanumérico enorme
		strings.Repeat("λ", 400),           // bytes multibyte, versión grande
		"tel:+54 9 11 5555-5555",
		"mailto:test@example.com?subject=hola",
	}
	niveles := []qr.Level{qr.L, qr.M, qr.Q, qr.H}

	type entry struct {
		File  string `json:"file"`
		Text  string `json:"text"`
		Level string `json:"level"`
		Ver   int    `json:"version"`
		Mask  int    `json:"mask"`
	}
	var manifest []entry

	idx := 0
	for _, texto := range casos {
		for _, lvl := range niveles {
			m, err := qr.Encode([]byte(texto), qr.Options{Level: lvl, Mask: -1})
			if err != nil {
				fmt.Fprintf(os.Stderr, "encode falló (%q, %s): %v\n", texto, lvl, err)
				continue
			}
			name := fmt.Sprintf("qr_%03d.png", idx)
			f, _ := os.Create(filepath.Join(out, name))
			png.Encode(f, m.Image(6, 4))
			f.Close()
			manifest = append(manifest, entry{name, texto, lvl.String(), m.Version, m.Mask})
			idx++
		}
	}
	// El borde de arriba: el texto más largo que entra en la versión 40, por
	// modo y por nivel (tabla 7 de ISO/IEC 18004). Si zxing los lee, las tablas
	// de bloques de la 40 y el indicador de cuenta largo están bien.
	limites := []struct {
		letra      string
		l, m, q, h int
	}{
		{"7", 7089, 5596, 3993, 3057}, // numérico
		{"K", 4296, 3391, 2420, 1852}, // alfanumérico
		{"k", 2953, 2331, 1663, 1273}, // byte
	}
	for _, lim := range limites {
		for i, n := range []int{lim.l, lim.m, lim.q, lim.h} {
			texto := strings.Repeat(lim.letra, n)
			m, err := qr.Encode([]byte(texto), qr.Options{Level: niveles[i], Mask: -1})
			if err != nil {
				fmt.Fprintf(os.Stderr, "encode falló (%d × %q, %s): %v\n", n, lim.letra, niveles[i], err)
				continue
			}
			name := fmt.Sprintf("qr_%03d.png", idx)
			f, _ := os.Create(filepath.Join(out, name))
			png.Encode(f, m.Image(6, 4))
			f.Close()
			manifest = append(manifest, entry{name, texto, niveles[i].String(), m.Version, m.Mask})
			idx++
		}
	}

	mf, _ := os.Create(filepath.Join(out, "manifest.json"))
	json.NewEncoder(mf).Encode(manifest)
	mf.Close()
	fmt.Printf("%d PNGs de QR en %s\n", idx, out)
}
