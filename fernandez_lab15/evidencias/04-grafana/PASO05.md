# PASO 05 — Grafana OSS integrado con Prometheus

**Laboratorio N.º 15 · Michael Fernandez · 26/11/2026.**

Resultado: **COMPLETADO**. La marca definitiva y fecha de cierre estan en
[VERIFICACION-PASO05.json](VERIFICACION-PASO05.json). Grafana queda activo
junto con los siete microservicios, MariaDB y Prometheus. No se ejecuta el
PASO 06 ni se publica en GitHub.

El alcance de las paginas 10–11 se implementa segun las actividades detalladas
de la autorizacion: instalacion local, acceso administrativo y conexion real
con Prometheus. La guia PDF no estaba adjunta en el checkout; no se atribuyen
a esas paginas instrucciones adicionales no proporcionadas.

## A. Version y ubicacion

- **Grafana OSS 13.3.2 estable**, licencia AGPLv3, Windows **amd64**.
- Arquitectura detectada: **x64-based PC**.
- Instalacion independiente: **`C:\Grafana`**, sin instalaciones previas
  sobrescritas ni necesidad de elevacion/fallback.
- Binario real: `C:\Grafana\bin\grafana.exe`.
- Comando admitido y comprobado: `grafana.exe server --homepath ... --config ...`.
- Version real: [grafana-version.txt](grafana-version.txt).
- No MSI, registro de servicio de Windows, Docker ni cambios permanentes a PATH.

Grafana presenta las series; Prometheus realiza scrapes y conserva su historial.
Grafana no sustituye la TSDB de Prometheus ni consulta las bases del proyecto.

## B. Descarga e integridad

