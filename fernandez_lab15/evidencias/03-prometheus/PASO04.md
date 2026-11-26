# PASO 04 — Prometheus local: informe de cierre

**Laboratorio 15 · Michael Fernandez · 26/11/2026.**

Estado: **completado**, con los siete microservicios y una instancia de
Prometheus ejecutandose. Resultado estructurado y fecha exacta de la ultima
comprobacion: [VERIFICACION-PASO04.json](VERIFICACION-PASO04.json).
No se ejecuta el PASO 05 ni se instala Grafana.

## 1. Diagnostico y recuperacion del trabajo interrumpido

Se inspeccionaron README, configuracion, scripts, registros de procesos,
recibo de instalacion, respuestas HTTP, consultas y capturas **antes de continuar**.
No habia una copia separada del prompt original: se recuperaron las condiciones
documentadas y se aplicaron las restricciones expresas de la solicitud de reanudacion.

| Actividad encontrada | Estado al retomar | Accion de continuacion |
|---|---|---|
| Prometheus 3.13.5 LTS en `C:\Prometheus` | Instalado, checksum verificado, PID 10868 activo | Reverificar binarios/ZIP; no reinstalar |
| YAML de siete jobs y `promtool check config` | Completado | Revalidar sin cambiar configuracion |
| Siete microservicios del PASO 03 | Mismos PID, puertos activos | Mantener; comprobar salud y metricas |
| Siete targets Prometheus | UP, sin errores | Reconsultar estado final y cuatro expresiones de disponibilidad |
| 19 consultas PromQL antes y despues | Completadas, HTTP 200 | Conservar las 38 respuestas originales |
| Trafico GET y consultas de rango | 24 rondas, 120 GET, cuatro rangos | No repetir la generacion de trafico |
| Regresion Actuator y negocio | Completada | Conservar; refrescar 21 comprobaciones Actuator sin trafico de negocio |
| Capturas 01–14 | Existentes y legibles | Conservar las 14, contrastando SHA-256 |
| Capturas 15 y 16 | Pendientes | Capturar resultados reales: UP=7 y DOWN=0 |
| Cobertura visual de targets | Captura 07 mostraba cuatro por limite de pantalla | Agregar captura 17 con los restantes, sin sustituir 07 |
| Informes finales | No existian | Crear este informe y `VERIFICACION-PASO04.json` |
| Integridad, privacidad y cierre operativo | Faltaba cierre definitivo | Comparar huellas y comprobar procesos finales |

Se inventariaron **209 archivos de evidencia existentes** al reanudar.
Se conservan sin cambios los **208 archivos de resultados**, incluidas las
14 imagenes originales; solo se actualiza `CAPTURAS-PASO04.json` para incorporar
las tres capturas nuevas y cerrar su error historico.
El inventario, sus SHA-256 y el manifiesto interrumpido se conservan en
`.runtime/paso04/reanudacion-antes.json` y
`.runtime/paso04/CAPTURAS-PASO04-interrumpido.json`.

El error pendiente era del registro de capturas (`data` recibio `undefined`),
no un fallo de Prometheus. La continuacion se ejecuto con seleccion explicita
`--solo=15,16,17`; no se recapturaron 01–14. La vista complementaria requirio
desplazar y repintar la ventana real antes de `PrintWindow`.

En el cierre se detecto ademas que Windows PowerShell 5.1 interpretaba como
Latin-1 el JSON UTF-8 de flags, alterando el simbolo de grado de la ruta del
proyecto. Se corrigio la decodificacion en el verificador, sin cambiar la ruta,
la configuracion ni el proceso de Prometheus.

### Archivos revisados y cambios del PASO 04

La comparacion con la linea base original identifica modificaciones previas en
`README.md`, `scripts/Capturas-Actuator.mjs` y `scripts/Verificar-Actuator.ps1`.
Ya existian los scripts de instalacion/arranque/detencion/verificacion de Prometheus,
`scripts/Consultas-Prometheus.mjs`, `scripts/Preparar-Capturas-Paso04.mjs`,
`scripts/Finalizar-Paso04.ps1`, `scripts/Integridad-Paso04.ps1`,
`observabilidad/prometheus/prometheus.yml` y las evidencias de esta fase.
Las listas completas de archivos agregados/modificados figuran en
`Integrity.AddedLocalFiles` y `Integrity.ModifiedLocalFiles` del JSON final.

En esta reanudacion se ajustaron exclusivamente el manifiesto de capturas,
su capturador, el cierre de verificacion y la documentacion del Lab 15.
No se cambiaron fuentes Java, POM, JAR ni YAML de los servicios. No se compilo,
no se reinicio ningun microservicio y no se crearon servidores duplicados.

## 2. Instalacion existente y configuracion efectiva

- Version: **Prometheus y promtool 3.13.5**, Windows amd64, instalacion portable.
- Distribucion: `prometheus-3.13.5.windows-amd64.zip`.
- SHA-256 oficial y recalculado:
  `846398b50b90e02f69960342190a1d01bf9a335b3aeee69bfd6ead41d3a314c5`.
