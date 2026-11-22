$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$base = 'http://localhost:8085/api/pedidos'
$before = Invoke-RestMethod $base
$rows = foreach ($payload in @(
    @{clienteId=9223372036854775807L;productoId=1;cantidad=1},
    @{clienteId=1;productoId=9223372036854775807L;cantidad=1}
)) {
    # Primero confirmar que el recurso elegido no existe, sin inventar ese supuesto.
    $url = if ($payload.clienteId -ne 1) {'http://localhost:8084/api/clientes/' + $payload.clienteId} else {'http://localhost:8083/api/productos/' + $payload.productoId}
    $missing = $false
    try { Invoke-WebRequest $url -UseBasicParsing | Out-Null }
    catch { if ([int]$_.Exception.Response.StatusCode -eq 404) {$missing=$true} else {throw} }
    if (!$missing) { throw 'El ID existe: se cancela la prueba para evitar crear registros.' }
    $status = 0
    $body = ''
    try { $response = Invoke-WebRequest $base -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json) -UseBasicParsing; $status=[int]$response.StatusCode; $body=$response.Content }
    catch { $status=[int]$_.Exception.Response.StatusCode; $body=$_.ErrorDetails.Message }
    if ($status -ne 404) { throw "Se esperaba 404 para referencia inexistente, recibido HTTP $status" }
    [pscustomobject]@{Payload=$payload;ConfirmedMissing=$missing;Status=$status;Body=$body}
}
$after = Invoke-RestMethod $base
if (($before | ConvertTo-Json -Depth 15 -Compress) -ne ($after | ConvertTo-Json -Depth 15 -Compress)) {
    throw 'El listado cambio durante la prueba: revisar manualmente, no eliminar registros.'
}
@{Timestamp=(Get-Date -Format o);Before=$before;Cases=$rows;After=$after;Unchanged=$true} |
    ConvertTo-Json -Depth 20 | Set-Content (Join-Path $root 'evidencias/actividad-final/validaciones-http.json') -Encoding UTF8
Write-Output 'PASS: dos pedidos invalidos rechazados y listado intacto.'
