# demo.tape: la demo del README de clip2qr, grabada de verdad con VHS.
#
#   cd demo
#   vhs demo.tape            # escribe demo.gif y demo.webm
#
# Hace falta VHS 0.12.1 o más nuevo (la 0.12.0 no llega a llamar a ffmpeg),
# ttyd, ffmpeg y Go. Lo que se ve corre de verdad: preparar.ps1 compila
# clip2qr desde este repo y el QR sale de ese .exe. El texto va con --text:
# la demo no toca el portapapeles de quien graba. Detalles: LEEME.md.

Output demo.gif
Output demo.webm

Require pwsh
Require go

Set Shell "pwsh"
Set FontFamily "Cascadia Mono"
Set FontSize 16
Set Width 1078
Set Height 644
Set Padding 24
# 1078x644 con Cascadia Mono 16 y 24 de margen: 100 columnas x 30 filas.
Set Framerate 25
Set CursorBlink false
Set TypingSpeed 80ms
Set WaitTimeout 90s
# La paleta de clip2qr (internal/tui/color.go) sobre #0b0b0f.
Set Theme { "name": "clip2qr", "background": "#0b0b0f", "foreground": "#cdd6f4", "cursor": "#c4b5fd", "selection": "#2c2e38", "black": "#2c2e38", "red": "#f2a7b8", "green": "#b5dfa8", "yellow": "#eedfb8", "blue": "#c4b5fd", "magenta": "#f3b9d2", "cyan": "#8fd6cc", "white": "#cdd6f4", "brightBlack": "#55586b", "brightRed": "#f2a7b8", "brightGreen": "#b5dfa8", "brightYellow": "#eedfb8", "brightBlue": "#c4b5fd", "brightMagenta": "#f3b9d2", "brightCyan": "#8fd6cc", "brightWhite": "#ffffff" }

# Fuera de cámara: clip2qr de este repo primero en el PATH, un prompt ">"
# limpio, sin sugerencias del historial (serían del que graba) y los colores
# de la línea de comandos en la misma paleta.
Hide
Type@5ms "$env:Path = (./preparar.ps1) + ';' + $env:Path"
Enter
Wait
Type@5ms 'Set-PSReadLineOption -PredictionSource None -Colors @{ Command = "`e[38;2;196;181;253m"; Parameter = "`e[38;2;138;143;168m"; String = "`e[38;2;143;214;204m"; Number = "`e[38;2;246;192;160m"; Operator = "`e[38;2;138;143;168m"; Default = "`e[38;2;205;214;244m" }; function prompt { "`e[38;2;196;181;253m>`e[0m " }; Clear-Host'
Enter
Wait
Show

Sleep 400ms

# Una URL, del texto al QR: se escanea con el teléfono directo de la pantalla.
Type "clip2qr"
Type@85ms " --text"
Type@60ms ' "https://github.com/agustinyarrus/clip2qr"'
Sleep 150ms
Enter
Sleep 4.2s

# Fuera de cámara: se desarma la escena.
Hide
Type@5ms "./preparar.ps1 -Limpiar"
Enter
Wait