- Binarios instalados contrastados con las huellas del recibo original.
- Configuracion: [prometheus.yml](../../observabilidad/prometheus/prometheus.yml).
- SHA-256 del YAML:
  `0D5F92B0A608D45C665DCA4BF9C10CE8D80C50F9D67E5011C88C70AEBC8BDC37`.
- `promtool check config`: **exit 0, SUCCESS**, tambien al retomar.
- Scrape y evaluacion: **5s**; timeout: **4s**; siete jobs, un target por job.
- Listener: **127.0.0.1:9090**; retencion: **1d**.
- TSDB/WAL: `.runtime/prometheus/data`; se conservan, sin borrar ni reiniciar.
- Admin API y lifecycle: deshabilitados, contrastados con la API de flags.
- PATH permanente y variables globales: sin cambios.

Fuentes: [recibo](INSTALACION-PROMETHEUS.json),
[checksum oficial](sha256sums-oficial.txt),
[validacion original](VALIDACION-PROMTOOL.json) e `InstallationRecheck` y
`PrometheusLiveSettings` del JSON final. No se repitio la descarga ni la instalacion.

## 3. Estado operativo final

| Servicio | Puerto | PID conservado | Actuator health | Target |
|---|---:|---:|---|---|
| config-server | 8888 | 26512 | UP | UP |
| eureka-server | 8761 | 19156 | UP | UP |
| gateway-service | 8080 | 2604 | UP | UP |
| categoria-service | 8082 | 12236 | UP | UP |
| producto-service | 8083 | 25256 | UP | UP |
| cliente-service | 8084 | 3672 | UP | UP |
| pedido-service | 8085 | 11016 | UP | UP |
| Prometheus | 9090 | 10868 | healthy y ready HTTP 200 | No se agrega job propio |

Se comparan PID, fecha de inicio, ejecutable y argumentos con los registros
originales. Cada servicio tiene una instancia y su listener es localhost;
los siete JAR mantienen sus huellas. Prometheus conserva su proceso y sus flags.

Comprobaciones de cierre:

- **21/21 GET Actuator HTTP 200**: indice, health y metrics por servicio;
  se comprueban enlaces Prometheus, salud UP y presencia de metricas JVM/HTTP.
- **7/7 GET `/actuator/prometheus` HTTP 200**.
- **7 targets UP, 0 DOWN**, sin `lastError`, con job/instancia/URL esperados.
- `/`, `/targets`, `/-/healthy`, `/-/ready`: HTTP 200 en Prometheus.
- Eureka: las cinco aplicaciones esperadas, una instancia UP por aplicacion;
  Config Server y Eureka no se cuentan como clientes que deban registrarse.
- Siete rutas `/<servicio>/actuator/prometheus` del Gateway: **404**, aisladas.

Estado crudo final: [targets-verificacion-final.json](targets-verificacion-final.json).
La verificacion principal es **real, contra localhost, sin mocks**.

## 4. PromQL y trafico ya completados: resultados preservados

Intervalo original de trafico: **2026-11-26 03:05:54.570Z a 03:08:01.084Z**.
Son **24 rondas de cinco GET**, cuatro rutas Gateway y pedidos detallados.
Las 120 respuestas fueron HTTP 200, sin fallbacks inesperados. No se repitieron.

| Comprobacion | Resultado guardado |
|---|---|
| `up` | Siete series con valor 1 |
| `count(up)` / `sum(up)` | 7 / 7; confirmados otra vez al cierre |
| `count(up == 0) or vector(0)` | 0; confirmado otra vez al cierre |
| Memoria JVM, CPU, hilos y uptime | Siete series por consulta |
| `hikaricp_connections_active` | Cuatro series, solo servicios JDBC |
| HTTP exitosas acumuladas | Siete series; aumentaron los siete contadores |
| HTTP negocio: contador, tasa y latencia media | Cuatro series por consulta |
| Resilience4j circuitbreaker calls / closed / retry | 9 / 3 / 8 series |
| Gateway: tasa, contador y latencia por ruta | Cuatro series por consulta |
| Contadores de rutas Gateway | 4 → 28, incremento **+24** en cada ruta |
| Contadores de negocio | Categoria +96; Producto, Cliente y Pedido +48 cada uno |
| `query_range` | Cuatro consultas, 26 puntos por serie, paso de 5s |

Los incrementos de negocio incluyen las llamadas compuestas Feign: no tienen
por que coincidir con el numero de solicitudes externas. Los contadores HTTP
generales incluyen scrapes y actividad de infraestructura; no son una medicion
aislada del trafico de negocio.

Expresiones reproducibles: [Consultas-Prometheus.mjs](../../scripts/Consultas-Prometheus.mjs).
Resumen y enlaces a las 38 respuestas y cuatro rangos:
[CONSULTAS-PROMETHEUS.json](CONSULTAS-PROMETHEUS.json).
Regresion previa preservada: [REGRESION-ACTUATOR.json](REGRESION-ACTUATOR.json),
incluidas rutas Gateway/directas y consultas compuestas de solo lectura.

### Interpretacion y limites

