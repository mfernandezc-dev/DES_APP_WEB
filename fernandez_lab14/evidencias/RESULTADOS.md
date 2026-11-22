# Resultados verificables — Laboratorio 14

Fecha de ejecución: **21 de noviembre de 2026**. Servicios Java y bases MySQL locales reales; no se sustituyeron los servicios por mocks para las pruebas HTTP.

## Construcción y pruebas Maven

- Los siete módulos finalizaron `package -DskipTests` correctamente (también compila las pruebas, pero no las ejecuta).
- Luego se ejecutó `mvn test` en cada módulo y se volvió a ejecutar `package` con pruebas tras añadir el manejador de excepciones: **11 pruebas, 0 fallos, 0 errores** en la revisión final.
- Config Server, Eureka, Gateway, Categoría, Cliente y Producto: una prueba de contexto cada uno.
- Pedido: una prueba de contexto, dos pruebas unitarias de validación que comprueban que no se invoca el repositorio cuando falla una referencia y dos pruebas del manejador HTTP (404/503).
- Las pruebas JPA se ejecutaron con `spring.jpa.hibernate.ddl-auto=validate`; registro y descarga Eureka se desactivaron únicamente en el proceso de pruebas mediante sus propiedades específicas. No se deshabilitó el componente Eureka completo en el servidor.
- Resultado por módulo: [`actividad-final/maven-tests.json`](actividad-final/maven-tests.json).

## Config Server, perfiles y descubrimiento

- Doce consultas satisfactorias: cuatro aplicaciones por tres perfiles (`default`, `dev`, `prod`).
- Versión remota observada: `39a22fc2d854d3549ce77cbb347cd20101b0d13f`.
- Credenciales omitidas de las respuestas guardadas: [`perfiles/configuracion-consultada.json`](perfiles/configuracion-consultada.json).
- Capturas reales de navegador: [`config-server/categoria-default.png`](config-server/categoria-default.png) y [`config-server/eureka-registro.png`](config-server/eureka-registro.png).
- Eureka mostraba una instancia UP de cada servicio de negocio; la captura incluye un aviso real de autopreservación debido al bajo ritmo de renovaciones durante las interrupciones. No se deshabilitó esa protección para producir una captura limpia.
- No se arrancaron servicios ni bases PROD. Leer el perfil no demuestra un despliegue productivo.

## Diagnóstico inicial y limitaciones

- PID 15108 identificado como Pedido Service de este laboratorio; `jcmd` confirmó su directorio de trabajo.
- Consulta directa y Feign devolvieron inicialmente el pedido 1 real.
- El HTTP 500 histórico no pudo reproducirse; no se tuvo acceso al historial de consola de IntelliJ. Su causa exacta queda **sin confirmar**, no se inventa una corrección.
- Se conserva `circuit-breaker/postman-inicial.json`: una prueba Postman posterior detectó un fallback de producto durante recompilación, con **una aserción aprobada y una fallida**. No es una evidencia de éxito.

## Recorrido HTTP

### Circuit Breaker Cliente → Pedido: aprobado

- Se detuvo el proceso identificado de Pedido Service; cuatro consultas devolvieron el fallback esperado.
- Actuator registró `bufferedCalls: 3`, `failedCalls: 3`, `notPermittedCalls: 1`, estado **OPEN** y umbral 50 %.
- Se reinició Pedido; tras la espera y actualización de descubrimiento se obtuvieron diez respuestas con el pedido 1 real, Carlos Ramirez y Laptop a 2500.
- El circuito terminó **CLOSED**, con cero fallos en la ventana final.
- Evidencia: `circuit-breaker/pedido-detenido.json`, `circuit-breaker/recuperacion.json` y `circuit-breaker/ejecucion-parcial.txt`.

### Regresión de los dos circuitos existentes: aprobada con recuperación estable