Se consultaron la [pagina oficial solicitada](https://grafana.com/grafana/download?edition=oss&platform=windows),
la [version concreta](https://grafana.com/grafana/download/13.3.2?edition=oss&platform=windows)
y los [metadatos oficiales](https://grafana.com/api/grafana/versions/13.3.2).
El release declara `stable=true`, sin beta, preview ni nightly.

Distribucion descargada exclusivamente desde Grafana:

```text
https://dl.grafana.com/grafana/release/13.3.2/grafana_13.3.2_44555861735_windows_amd64.tar.gz

SHA-256 oficial y calculado:
8545e8702b219220dddf687053ddfc0503f3acd5bb80a4a401daa2d5faae1056
```

El checksum coincide **antes de extraer o ejecutar**. La pagina denomina
“zip” al enlace, pero el paquete oficial actual es `.tar.gz`; se utilizo
`tar.exe` disponible en Windows, comprobando las entradas antes de extraer.
Tambien se registra SHA-256 del ejecutable y se revalida al iniciar/detener.

Evidencias: [INSTALACION-GRAFANA.json](INSTALACION-GRAFANA.json),
[release-oficial.json](release-oficial.json), [captura 01](01-descarga-grafana.png)
y [captura 02](02-version-grafana.png). El archivo descargado permanece
ignorado en `.runtime/paso05/`; no se reinstalo Prometheus.

## C. Proceso, puerto, configuracion y acceso

- PID Grafana: **27568**, listener exclusivo **127.0.0.1:3000**.
- `GET /api/health`: HTTP 200, `database=ok`, version 13.3.2.
- Registro operativo completo: `.runtime/grafana/proceso.json`, con inicio UTC,
  ejecutable, SHA-256, argumentos, configuracion y archivos stdout/stderr.
- Configuracion especifica: `.runtime/grafana/grafana-lab15.ini`.
- SQLite: `.runtime/grafana/data/grafana.db`.
- Logs, plugins instalables, provisioning y dashboards operativos:
  `.runtime/grafana/{logs,plugins,provisioning,dashboards}`.
- Acceso anonimo, registro publico y creacion de organizaciones deshabilitados.
- Telemetria, actualizaciones, precarga de plugins, noticias y snapshots
  externos deshabilitados. Tema oscuro; refresco minimo **5s**.

Se verificaron los valores efectivos mediante API, el INI realmente usado y
la existencia de los archivos operativos. No se usa MariaDB para Grafana.
Los plugins integrados que forman parte de la distribucion se leen de la
instalacion; no se descargaron extensiones adicionales.

### Cambio seguro del acceso inicial

En esta instalacion nueva se comprobo el acceso inicial de la distribucion,
se cambio la clave administrativa por una aleatoria de alta entropia y se
verifico que la clave inicial ya devuelve **401**. El usuario sigue siendo
`admin`; **no se publica ninguna contrasena**.

La credencial se guarda como PSCredential cifrada con **Windows DPAPI** en
`.runtime/grafana/private/admin.clixml`. El directorio privado tiene herencia
desactivada y ACL para la cuenta de Windows actual y SYSTEM. La clave interna
de cifrado de Grafana tambien reside alli; no se guarda en archivos versionables.
El propietario puede recuperar su acceso siguiendo el procedimiento de
terminal privada del [README](../../README.md#grafana-oss--paso-05).
No hay intervencion manual de autenticacion pendiente.

La captura de login tiene los campos vacios. La automatizacion autentica por
canal local sin imprimir secretos, guardar headers ni producir capturas de claves.
HTTP/cookie sin TLS se aceptan exclusivamente por el listener localhost;
no se habilita publicacion remota.

Evidencia: [AUTENTICACION-GRAFANA.json](AUTENTICACION-GRAFANA.json),
[grafana-health.json](grafana-health.json),
[configuracion-efectiva-segura.json](configuracion-efectiva-segura.json).

## D. Conexion real Grafana–Prometheus

| Propiedad | Valor efectivo |
|---|---|
| Nombre | Prometheus |
| Tipo | prometheus |
| UID | prometheus-lab15 |
| URL | http://127.0.0.1:9090 |
| Acceso | proxy del servidor |
| Predeterminada | Si |
| Intervalo | 5s |
| Editable desde UI | No, provisionada |

Fuente: [prometheus.yml](../../observabilidad/grafana/provisioning/datasources/prometheus.yml).
Se cargo automaticamente al iniciar Grafana. La API de fuentes confirma que
existe **solo este datasource**, sin conexiones SQL a las bases del proyecto.

Prueba equivalente a **Save & test**, apropiada para una fuente no editable:

```text
GET http://localhost:3000/api/datasources/uid/prometheus-lab15/health
HTTP 200
status: OK
message: Successfully queried the Prometheus API.
```

No se habilito edicion ni se guardaron cambios manuales para obtener esta
prueba. La configuracion se comprobo en la interfaz; Explore y los paneles
hicieron consultas reales mediante Grafana. No se uso un mock.

Respuestas: [datasource-prometheus.json](datasource-prometheus.json),
[datasource-health.json](datasource-health.json),
[CONEXION-GRAFANA.json](CONEXION-GRAFANA.json).

## E. Resultado de `up`

Consulta real realizada en **Grafana Explore**, por el proxy de Grafana y
por su backend de consultas:

| job | Resultado |
|---|---:|
| config-server | 1 |
| eureka-server | 1 |
| gateway-service | 1 |
| categoria-service | 1 |
| producto-service | 1 |
| cliente-service | 1 |
| pedido-service | 1 |

**7 disponibles, 0 DOWN, total 7, disponibilidad de scrape 100%.**
Esto no equivale a certificar salud de negocio: Actuator y las rutas se
verifican separadamente. Respuesta: [grafana-query-up.json](grafana-query-up.json).
Interfaz real: [07-explore-consulta-up.png](07-explore-consulta-up.png).

## F. Dashboard y provisioning portable

**Lab 15 - Observabilidad de Microservicios**, UID `lab15-observabilidad`:

<http://localhost:3000/d/lab15-observabilidad/lab-15-observabilidad-de-microservicios>

- Carpeta: **Laboratorio 15**, UID `lab15-folder`.
- [Dashboard JSON](../../observabilidad/grafana/dashboards/lab15-observabilidad.json).
- [Proveedor](../../observabilidad/grafana/provisioning/dashboards/lab15.yml).
- [Generador reproducible](../../scripts/Crear-Dashboard-Grafana.mjs).
- Rango inicial **ultimos 15 minutos**, refresco **cada 5s**, tema oscuro.
- Variable **Microservicio**, consulta `label_values(up, job)`: seleccion
  multiple o todos mediante `job`; siete valores reales comprobados.
- Las cuatro cifras globales y el estado individual de los siete servicios
  **no se filtran**. JVM, HTTP, JDBC y resiliencia si respetan la seleccion.
- Los YAML versionables usan `${LAB15_GRAFANA_DASHBOARDS}`. El lanzador
  define esa variable solo en el proceso hijo, sin una ruta fija de este equipo.
- Los archivos se copian a `.runtime/grafana/` y se cargan automaticamente.
  El proveedor recarga cambios cada 10s, sin reiniciar Grafana.

No se depende de ediciones manuales en SQLite ni en la UI. El dashboard
cargado por el servidor esta en [dashboard-cargado.json](dashboard-cargado.json).

## G. Paneles, metricas y semantica

**18 paneles: introduccion + 17 de datos.** Se cubren las 15 categorias
obligatorias y se agregan dos paneles de resiliencia comprobada.

| ID | Panel | Metrica / calculo | Alcance |
|---:|---|---|---|
| 2 | Servicios disponibles | `sum(up)` | Global |
| 3 | Servicios no disponibles | `count(up == 0) or vector(0)` | Global |
| 4 | Total de servicios | `count(up)` | Global |
| 5 | Disponibilidad del scrape | `100 * avg(up)` | Global, porcentaje |
| 6 | Estado individual | `up`, 1=UP verde, 0=DOWN rojo | Global, siete jobs |
| 7 | Memoria JVM | `sum by(job)(jvm_memory_used_bytes) / 1024 / 1024` | MiB, filtro job |
| 8 | CPU del proceso | `100 * process_cpu_usage` | Porcentaje, eje automatico |
| 9 | Hilos activos | `jvm_threads_live_threads` | Gauge |
| 10 | Tiempo de actividad | `process_uptime_seconds` | Duracion, entrada en segundos |
| 11 | HTTP negocio por segundo | `rate` del contador de negocio | Solicitudes/s |
| 12 | HTTP exitosas | `increase` de respuestas 200, ventana 2m | Solicitudes, puede extrapolar |
| 13 | Respuesta media HTTP | `1000 * rate(sum) / (rate(count) > 0)` | ms, ponderada por job |
| 14 | HikariCP activas | `hikaricp_connections_active` | Solo cuatro servicios JDBC |
| 15 | HikariCP maximas | `hikaricp_connections_max` | Solo cuatro servicios JDBC |
| 16 | CircuitBreaker llamadas | `rate(resilience4j_circuitbreaker_calls_seconds_count)` | job, name, kind |
| 17 | Circuitos CLOSED, adicional | `resilience4j_circuitbreaker_state{state="closed"}` | Tres instancias reales |
| 18 | Retry llamadas, adicional | `rate(resilience4j_retry_calls_total)` | Producto/Pedido |

Las expresiones completas, incluyendo el filtro `${servicio:regex}`,
se conservan en el dashboard y en
[CONSULTAS-GRAFANA.json](CONSULTAS-GRAFANA.json). Cada respuesta de panel
se guarda en `panel-02.json` a `panel-18.json`, con frames y muestras reales.
La tabla final de estados se comprobo tambien con sus respuestas reales y la
transformacion de series a filas (sin inventar valores):
[TABLA-ESTADOS-GRAFANA.json](TABLA-ESTADOS-GRAFANA.json) y
[panel-06-tabla.json](panel-06-tabla.json).

### Ventanas, Gateway y ausencia de datos

- `$__rate_interval` deriva del intervalo de 5s y conserva al menos cuatro
  scrapes; el verificador API utiliza **1m**. No se aplican `rate` a gauges.
- MVC filtra `uri=~"/api/.*"`. Gateway utiliza
  `spring_cloud_gateway_requests_seconds_count` y `_sum`; para exitosas,
  `httpStatusCode="200"`. Se unen las dos familias por job para mostrar el
  Gateway sin atribuirle las URI MVC.
- La latencia media requiere **denominador > 0**. Sin solicitudes no hay
  observacion, y el grafico deja un hueco; no se rellena con cero o datos falsos.
  No es un percentil ni un SLO historico.
- **Sin datos no significa DOWN**. Los gauges/contadores existentes pueden
  valer cero de forma legitima; una metrica no instrumentada no se fabrica.
- JDBC aparece en Categoria, Producto, Cliente y Pedido, no en infraestructura.
  Entre consultas se observaron conexiones activas cero; maximas **10**.
- CircuitBreaker tiene series en Producto, Cliente y Pedido; Retry solo en
  Producto y Pedido. No se inventan series para los otros servicios.
- Filtrar Config Server/Eureka deja HTTP **de negocio** sin series; filtrar
  infraestructura deja JDBC sin datos. Es esperado y se documenta en el panel.
- Fuera de una ventana con actividad, una latencia sin observaciones puede
  mostrar Sin datos. Las pruebas y capturas conservan sus fechas de actividad.

## H. Capturas reales

**14/14 obtenidas; ninguna pendiente.** Todas son nuevas de esta fase, Chrome
real con URL y `PrintWindow`, sin HTML fabricado ni reutilizacion de imagenes
de pasos anteriores. La version se muestra como salida real de herramienta
en archivo local; la conexion correcta como respuesta autentica de la API.

| Archivo | Evidencia |
|---|---|
| [01-descarga-grafana.png](01-descarga-grafana.png) | OSS, Windows y checksum de la pagina oficial |
| [02-version-grafana.png](02-version-grafana.png) | Version del ejecutable real |
| [03-grafana-login.png](03-grafana-login.png) | Login sin datos secretos rellenados |
| [04-grafana-inicio.png](04-grafana-inicio.png) | Inicio autenticado |
| [05-datasource-prometheus.png](05-datasource-prometheus.png) | Fuente provisionada y URL real |
| [06-conexion-prometheus-correcta.png](06-conexion-prometheus-correcta.png) | Health equivalente a Save & test, OK |
| [07-explore-consulta-up.png](07-explore-consulta-up.png) | Siete resultados de `up=1` |
| [08-dashboard-general.png](08-dashboard-general.png) | Resumen global y dashboard |
| [09-estado-microservicios.png](09-estado-microservicios.png) | Estado individual de los siete |
| [10-memoria-cpu.png](10-memoria-cpu.png) | Series JVM y CPU |
| [11-metricas-http.png](11-metricas-http.png) | Tasas, exitosas y latencia con trafico real |
| [12-conexiones-jdbc.png](12-conexiones-jdbc.png) | Pools de los servicios JDBC |
| [13-resilience4j.png](13-resilience4j.png) | CircuitBreaker y Retry reales |
| [14-filtro-microservicio.png](14-filtro-microservicio.png) | Producto seleccionado y series filtradas |

URLs, fechas y bytes: [CAPTURAS-PASO05.json](CAPTURAS-PASO05.json).
Dimensiones y SHA-256: `ScreenshotAudit` del JSON final. No se publican
cookies, headers de autorizacion ni perfiles de navegador.
Las capturas HTTP y Resilience4j fijan en la URL el intervalo del trafico
medido, con un minuto de margen antes/despues; consultan datos reales de la
TSDB sin repetir trafico. El dashboard conserva su rango inicial relativo de 15m.

## I. Archivos creados y modificados

Archivos de configuracion nuevos:

- `observabilidad/grafana/provisioning/datasources/prometheus.yml`.
- `observabilidad/grafana/provisioning/dashboards/lab15.yml`.
- `observabilidad/grafana/dashboards/lab15-observabilidad.json`.

Scripts nuevos:

- `Instalar-Grafana.ps1`, `Entorno-Grafana.ps1`, `Acceso-Grafana.ps1`.
- **`Iniciar-Grafana.ps1`, `Detener-Grafana.ps1`, `Verificar-Grafana.ps1`**.
- `Inicializar-Acceso-Grafana.mjs`, `Grafana-API.mjs`, `Verificar-Grafana.mjs`.
- `Crear-Dashboard-Grafana.mjs`, `Navegador-Lab15.mjs`, `Capturas-Grafana.mjs`.
- `Validar-Interfaz-Grafana.mjs`, `Integridad-Paso05.ps1`, `Finalizar-Paso05.ps1`.
- `Verificar-Estado-Grafana.mjs`: siete filas reales del panel de estados.

Modificaciones reutilizables:

- `README.md`: instalacion, seguridad, operacion, paneles, PromQL y resultados.
- `scripts/Verificar-Actuator.ps1`: admite `-Paso 05`, con salida separada y
  reutilizacion de los PID/protecciones del PASO 03.
- `scripts/Verificar-Servidor-Prometheus.mjs`: admite `--paso=05`, sin
  sobrescribir ningun resultado anterior.
- `scripts/Capturar-Ventana.ps1`: amplía la region de deteccion de contenido
  para aceptar salidas reales cortas de una sola linea.

Evidencias nuevas bajo `evidencias/04-grafana/`, incluidos este informe y el
JSON final; checkpoints y datos operativos ignorados bajo `.runtime/`.
El inventario completo de altas/cambios esta en `Integrity` del JSON final.
No se modifican fuentes Java, POM, dependencias Maven, JAR ni Prometheus.

## J. Trafico, interfaz y regresion

Se reutilizo el generador del PASO 04 con salida propia de PASO 05:

```powershell
& 'C:\Program Files\nodejs\node.exe' .\scripts\Verificar-Servidor-Prometheus.mjs --paso=05 --duracion=120
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verificar-Actuator.ps1 -Paso 05 -OmitirTrafico
```

- **24 rondas / 120 GET** sobre las cinco URL autorizadas, durante unos
  dos minutos. Sin POST/PUT/PATCH/DELETE de negocio ni pruebas agresivas.
- Siete targets UP antes/despues; **19 PromQL antes + 19 despues** y cuatro
  consultas de rango. Los contadores de las cuatro rutas Gateway aumentaron
  **+24** cada uno. Las cinco URL devolvieron HTTP 200 sin fallbacks inesperados.
- **17/17 paneles de datos** consultados por `/api/ds/query`: respuestas
  HTTP 200, frames y muestras numericas reales, sin errores de configuracion.
- Filtros API para los **siete jobs**, comprobando memoria, up, HTTP y JDBC.
- Validacion UI: cifras 7/0/7/100%, siete estados UP, **12 graficos renderizados**,
  refresco automatico real de consultas y filtro Producto que mantiene las
  cifras globales. Cero errores JavaScript/de consultas observados.
- **21/21 GET Actuator HTTP 200**; siete health UP; cinco aplicaciones
  esperadas en Eureka; cuatro rutas Gateway/directas y consultas compuestas
  reales correctas. Datos personales de respuestas de negocio sanitizados.
- Prueba anti-duplicado: volver a ejecutar el inicio reconoce el PID activo
  y no crea otro. `Detener-Grafana.ps1 -WhatIf` valida identidad sin detenerlo.

Resultados: [CONSULTAS-PROMETHEUS.json](CONSULTAS-PROMETHEUS.json),
[CONSULTAS-GRAFANA.json](CONSULTAS-GRAFANA.json),
[INTERFAZ-GRAFANA.json](INTERFAZ-GRAFANA.json),
[filtros-verificados.json](filtros-verificados.json),
[REGRESION-ACTUATOR.json](REGRESION-ACTUATOR.json).

## K. Bases e integridad Git

- Linea base anterior a la instalacion en `.runtime/paso05/integridad-antes.json`.
- **2.878 archivos externos**, incluidos **1.530 de Lab 14**, sin altas,
  eliminaciones ni modificaciones. Otros laboratorios intactos.
- Todas las evidencias anteriores, incluidas las 17 capturas y el informe
  satisfactorio del PASO 04, conservan SHA-256. No se reescribieron.
- Indice/staging, HEAD y estado externo de Git sin cambios. No se ejecuto
  add, commit, push, pull, reset, stash, checkout ni publicacion remota.
- Instantaneas JDBC **READ ONLY** antes/despues: mismos esquemas DEV,
  estructuras, filas, conteos y hashes. Solo lectura y rollback.
- Se mantienen Hibernate `validate`, SQL init `never`, Flyway/Liquibase
  deshabilitados y las protecciones Hikari/JDBC de los mismos procesos.
- config-repo sigue fijado al commit
  `39a22fc2d854d3549ce77cbb347cd20101b0d13f`, sin cambios ni publicacion.
- No recompilaciones, reinicios de Java/Prometheus/MariaDB ni cambios de puertos.
  Los siete Java, Prometheus y Grafana escuchan exclusivamente en localhost.
- Binarios fuera del repositorio o en `.runtime`; SQLite, logs, credenciales,
  plugins, datos y perfiles ignorados por Git. Revision publicable sin secretos.

`Database`, `Integrity`, `Microservices`, `Prometheus` y `Security` del JSON
final contienen las pruebas; no se afirma que esto equivalga a pruebas CRUD
exhaustivas ni a garantizar operaciones ajenas al alcance del laboratorio.

## L. Problemas encontrados y soluciones

1. **Pagina oficial dinamica:** la lectura sin JavaScript omitia el area de
   descargas. Se usaron metadatos oficiales y Chrome real para el checksum.
2. **Cambio de formato:** el enlace Windows independiente distribuye tar.gz;
   se detecto y extrajo con tar, sin instalar herramientas adicionales.
3. **Virtualizacion/render de Grafana:** una ventana oculta podia aparentar
   un layout vacio. Activar Chrome y pedir un repintado real resolvio la captura,
   sin fabricar contenido ni cambiar datos.
4. **Salida de version de una linea:** el detector original empezaba demasiado
   abajo. Se amplio la region de lectura de pixeles para aceptar esa salida real.
5. **`-WhatIf` en PowerShell 5.1:** interferia con una lectura interna de
   `Get-FileHash`. La identidad ahora usa SHA-256 por .NET en modo de lectura;
   `ShouldProcess` sigue protegiendo exclusivamente la detencion.
6. **Rutas de `/api/admin/settings`:** la API codifica Unicode y normaliza
   espacios en su representacion. Se contrasta esa representacion y se
   comprueban por separado las rutas reales del INI/archivos. No se movieron
   datos ni se reinicio Grafana para resolver una diferencia de presentacion.
7. **Legibilidad:** eje CPU automatico con unidad porcentaje, colores de estado
   gobernados por umbrales y tabla de siete filas para evitar comprimir los
   siete nombres en un Stat pequeno. La tabla conserva la consulta `up`, sin
   transformar ausencia de observaciones en un DOWN.
   Los ajustes del dashboard se recargaron por provisioning, sin reiniciar.

Los errores intermedios se corrigieron antes de marcar el paso completado;
los checkpoints y logs privados permiten reconstruir el progreso.

## M. Comandos de operacion y recuperacion

Desde `fernandez_lab15`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Iniciar-Grafana.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verificar-Grafana.ps1 -SoloConexion
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Detener-Grafana.ps1 -WhatIf
# Solo si se desea detener Grafana; NO se ejecuto al terminar:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Detener-Grafana.ps1
```

El script de detencion comprueba PID, fecha de inicio, ejecutable, argumentos,
directorio operativo y huella antes de actuar. No mata por puerto/nombre ni
detiene procesos ajenos; conserva SQLite, TSDB y los servicios existentes.

Para retomar tras interrupcion: revisar `.runtime/paso05/checkpoint-*.json`,
el recibo y registro de Grafana y el manifiesto de capturas. No reinstalar
ni regenerar la credencial existente. El capturador omite capturas registradas;
`--solo=...` permite reanudar las pendientes. El inventario `antes` se protege
contra sobrescritura. `Finalizar-Paso05.ps1` consolida el cierre sin trafico
de escritura y solo permite `Completed: true` si todas sus comprobaciones pasan.

## N. Preparacion para PASO 06

**PASO 05 completo; actividades adicionales pendientes: ninguna.**
El entorno queda preparado para **solicitar autorizacion** del PASO 06.
**PASO 06 no ejecutado. GitHub no publicado.**

Los siete microservicios, MariaDB, Prometheus y Grafana quedan ejecutandose;
sus PID y listeners finales se incluyen en la verificacion estructurada.