`up=1` significa que el scrape tuvo exito, **no** que todas las funciones de
negocio esten sanas. Por eso se comprueba health de Actuator por separado.
La suma de memoria se expresa en MiB y CPU como porcentaje del proceso.
Un pool JDBC con cero conexiones activas entre consultas es normal.
La latencia media es suma de duraciones dividida por numero de solicitudes,
no un percentil. Al inicio de cada serie de latencia hay un NaN por ausencia
de solicitudes en la ventana: se conserva, no se reemplaza por cero.

El Gateway usa `spring_cloud_gateway_requests_seconds_count` y `routeId` para
el trafico de sus rutas; no se le atribuyen las mismas URI instrumentadas que
a los servicios MVC. Las series JVM/CPU representan instantes variables,
no valores que deban permanecer iguales entre capturas.

## 5. Capturas y evidencias

Capturas **reales de Chrome**, ventana con URL, obtenidas mediante CDP por pipe
y `PrintWindow`, sin fabricar paginas ni resultados. Inventario con URL,
fecha y bytes: [CAPTURAS-PASO04.json](CAPTURAS-PASO04.json).
Dimensiones **1500 × 850** y SHA-256 por archivo en `ScreenshotAudit`.

| Capturas | Contenido |
|---|---|
| [01](01-descarga-prometheus.png) | Pagina oficial, paquete Windows y checksum |
| [02](02-version-prometheus.png), [03](03-configuracion-prometheus.png), [04](04-validacion-promtool.png) | Version, YAML y salida real de promtool |
| [05](05-prometheus-interfaz.png), [06](06-consulta-up.png) | Interfaz y siete series de `up` |
| [07](07-targets-up.png) + [17](17-targets-up-continuacion.png) | Dos vistas complementarias que cubren los siete targets UP |
| [08](08-total-servicios.png) | Total de targets: 7 |
| [09](09-memoria-jvm.png), [10](10-uso-cpu.png), [11](11-peticiones-http.png) | Memoria, CPU y HTTP |
| [12](12-grafico-peticiones.png) | Grafico real de la ventana de trafico original |
| [13](13-conexiones-jdbc.png), [14](14-resilience4j.png) | HikariCP y Resilience4j |
| [15](15-suma-servicios-up.png), [16](16-servicios-down.png) | Suma UP=7 y DOWN=0, completadas al reanudar |

Las capturas 02–04 abren archivos locales de salida/configuracion, no respuestas
HTTP del servidor. La grafica 12 conserva su instante final original para no
perder la ventana de trafico ya medida. Las capturas 01–14 son historicas y
las 15–17 corresponden a la reanudacion; sus fechas no se alteran.

## 6. Restricciones e integridad

- **Lab 14 y otros laboratorios:** 2.878 archivos externos comparados con la
  linea base original; cero agregados, eliminados o modificados. De ellos,
  **1.530 pertenecen a Lab 14**.
- **Evidencias anteriores:** las **342** existentes fuera de esta fase siguen
  intactas. Las 14 capturas y los resultados previos del propio PASO 04 tambien.
- **Git:** indice/staging, HEAD y estado externo sin cambios. No se ejecuto
  `git add`, commit, reset ni ninguna operacion de publicacion.
- **Bases DEV:** mismas estructuras, filas, conteos y SHA-256 antes/despues.
  Solo se uso el lector JDBC existente, en transaccion de solo lectura y
  rollback; no DDL, inserciones, actualizaciones ni eliminaciones.
- **Protecciones:** Hibernate `validate`, SQL init `never`, Flyway/Liquibase
  deshabilitados y Hikari/sesion JDBC de solo lectura. Se conservan las
  pruebas de contexto de arranque porque los PID no cambiaron y se reconsulta
  precedencia efectiva de propiedades sin publicar secretos.
- **config-repo:** commit fijo
  `39a22fc2d854d3549ce77cbb347cd20101b0d13f`; no se modifica ni se publica.
- **Privacidad:** sin env completo ni credenciales guardadas; respuestas
  previas sanitizadas conservadas y revision de campos sensibles sin hallazgos.
- Binarios fuera de Git; logs, perfiles de navegador, ZIP, TSDB y WAL ignorados
  bajo `.runtime`. No se instala software adicional ni se ejecuta Docker.

Detalle verificable: `Integrity`, `Database`, `Recovery`, `Security`,
`EffectivePropertyRecheck` y `PriorActualContextProtections` del JSON final.
Las garantias de integridad se refieren a las rutas y esquemas inventariados;
no se presentan como pruebas CRUD ni certificacion integral de negocio.

## 7. Reproduccion minima y cierre

Desde `fernandez_lab15`, con el conjunto ya activo:

```powershell
# Repetir solo el cierre: no instala, inicia ni detiene servicios.
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Integridad-Paso04.ps1 -Momento despues
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Finalizar-Paso04.ps1
```

No ejecutar el instalador ni los lanzadores para un servidor que ya esta activo.
No volver a generar trafico o capturas completas para cerrar esta reanudacion.
Prometheus: <http://localhost:9090/> · targets: <http://localhost:9090/targets>.

**Pendientes del PASO 04: ninguno. PASO 05/Grafana: no autorizado, no ejecutado.**