- Producto → Categoría: servicio detenido, fallback y **OPEN**; reinicio, categoría ACTIVO y circuito **CLOSED**. Archivos `categoria-open.json` y `categoria-recuperacion.json`.
- Pedido → Producto: servicio detenido, fallback y **OPEN**; reinicio, Laptop a 2500 y circuito **CLOSED**. Archivos `producto-open.json` y `producto-recuperacion.json`.
- El primer chequeo de recuperación de Producto falló porque una sola respuesta real no garantizaba CLOSED: las llamadas de prueba efectuadas mientras el servidor arrancaba habían fallado en HALF_OPEN. Se corrigió **la espera de la prueba**, no los parámetros del circuito, y se verificaron diez respuestas reales consecutivas y CLOSED. Se conservan tanto `regresion-primer-recorrido.txt` como `regresion-recuperacion.txt`; no se oculta la aserción fallida inicial.
- La última consulta verificó los tres circuitos simultáneamente en **CLOSED** y comunicación directa/Feign con el pedido original: `actividad-final/estado-final.json`.

Los resultados de Retry y Bulkhead se guardan por escenario en sus carpetas y se resumen a continuación. Una ejecución del recorrido se interrumpió al detectar serialización excesiva de metadatos de `Get-Content` por Windows PowerShell 5. Se corrigió usando un lector de strings puros con acceso compartido `FileShare.ReadWrite`, necesario mientras Java escribe en el log. No se presenta esa ejecución parcial como una aprobación de todo el recorrido.

### Retry y Bulkhead: recorrido inicial aprobado

El recorrido posterior terminó correctamente. Salida: [`actividad-final/recorrido-retry-bulkhead.txt`](actividad-final/recorrido-retry-bulkhead.txt).

| Caso real | Resultado observado |
|---|---|
| Categoría detenida | Tres intentos HTTP en una solicitud lógica, fallback; duración **4340 ms** |
| Categoría restablecida | Respuesta con categoría real `Laptops`, estado ACTIVO |
| Bulkhead Categoría, cuatro solicitudes concurrentes | Cuatro HTTP 200: dos respuestas reales en **10023/10020 ms**, dos fallbacks en **1010/1010 ms** |
| Cliente con demora de 5000 ms | Tres intentos por timeout de 2000 ms, fallback; duración total **10079 ms** |
| Cliente sin cabecera de demora | Vuelve a responder Carlos Ramirez |
| Bulkhead Producto, cuatro solicitudes concurrentes | Cuatro HTTP 200: dos respuestas reales en **10046/10046 ms**, dos fallbacks en **1033/1033 ms** |
| Listado anterior y pedido por ID | Se conservaron el esquema anterior y los datos existentes |

Los logs de ambas dependencias con demora muestran un máximo de **dos llamadas activas** y retorno a cero. No se deduce el límite solo de que aparezca un fallback.

Evidencias: `retry/categoria-no-disponible.json`, `retry/categoria-disponible.json`, `bulkhead/categoria-concurrente.json`, `actividad-final/cliente-retry.json`, `actividad-final/producto-bulkhead.json`.

`informe.html` visualiza esos archivos. `retry/informe-resultados.png` es una captura auténtica de **ese informe**, no una captura de Postman ni una pantalla del backend en vivo. Algunos valores `Response` serializados por Windows PowerShell aparecen envueltos en `value`/`Count`: son metadatos del archivo de evidencia, no un cambio del contrato HTTP; las respuestas completas de las pruebas concurrentes están en los campos `Body` sin esa envoltura.

### Actividad final: sesión posterior con capturas directas de ejecución

El **21/11/2026, entre las 19:07 y 19:09 (-05:00)**, se repitieron únicamente los escenarios finales contra los servicios Java y MySQL reales, usando las implementaciones existentes. No se sustituyen los resultados del recorrido inicial por estos tiempos nuevos: son ejecuciones distintas. Ambas solicitudes usaron `GET http://localhost:8085/api/pedidos?detallado=true`; el listado original `GET /api/pedidos` se conserva sin composición remota.

