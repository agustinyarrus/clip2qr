# Verifica el dibujo de la TERMINAL, no el PNG: reconstruye la matriz a partir
# de los medios bloques que imprime clip2qr, la pasa a imagen y la decodifica
# con zxing-cpp. Si el texto coincide, lo que ve el teléfono en la pantalla es
# un QR válido con el contenido pedido.
#
#   clip2qr --text "hola" --no-color | python terminal_check.py "hola"
#   clip2qr --text "hola" --no-color -i | python terminal_check.py "hola" --invert
#
# Sin --invert (lo normal en una consola oscura) el bloque pintado es un módulo
# CLARO; con -i en clip2qr, es uno oscuro.
import argparse
import io
import sys

import zxingcpp
from PIL import Image

p = argparse.ArgumentParser()
p.add_argument("esperado")
p.add_argument("--invert", action="store_true")
a = p.parse_args()

texto = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8").read()
bloques = set("█▀▄ ")
lineas = [l.rstrip() for l in texto.splitlines()]
lineas = [l for l in lineas if l.strip() and set(l) <= bloques]
if not lineas:
    sys.exit("✗ no encontré el dibujo del QR en la entrada")
margen = min(len(l) - len(l.lstrip(" ")) for l in lineas)
lineas = [l[margen:] for l in lineas]
ancho = max(len(l) for l in lineas)

# Cada carácter son dos módulos apilados: arriba y abajo.
filas = []
for l in lineas:
    l = l.ljust(ancho)
    filas.append([c in "█▀" for c in l])
    filas.append([c in "█▄" for c in l])
pintado_es_claro = not a.invert
# Una fila sin nada pintado al final es la mitad vacía del último carácter.
while filas and not any(filas[-1]):
    filas.pop()

escala, borde = 8, 4
alto = len(filas)
img = Image.new("L", ((ancho + 2 * borde) * escala, (alto + 2 * borde) * escala), 255)
px = img.load()
for y, fila in enumerate(filas):
    for x, pintado in enumerate(fila):
        claro = pintado if pintado_es_claro else not pintado
        if not claro:
            for dy in range(escala):
                for dx in range(escala):
                    px[(x + borde) * escala + dx, (y + borde) * escala + dy] = 0

res = zxingcpp.read_barcodes(img)
leido = res[0].text if res else None
if leido == a.esperado:
    print(f"✓ el dibujo de la terminal ({ancho}×{alto} módulos) dice lo esperado")
    sys.exit(0)
print(f"✗ zxing leyó {leido!r}, esperaba {a.esperado!r}")
sys.exit(1)
