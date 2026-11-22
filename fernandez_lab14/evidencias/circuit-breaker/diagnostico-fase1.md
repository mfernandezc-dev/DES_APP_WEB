# Diagnóstico inicial — 21/11/2026

Comprobaciones reales antes de modificar código:

- Puerto 8085: PID 15108, `com.tecsup.PedidoServiceApplication`.
- `jcmd 15108 VM.system_properties` confirma `user.dir` en `fernandez_lab14/pedido-service` y JVM `27.0.1.0.2`.
- Una sola aplicación Pedido Service entre los procesos Java; los procesos Maven y compiladores de IntelliJ no son instancias del servicio.
- Eureka: una instancia UP de cada servicio de negocio, todas con hostname `localhost`, puertos 8082–8085. No se observó registro duplicado de pedidos.
- Consulta directa `GET http://localhost:8085/api/pedidos/1`: HTTP 200.
- Consulta Feign `GET http://localhost:8084/api/clientes/pedidos/1`: HTTP 200 y los mismos datos.

Respuesta de ambas consultas:

```json
{"id":1,"cantidad":1,"estado":"PENDIENTE","cliente":{"id":1,"nombre":"Carlos","apellido":"Ramirez"},"producto":{"id":1,"nombre":"Laptop","precio":2500.0}}
```

El HTTP 500 informado anteriormente **no se reprodujo**. No hay archivos `.log` en el laboratorio; las aplicaciones originales escriben en las consolas de IntelliJ, cuyo historial no está disponible por HTTP/jcmd. No se atribuye una causa raíz sin el stacktrace histórico. El puerto ocupado explica el rechazo de un segundo arranque, pero no demuestra la causa del 500 anterior. No fue necesario cambiar PedidoClient ni detener procesos para restablecer la comunicación: ya estaba operativa al iniciar la revisión.

Los endpoints Actuator de circuitos respondían 404 antes de habilitar su exposición. Esto no implica que el Circuit Breaker estuviera ausente.