| Escenario | Resultado real | Captura y fuente |
|---|---|---|
| Retry Pedido → Cliente, cabecera `X-Lab-Cliente-Delay-Ms: 5000` | Tres intentos reales; Cliente registró la demora de 5000 ms en cada intento. Tras agotar Retry se obtuvo fallback de Cliente, con Producto normal. HTTP **200**, **10114 ms**; **seis comprobaciones aprobadas**. | [Consola de ejecución](actividad-final/cliente-retry-ejecucion.png), [resultados y logs](actividad-final/cliente-retry-ejecucion.json), [metadatos](actividad-final/cliente-retry-ejecucion.png.json) |
| Bulkhead Pedido → Producto, cabecera `X-Lab-Producto-Delay-Ms: 10000` | Cuatro GET concurrentes: dos productos reales en **10146/10141 ms** y dos fallbacks en **1139/1142 ms**. Cuatro HTTP **200**, máximo observado de **dos llamadas activas**, dos rechazos `productoBulkhead is full`; **siete comprobaciones aprobadas**. | [Consola de ejecución](actividad-final/producto-bulkhead-ejecucion.png), [resultados y logs](actividad-final/producto-bulkhead-ejecucion.json), [metadatos](actividad-final/producto-bulkhead-ejecucion.png.json) |

**Trece comprobaciones aprobadas** entre ambos escenarios. No son las doce aserciones Postman anteriores ni una nueva ejecución de Maven. Los cuatro GET de Bulkhead se lanzaron desde cuatro tareas con una barrera de inicio compartida; los tiempos de inicio, respuestas completas y logs están en el JSON fuente.

Un HTTP 200 con fallback acredita que el consumidor devolvió una respuesta degradada controlada, **no una respuesta exitosa de la dependencia remota**. En Retry, el producto siguió disponible mientras fallaba la consulta de Cliente por timeout; en Bulkhead, solo dos consultas a Producto fueron admitidas y las otras dos recibieron fallback por saturación.

Las imágenes son capturas nativas de la **consola que ejecutó las peticiones HTTP**, mostrando URL, cabecera, estado, respuesta, tiempos y extractos originales de los logs de esa ejecución. No son una interfaz Postman ni una captura del HTML. Sus metadatos indican `Windows PrintWindow (native console)`, dimensiones 993 × 839, escenario, URL, cabecera, archivo de resultados y SHA-256 verificado contra el PNG.

### Cierre de la sesión de capturas: DEV restaurado

- [Registro satisfactorio de cierre](actividad-final/estado-final-capturas-20261121-190923.json): los seis puertos estaban disponibles; los cuatro servicios de negocio terminaron con **DEV, sin LAB y `ddl-auto=validate`**, con su identidad y ruta comprobadas. LAB es exclusivo de simulaciones temporales, no un perfil productivo.
- Las comprobaciones directas posteriores con cabeceras artificiales de 10000 ms respondieron en **23/37/25 ms** para Categoría/Producto/Cliente: la simulación estaba desactivada. Una consulta posterior a Pedido **sin cabeceras** obtuvo HTTP 200 en **54 ms**, con Cliente y Producto reales.
- Los listados de Categoría, Producto, Cliente y Pedido coincidieron antes/después (`BusinessDataUnchanged: true`); solo se enviaron GET. No se modificaron datos para estas pruebas.
- El registro confirmó rama `main`, HEAD e índice sin cambios, **57 entradas preparadas** y ningún cambio en los archivos protegidos. Estos son resultados del cierre registrado, no una nueva verificación en vivo durante esta edición documental.
- Se conserva el [intento previo interrumpido](actividad-final/estado-final-capturas-20261121-190620.json): la comprobación de `/actuator/info` de Categoría obtuvo 404 y no se completó la verificación final de Pedido. **No es una prueba aprobada ni describe el cierre vigente**; se conserva como trazabilidad sin sobrescribirlo.

### Validaciones por HTTP

