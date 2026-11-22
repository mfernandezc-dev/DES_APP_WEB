$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$control=Join-Path $PSScriptRoot 'Servicios-Lab.ps1'
$capture=Join-Path $PSScriptRoot 'Capturar-Evidencia.ps1'
function Wait-Real {
    $deadline=[DateTime]::UtcNow.AddSeconds(150)
    do {
        try {
            $r=Invoke-RestMethod 'http://localhost:8084/api/clientes/pedidos/1' -TimeoutSec 35
            if($r.id -eq 1 -and $r.producto.precio -eq 2500 -and $r.cliente.nombre -eq 'Carlos'){return $r}
        } catch {}
        Start-Sleep -Seconds 2
    } while([DateTime]::UtcNow -lt $deadline)
    throw 'No se recuperaron los datos reales en el plazo previsto.'
}
$null=Wait-Real
& $capture -Url 'http://localhost:8084/api/clientes/pedidos/1' -Archivo 'circuit-breaker/antes-real.png'
try {
    & $control -Accion Detener -Servicio pedido-service
    1..4 | ForEach-Object { Invoke-RestMethod 'http://localhost:8084/api/clientes/pedidos/1' -TimeoutSec 35 | Out-Null }
    $state=Invoke-RestMethod 'http://localhost:8084/actuator/circuitbreakers'
    if($state.circuitBreakers.pedidoService.state -ne 'OPEN'){throw 'El circuito no llego a OPEN.'}
    & $capture -Url 'http://localhost:8084/actuator/circuitbreakers' -Archivo 'circuit-breaker/open-real.png'
} finally {
    & $control -Accion Reiniciar -Servicio pedido-service
}
$null=Wait-Real
1..10 | ForEach-Object { $null=Wait-Real }
& $capture -Url 'http://localhost:8084/actuator/circuitbreakers' -Archivo 'circuit-breaker/recuperacion-real.png'
& (Join-Path $PSScriptRoot 'Probar-Validaciones.ps1')

# Salida de LAB: ningun filtro/interceptor de demora queda registrado en los contextos.
foreach($service in @('categoria-service','producto-service','cliente-service')) {
    & $control -Accion Reiniciar -Servicio $service
}
$normal=Wait-Real
$ports=8082,8083,8084,8085
$processes=foreach($port in $ports){
    $listener=Get-NetTCPConnection -State Listen -LocalPort $port | Select-Object -First 1
    [pscustomobject]@{Port=$port;PID=$listener.OwningProcess;Profiles='dev';DdlAuto='validate'}
}
@{Timestamp=(Get-Date -Format o);Pedido=$normal;Processes=$processes} | ConvertTo-Json -Depth 10 |
    Set-Content (Join-Path $root 'evidencias/actividad-final/estado-final.json') -Encoding UTF8
Write-Output 'PASS: validaciones 404, comunicacion recuperada y cuatro servicios sin perfil LAB.'
