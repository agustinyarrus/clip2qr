<#
.SYNOPSIS
  El dibujo de la terminal contra zxing-cpp: 15 casos (5 textos, cada uno
  normal, invertido y con nivel H y borde 4), más uno que tiene que fallar.

.DESCRIPTION
  Corre clip2qr.exe con cada texto, le pasa lo que imprime a
  terminal_check.py (que reconstruye la matriz desde los medios bloques y la
  decodifica con zxing-cpp) y compara con el texto pedido. Al final, un caso
  con el texto esperado cambiado: si el guion lo diera por bueno, el oráculo
  no estaría mirando nada.

  Requisitos: Python 3 con pip install -r internal/qr/_oracle/requirements.txt.

.EXAMPLE
  .\build.ps1
  .\internal\qr\_oracle\terminal_all.ps1 -Exe .\dist\clip2qr.exe
#>
#Requires -Version 7
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Exe
)
$ErrorActionPreference = 'Stop'
$check = Join-Path $PSScriptRoot 'terminal_check.py'
$Exe = (Resolve-Path $Exe).Path
# Lo que imprime clip2qr (UTF-8) tiene que llegar entero a python.
try { [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) } catch { }
$OutputEncoding = [Text.UTF8Encoding]::new($false)

$textos = @(
    'hola'
    'https://github.com/agustinyarrus/clip2qr'
    'WIFI:S:MiRed;T:WPA;P:clave-secreta-123;;'
    'café con leche y medialunas — ñandú'
    ('A' * 300)
)
$variantes = @(
    @{ Nombre = 'normal';           Clip = @();                  Check = @() }
    @{ Nombre = 'invertido';        Clip = @('-i');              Check = @('--invert') }
    @{ Nombre = 'nivel H, borde 4'; Clip = @('-e', 'h', '-q', '4'); Check = @() }
)

function Probar([string] $texto, [string[]] $clip, [string] $esperado, [string[]] $flags) {
    $dibujo = & $Exe --text $texto --no-color @clip
    if ($LASTEXITCODE -ne 0) { return "clip2qr salió con $LASTEXITCODE" }
    $salida = ($dibujo -join "`n") | python $check $esperado @flags 2>&1
    if ($LASTEXITCODE -ne 0) { return (@($salida) -join ' ').Trim() }
    return $null
}

$ok = 0; $total = 0
foreach ($t in $textos) {
    $corto = if ($t.Length -gt 40) { $t.Substring(0, 12) + "… ($($t.Length) caracteres)" } else { $t }
    foreach ($v in $variantes) {
        $total++
        $falla = Probar $t $v.Clip $t $v.Check
        if ($falla) { Write-Host "  ✗ $($v.Nombre) · $corto  $falla" }
        else { $ok++; Write-Host "  ✓ $($v.Nombre) · $corto" }
    }
}

# El control: el mismo dibujo con otro texto esperado tiene que fallar.
$control = Probar 'hola' @() 'chau' @()
if ($control) { Write-Host '  ✓ control: con otro texto esperado, el guion falla' }
else { Write-Host '  ✗ control: el guion aceptó un texto que no era el del código' }

Write-Host ''
Write-Host "  $ok de $total dibujos leídos por zxing-cpp con el texto pedido"
if ($ok -ne $total -or -not $control) { exit 1 }
exit 0
