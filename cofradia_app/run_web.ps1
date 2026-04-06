# Cofradia — una sola terminal para la app en el navegador
# Uso: clic derecho → Ejecutar con PowerShell, o en terminal:
#   cd "ruta\cofradia_app"
#   .\run_web.ps1

$ErrorActionPreference = "SilentlyContinue"
$port = 8080

Write-Host "Cerrando procesos que usan el puerto $port..." -ForegroundColor Yellow
$conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
foreach ($c in $conns) {
    $pid = $c.OwningProcess
    if ($pid -gt 0) {
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        Write-Host "  PID $pid detenido"
    }
}
Start-Sleep -Seconds 1

Set-Location $PSScriptRoot
Write-Host "`nCompilando y sirviendo en http://localhost:$port" -ForegroundColor Green
Write-Host "Para detener: Ctrl+C en esta ventana`n" -ForegroundColor Cyan

flutter pub get
flutter run -d web-server --web-port=$port --web-hostname=localhost
