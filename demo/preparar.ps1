<#
.SYNOPSIS
  Arma (o desarma con -Limpiar) la escena de la demo de clip2qr: el
  clip2qr.exe de este repo, listo para usar.

.DESCRIPTION
  Compila clip2qr desde este repo a demo\.escena\bin\clip2qr.exe con la
  versión limpia (sin commit estampado): en la cabecera dice v1.0.0 y no
  v1.0.0+abc1234. Imprime esa carpeta, para ponerla primera en el PATH.

  La demo no toca el portapapeles (sería el de quien graba): el texto va con
  --text. Tampoco muestra rutas: ni la cabecera ni la tarjeta nombran una
  carpeta.

  -Limpiar borra demo\.escena (está en .gitignore).

.EXAMPLE
  .\preparar.ps1            # compila y dice dónde quedó
  .\preparar.ps1 -Limpiar   # la desarma
#>
[CmdletBinding()]
param(
    [switch] $Limpiar
)
$ErrorActionPreference = 'Stop'

$demo = $PSScriptRoot
$repo = Split-Path $demo -Parent
$escena = Join-Path $demo '.escena'

if (Test-Path -LiteralPath $escena) { Remove-Item -LiteralPath $escena -Recurse -Force }
if ($Limpiar) {
    Write-Host 'escena desarmada'
    exit 0
}

if (-not (Get-Command go -ErrorAction SilentlyContinue)) { Write-Host 'falta go en el PATH'; exit 1 }
$bin = Join-Path $escena 'bin'
New-Item -ItemType Directory -Path $bin -Force | Out-Null

Push-Location $repo
$cgoAntes = $env:CGO_ENABLED
try {
    $env:CGO_ENABLED = '0'
    go build -trimpath -ldflags '-s -w' -o (Join-Path $bin 'clip2qr.exe') .
    if ($LASTEXITCODE -ne 0) { throw 'no compiló clip2qr' }
} finally {
    $env:CGO_ENABLED = $cgoAntes
    Pop-Location
}
$bin