La ejecución anterior al manejador (`actividad-final/validaciones-antes-manejador.json`) confirmó referencias inexistentes y listado intacto, pero devolvía HTTP 500. Tras reiniciar con el manejador nuevo, **ambos casos devolvieron HTTP 404** y el listado antes/después permaneció idéntico: `actividad-final/validaciones-http.json`. No se creó, modificó ni eliminó ningún pedido para estas pruebas.

### Verificación final y salida de la simulación

- Postman ejecutó tres solicitudes (pedido directo, Cliente → Pedido y listado detallado): **12 aserciones aprobadas, cero fallidas**, con HTTP 200 y datos reales. Se guardó un resumen sin headers/tokens en `actividad-final/postman-verificacion-final.json`.
- Las cuatro aplicaciones quedaron con perfil **dev**, sin `lab`, y `ddl-auto=validate`; se comprobó su línea de ejecución mediante `jcmd`.
- Se enviaron cabeceras de demora de 10000 ms directamente a Categoría, Producto y Cliente: respondieron en **63, 36 y 25 ms**, respectivamente. Los filtros de simulación estaban desactivados: `actividad-final/simulacion-desactivada.json`.
- Capturas reales verificadas visualmente: `circuit-breaker/antes-real.png`, `circuit-breaker/open-real.png`, `circuit-breaker/recuperacion-real.png`, con URL/hora en sus JSON de metadatos. La segunda repetición de OPEN muestra tres fallos en una ventana con cinco llamadas (60 %); difiere legítimamente de la primera ventana de tres fallos sobre tres llamadas (100 %).
- Registro operativo de cierre: `actividad-final/cierre-pruebas.txt`.

## Alcance de la evidencia

Los JSON contienen respuestas reales, tiempos y extractos de consola, no capturas fabricadas. Las pruebas unitarias usan dobles solo para verificar reglas de guardado; no se cuentan como comunicación HTTP. Las capturas headless son capturas auténticas de una página de navegador y no muestran su barra de direcciones; su URL de origen se documenta aparte.

Las dos nuevas capturas nativas de consola son evidencia de ejecución; `retry/informe-resultados.png` es una captura de informe derivado; [informe.html](informe.html) presenta resultados JSON; el diagrama Mermaid del [README principal](../README.md) es explicativo y no demuestra ejecución. Los PNG y JSON originales se conservan sin modificaciones, incluidos los intentos fallidos identificados. La corrección de texto mal decodificado en el HTML es solo de presentación, no altera las cifras ni los archivos fuente.

No se realizaron commits, push, ramas, worktrees, limpieza destructiva ni cambios en otros laboratorios. La publicación sigue pendiente de autorización y revisión del índice preexistente.

## Pendientes y límites

- Confirmar la causa del 500 histórico requiere el stacktrace original o una nueva reproducción; el estado actual sí está verificado y no presenta ese error.
- **Estado observado en la auditoría del 21/11/2026:** el remoto estaba cinco commits por delante del HEAD local `3caec9f` (`main` remoto `9967692`), ninguno afectaba Lab 14; `origin/main` local estaba desactualizado. Había 57 archivos preparados de varios laboratorios, cuatro esqueletos incompletos de Lab 14 en el índice y ningún archivo de Lab 14 publicado. Estas cifras deben comprobarse nuevamente antes de publicar; no se hizo pull, no se alteró el índice y la publicación requiere autorización expresa.
- No se desplegó PROD ni se certificó una base productiva. Gateway conserva código, empaquetado y prueba de contexto; no se levantó para una prueba nueva de enrutamiento en vivo.
- Las capturas directas de Retry/Bulkhead de la actividad final ya están incorporadas. La guía no exige la interfaz Postman; si el docente la solicita expresamente, sería una evidencia adicional, no debe confundirse con las consolas capturadas.
- **Validación docente pendiente:** aceptación de `GET /api/pedidos?detallado=true` como adaptación del GET de la página 25, conservando el listado original; ausencia de `ProductoService.actualizar()` incluido en el ejemplo de la página 17. No se implementó automáticamente ni se presenta como funcionalidad existente.
