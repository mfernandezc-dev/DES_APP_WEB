# PASO 03 — Micrometer Registry Prometheus

**Resultado satisfactorio: 7/7 endpoints Prometheus HTTP 200 y 21/21 pruebas
Actuator HTTP 200.** Ejecución local: 25/11/2026, UTC-05. Los siete servicios
quedan activos en localhost, sin duplicados. PASO 04 no ejecutado.

Se reutilizaron las protecciones y sondas anteriores. No se encontró un PDF
local de la guía; se ejecutaron las actividades y URL de la autorización,
sin atribuir una lectura de un documento no disponible.

Evidencias principales:

- [VERIFICACION-PASO03.json](VERIFICACION-PASO03.json): consolidación final.
- [DEPENDENCIAS-PASO03.json](DEPENDENCIAS-PASO03.json): resolución Maven y propiedad admitida.
- [PROMETHEUS-HTTP.json](PROMETHEUS-HTTP.json): muestras, etiquetas y contadores antes/después.
- [REGRESION-ACTUATOR.json](REGRESION-ACTUATOR.json): Actuator, negocio, Eureka y aislamiento.
- [CAPTURAS-PASO03.json](CAPTURAS-PASO03.json): diez capturas nuevas, URL y ocultamientos.
- `respuestas/`: respuestas JSON de regresión, sanitizadas antes de persistir.
- `.runtime/paso03/`: logs, PID, argumentos y originales, ignorados por Git.

## A. Dependencias y configuración efectiva

Se agregó una declaración en cada POM, sin versión manual y conservando Actuator:

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

| Servicio | Registro directo | Micrometer efectivo | Cliente Java Prometheus |
|---|---:|---|---|
| config-server | 1 | 1.17.2 | 1.7.0 |
| eureka-server | 1 | 1.17.2 | 1.7.0 |
| gateway-service | 1 | 1.17.2 | 1.7.0 |
| categoria-service | 1 | 1.17.2 | 1.7.0 |
| producto-service | 1 | 1.17.2 | 1.7.0 |
| cliente-service | 1 | 1.17.2 | 1.7.0 |
| pedido-service | 1 | 1.17.2 | 1.7.0 |

Se ejecutó Maven `dependency:tree -Dincludes=io.micrometer:*,io.prometheus:*`
en los siete servicios, todos con `BUILD SUCCESS`. Los árboles reales están
en `dependencias-<servicio>.txt`. Core, Commons, Observation, Jakarta9 y Registry
se resuelven en 1.17.2; los módulos `prometheus-metrics-*`, en 1.7.0.
Estas bibliotecas **no instalan el servidor Prometheus**.

Se conservaron Spring Boot **4.1.2**, Spring Cloud **2025.1.4**, Resilience4j
**2.4.0**, OpenFeign y los niveles Java originales, sin cambios de BOM.

Configuración integrada sin duplicar claves por documento YAML:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always
  prometheus:
    metrics:
      export:
        enabled: true
```

Los metadatos del JAR efectivo `spring-boot-micrometer-metrics-4.1.2.jar`
confirman `management.prometheus.metrics.export.enabled`, tipo Boolean,
predeterminado `true`. Se declara explícitamente por la actividad y se impone
por argumento para prevalecer sobre Config Server. La sonda verifica el valor
real y el bean `io.micrometer.prometheusmetrics.PrometheusMeterRegistry`.
No se eliminaron las configuraciones de Actuator o Resilience4j.

## B. Archivos modificados

**24 archivos anteriores:** siete `pom.xml`; siete `application.yml` o
`application.yaml`; `README.md`; y los siguientes nueve archivos de `scripts/`:

```text
Entorno-Lab15.ps1       Compilar-Lab15.ps1      Iniciar-Lab15.ps1
Detener-Lab15.ps1       Huellas-Bases.ps1       VerificarContexto.java
Verificar-Actuator.ps1  Capturar-Ventana.ps1    Capturas-Actuator.mjs
```

Nuevos: `Integridad-Paso03.ps1`, `Resolver-Micrometer.ps1`,
`Resolver-Metadatos.mjs`, `Consolidar-Dependencias.mjs`,
`Verificar-Prometheus.mjs`, `Finalizar-Paso03.ps1`, `capturas-paso03.json`
y evidencias de esta carpeta. No se modificaron fuentes Java de los siete
servicios. `VerificarContexto.java` es la sonda externa a sus fuentes/JAR.

Los scripts de inicio/detención aceptan `-Paso 03`, predeterminado actual.
El lanzador exige SHA-256 del JAR igual al de la compilación correcta y registra
argumentos/PID nuevos, sin sobrescribir los registros históricos del PASO 02.

## C. Compilaciones y reinicio

Antes de editar: ubicación exclusiva en Lab 15, siete PID históricos con
identidad/fecha comprobadas, salud UP, listeners locales, huellas SQL iniciales
e inventario de fuentes, evidencias y estado Git.

El primer `package` encontró JAR bloqueados por Windows. Se conservaron los
logs en `.runtime/paso03/compilacion-bloqueada/`; se cerraron exclusivamente
los siete procesos registrados mediante `Detener-Lab15.ps1 -Paso 02` y se
repitió el empaquetado sin bloqueos ni cambios de versiones.

| Servicio | Java objetivo conservado | Resultado final | Pruebas |
|---|---:|---|---|
| config-server | 17 | BUILD SUCCESS, exit 0 | Omitidas |
| eureka-server | 17 | BUILD SUCCESS, exit 0 | Omitidas |
| gateway-service | 17 | BUILD SUCCESS, exit 0 | Omitidas |
| categoria-service | 25 | BUILD SUCCESS, exit 0 | Omitidas |
| producto-service | 25 | BUILD SUCCESS, exit 0 | Omitidas |
| cliente-service | 25 | BUILD SUCCESS, exit 0 | Omitidas |
| pedido-service | 25 | BUILD SUCCESS, exit 0 | Omitidas |

Amazon Corretto **26.0.2.1**, Maven **3.9.16** y
`-Dmaven.test.skip=true -DskipTests package`. No se compilaron/ejecutaron
pruebas que pudieran conectar con bases compartidas. JAVA_HOME no se modificó
globalmente. Logs y hashes: `.runtime/paso03/build-<servicio>.log` y
`compilacion-todos.json`.

Orden: Config Server → Eureka → Categoria → Producto → Cliente → Pedido →
Gateway. Antes de cada inicio se comprobó puerto libre; antes de continuar,
disponibilidad HTTP y resultado válido de la sonda del contexto protegido.

## D. Siete procesos actuales

| Servicio | Puerto | PID | Salud | Escucha |
|---|---:|---:|---|---|
| config-server | 8888 | 26512 | UP | 127.0.0.1 |
| eureka-server | 8761 | 19156 | UP | 127.0.0.1 |
| categoria-service | 8082 | 12236 | UP | 127.0.0.1 |
| producto-service | 8083 | 25256 | UP | 127.0.0.1 |
| cliente-service | 8084 | 3672 | UP | 127.0.0.1 |
| pedido-service | 8085 | 11016 | UP | 127.0.0.1 |
| gateway-service | 8080 | 2604 | UP | 127.0.0.1 |

La verificación final confirma identidad, fecha, listeners y hashes del JAR
compilado/registrado/actual. Siete Java propios de PASO 03 y cero de PASO 02;
no hay duplicados ni artefactos antiguos. MariaDB/XAMPP sigue en **3306, PID
12400**, sin reinicio ni cambios globales.

Registro actual: `.runtime/paso03/procesos.json`, `<servicio>.args` y logs
stdout/stderr con fecha. Para detener únicamente estos procesos:

```powershell
# Previsualización, sin detener:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Detener-Lab15.ps1 -Paso 03 -WhatIf
# Detención efectiva, en orden inverso:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Detener-Lab15.ps1 -Paso 03
```

Se valida ejecutable, argumentos, ubicación y fecha; no se mata por puerto
o por nombre genérico y no se detiene MariaDB ni procesos ajenos.

## E. Siete endpoints Prometheus

En todos: **`text/plain;version=0.0.4;charset=utf-8`**, cuerpo completo con
HELP/TYPE y muestras numéricas; ninguna línea de muestra inválida. No es JSON,
HTML ni una página de error. Familias y series no son el mismo conteo.

| GET real | HTTP | HELP / TYPE | Muestras numéricas | TXT publicable |
|---|---:|---:|---:|---|
| http://localhost:8083/actuator/prometheus | 200 | 85 / 85 | 188 | [Producto](producto-service-prometheus.txt) |
| http://localhost:8082/actuator/prometheus | 200 | 74 / 74 | 139 | [Categoria](categoria-service-prometheus.txt) |
| http://localhost:8084/actuator/prometheus | 200 | 82 / 82 | 185 | [Cliente](cliente-service-prometheus.txt) |
| http://localhost:8085/actuator/prometheus | 200 | 85 / 85 | 185 | [Pedido](pedido-service-prometheus.txt) |
| http://localhost:8888/actuator/prometheus | 200 | 57 / 57 | 221 | [Config Server](config-server-prometheus.txt) |
| http://localhost:8761/actuator/prometheus | 200 | 55 / 55 | 122 | [Eureka](eureka-server-prometheus.txt) |
| http://localhost:8080/actuator/prometheus | 200 | 56 / 56 | 171 | [Gateway](gateway-service-prometheus.txt) |

Son instantáneas posteriores al tráfico; futuros scrapes pueden variar.

## F. Métricas identificadas por servicio

En los **siete** se encontraron:

```text
application_ready_time_seconds       application_started_time_seconds
jvm_memory_used_bytes                jvm_memory_max_bytes
jvm_threads_live_threads             process_cpu_usage
system_cpu_usage                     process_uptime_seconds
http_server_requests_seconds_count   http_server_requests_seconds_sum
```

En **Categoria, Producto, Cliente y Pedido**, también:
`hikaricp_connections_active`, `hikaricp_connections_max`,
`jdbc_connections_active` y `jdbc_connections_max`. No se exigen ni se
atribuyen métricas JDBC a Config Server, Eureka o Gateway. No faltó ninguna
métrica de referencia aplicable en los scrapes medidos.

Ejemplos numéricos reales (memoria sumada sobre sus series):

| Servicio | Ready, s | Started, s | Memoria usada, bytes | CPU proceso | Threads |
|---|---:|---:|---:|---:|---:|
| Producto | 18.529 | 18.463 | 230738216 | 0.017648 | 37 |
| Categoria | 15.743 | 15.674 | 216719024 | 0.011014 | 33 |
| Cliente | 18.507 | 18.429 | 261761784 | 0.007508 | 37 |
| Pedido | 18.655 | 18.591 | 263140216 | 0.011475 | 37 |
| Config Server | 8.900 | 8.839 | 154872560 | 0.015955 | 26 |
| Eureka | 9.559 | 9.485 | 202201472 | 0.005983 | 32 |
| Gateway | 11.621 | 11.617 | 175646184 | 0.048510 | 43 |

Pools JDBC: activas **0**, máximo **10** en los cuatro. Cero activas en reposo
es normal. Algunas series de memoria máxima reportan **-1** (límite no
definido), no una muestra inventada. CPU es una proporción.

Etiquetas reales: `area`, `id`, `pool`, `method`, `status`, `uri`, `kind`,
`name`, `state` y etiquetas Gateway. El JSON conserva sus valores concretos.
`main_application_class="VerificarContexto"` corresponde al lanzador protegido
real mediante PropertiesLauncher, no a una clase inventada.

Resilience4j: **12 nombres de muestra en Producto/Pedido y 9 en Cliente**:

```text
resilience4j_bulkhead_available_concurrent_calls
resilience4j_bulkhead_max_allowed_concurrent_calls
resilience4j_circuitbreaker_buffered_calls
resilience4j_circuitbreaker_calls_seconds_count
resilience4j_circuitbreaker_calls_seconds_sum
resilience4j_circuitbreaker_calls_seconds_max
resilience4j_circuitbreaker_failure_rate
resilience4j_circuitbreaker_not_permitted_calls_total
resilience4j_circuitbreaker_slow_call_rate
resilience4j_circuitbreaker_slow_calls
resilience4j_circuitbreaker_state
resilience4j_retry_calls_total
```

Cliente tiene los nueve de CircuitBreaker; no se le atribuyen Bulkhead/Retry.
Categoria e infraestructura no presentan esas series. La diferencia con el
catálogo JSON anterior procede de normalización y expansión de timers.

| Servicio / circuito | successful | failed |
|---|---:|---:|
| Producto / categoriaService | 12 | 0 |
| Cliente / pedidoService | 1 | 0 |
| Pedido / productoService | 2 | 0 |

Se verificaron etiquetas, no solo descripciones HELP. No se provocaron caídas,
fallos artificiales, sobrecarga ni perfiles con demoras.

## G. Contadores HTTP antes y después

Después de las consultas funcionales iniciales: siete scrapes previos →
**tres rondas secuenciales de cuatro GET Gateway (12 solicitudes)** → siete
scrapes finales. Todas las solicitudes fueron HTTP 200 sin fallbacks; no se
reiniciaron procesos entre las dos medidas.

Servicios: `http_server_requests_seconds_count`, etiquetas `method="GET"`,
`status="200"`, `uri="/api/<recurso>"`:

| Servicio / recurso | Antes | Después | Incremento |
|---|---:|---:|---:|
| Categoria / categorias | 2 | 5 | +3 |
| Producto / productos | 2 | 5 | +3 |
| Cliente / clientes | 2 | 5 | +3 |
| Pedido / pedidos | 3 | 6 | +3 |

Gateway: `spring_cloud_gateway_requests_seconds_count`, etiquetas `routeId`,
`httpMethod="GET"`, `httpStatusCode="200"`:

| routeId | Antes | Después | Incremento |
|---|---:|---:|---:|
| categoria-service | 1 | 4 | +3 |
| producto-service | 1 | 4 | +3 |
| cliente-service | 1 | 4 | +3 |
| pedido-service | 1 | 4 | +3 |

No se confundieron con consultas al propio Actuator. Las llamadas Feign por
ID tienen sus propias series URI. Pedido parte de 3 porque la consulta
detallada comparte path con la colección.

## H. Regresión Actuator, salud, Eureka y aislamiento

| Servicio | /actuator | /actuator/health | /actuator/metrics | Salud |
|---|---:|---:|---:|---|
| Producto | 200 | 200 | 200 | UP |
| Categoria | 200 | 200 | 200 | UP |
| Cliente | 200 | 200 | 200 | UP |
| Pedido | 200 | 200 | 200 | UP |
| Config Server | 200 | 200 | 200 | UP |
| Eureka | 200 | 200 | 200 | UP |
| Gateway | 200 | 200 | 200 | UP |

La regresión reutilizada registró **138 GET**, omitiendo sus rondas de tráfico
para medirlas por separado. Los 404 deliberados de aislamiento y Gateway/routes
no corresponden a las 21 pruebas principales ni a negocio.

Eureka: cinco aplicaciones, una instancia UP cada una, anunciadas en
127.0.0.1: Categoria, Producto, Cliente, Pedido y Gateway. Config Server y
Eureka no están configurados para registrarse como clientes. Commit consumido:
`39a22fc2d854d3549ce77cbb347cd20101b0d13f`.

Los cuatro negocios conservan DB, cliente Config y descubrimiento UP.
Config Server conserva su indicador servidor UP y los indicadores
cliente/descubrimiento UNKNOWN no utilizados, como en PASO 02.

Discovery locator **false**. Las cinco pruebas proxy health y las **siete**
`http://localhost:8080/<servicio>/actuator/prometheus` devolvieron **404**.
El Prometheus propio del Gateway sí está disponible directamente en localhost.
No se abrió un puerto de administración adicional ni rutas públicas.

## I. Negocio y consultas compuestas

| GET | HTTP | Resultado |
|---|---:|---|
| http://localhost:8080/api/categorias | 200 | 2 categorías reales |
| http://localhost:8080/api/productos | 200 | 2 productos con categorías reales |
| http://localhost:8080/api/clientes | 200 | 1 cliente real |
| http://localhost:8080/api/pedidos | 200 | 1 pedido real |
| http://localhost:8085/api/pedidos?detallado=true | 200 | Cliente y producto reales |
| http://localhost:8084/api/clientes/pedidos/1 | 200 | Cliente → Pedido correcto |

Las cuatro respuestas Gateway coinciden con las directas. Se compararon
Producto–Categoria y Pedido–Cliente–Producto con los datos vivos en memoria.
Sin fallbacks inesperados ni mocks. Datos personales ocultados antes de
persistir. No se realizó POST, PUT, PATCH o DELETE ni se alteraron registros.

Todas las peticiones de prueba fueron GET. Esto no desactiva el protocolo
interno habitual de Eureka: los clientes realizan automáticamente su registro
y heartbeats, sin que sean pruebas CRUD ni escrituras en las bases de negocio.

## J. Diez capturas nuevas y anonimización

Chrome **158.0.8127.37** real, CDP por pipe y Win32 PrintWindow con URL visible.
Sin reutilizar PNG anteriores ni fabricar HTML. Las adicionales muestran
la exposición real desplazada a la familia indicada.

| Captura | URL visible / sección |
|---|---|
| [01-producto-prometheus.png](01-producto-prometheus.png) | http://localhost:8083/actuator/prometheus |
| [02-categoria-prometheus.png](02-categoria-prometheus.png) | http://localhost:8082/actuator/prometheus |
| [03-cliente-prometheus.png](03-cliente-prometheus.png) | http://localhost:8084/actuator/prometheus |
| [04-pedido-prometheus.png](04-pedido-prometheus.png) | http://localhost:8085/actuator/prometheus |
| [05-config-server-prometheus.png](05-config-server-prometheus.png) | http://localhost:8888/actuator/prometheus |
| [06-eureka-prometheus.png](06-eureka-prometheus.png) | http://localhost:8761/actuator/prometheus |
| [07-gateway-prometheus.png](07-gateway-prometheus.png) | http://localhost:8080/actuator/prometheus |
| [08-metricas-jvm.png](08-metricas-jvm.png) | Producto, jvm_memory_used_bytes |
| [09-metricas-http.png](09-metricas-http.png) | Producto, http_server_requests_seconds_count |
| [10-metricas-resilience4j.png](10-metricas-resilience4j.png) | Producto, resilience4j_circuitbreaker_calls_seconds_count |

**Ninguna pendiente.** Se cerró el navegador aislado de evidencia, no los Java.

Ocultamiento explícito y limitado:

- Dos etiquetas `path` por exposición, en `disk_free_bytes`/`disk_total_bytes`,
  contenían rutas locales absolutas. En los siete TXT se sustituyeron solo sus
  valores por `[REDACTADO]`: **14 sustituciones**. Se conservan formato, orden,
  HELP/TYPE, etiquetas restantes y todos los números.
- Los scrapes originales binarios antes/después están únicamente en
  `.runtime/paso03/*.original.txt`.
- Las primeras siete capturas ocultan esas dos regiones con rectángulos negros
  `[REDACTADO]`, sin cambiar métricas o números. Los PNG originales están solo
  en `.runtime/paso03/capturas-originales/`.
- Las capturas 08–10 no muestran esas rutas y no necesitan ocultamiento.
  Coordenadas/etiquetas ocultadas constan en CAPTURAS-PASO03.json.
- Perfiles Chrome, cookies y originales están ignorados. No se publicaron
  respuestas completas de env/configprops ni credenciales.

## K. Bases de datos y protecciones

En los mismos cuatro contextos que siguen atendiendo HTTP se comprobaron:
perfil exclusivamente dev, commit/label autorizado, DDL Spring **validate**,
propiedad real Hibernate de EntityManagerFactory **validate**, generate-ddl
false, SQL init never, Flyway/Liquibase false, Hikari y JDBC read-only,
`@@session.tx_read_only=1` y `SET SESSION TRANSACTION READ ONLY` sin cambios globales.

Al finalizar: **69 GET dirigidos a propiedades no sensibles de env**, origen
efectivo commandLineArgs y argumentos propios coincidentes. Valores HTTP
enmascarados. No se confunden con la lectura directa inicial de Hibernate/JDBC
en el mismo contexto. No hubo instrucciones DDL/DML ni endpoints de escritura.

Huellas iniciales antes del reinicio contra finales después del tráfico:

| Base / tabla | Antes | Después | SHA-256 estructura/datos |
|---|---:|---:|---|
| bd_categoria_dev.categoria | 2 | 2 | Iguales |
| bd_producto_dev.producto | 2 | 2 | Iguales |
| bd_cliente_dev.clientes | 1 | 1 | Iguales |
| bd_pedido_dev.detalle_pedido | 1 | 1 | Iguales |
| bd_pedido_dev.pedido | 1 | 1 | Iguales |

Todas las tablas base y todas sus filas, sin muestreo. Credenciales solo en
memoria/stdin, no en argumentos o archivos publicables. No se certifican
escrituras ni bases ajenas a estas cuatro DEV.

## L. Integridad y Git

- **1530 archivos de Lab 14 intactos**, mediante SHA-256.
- **2878 archivos externos** antes/después, sin cambios, eliminados o agregados;
  excluidos `.git`, `node_modules` y `.npm-cache` operativos.
- **174 archivos de evidencias anteriores intactos**, incluidos todos los del PASO 02.
- Índice idéntico byte a byte, SHA-256 antes/después:
  `8F774F87CFBD49BF356E4FBB00A0E431C30CD23F402C3250B8161A9301898B07`.
- Staging, estado externo, rama main y HEAD conservados. Sin add, commit, push,
  pull, reset, stash o checkout.
- config-repo local/remoto no editado; solo cache temporal de lectura ya
  preparado y commit fijo, sin push.
- PID, argumentos, originales, logs, clases, JAR y perfiles comprobados
  ignorados con git check-ignore. Sin credenciales detectadas en publicables.

## M. Incidencias y soluciones

1. **JAR bloqueados:** el primer repackage falló en los siete activos. Se
   preservaron logs, se cerraron solo los PID registrados y se recompilaron
   correctamente. El compilador ahora rechaza preventivamente recompilar JAR
   de procesos propios activos antes de escribir artefactos parciales.
2. **Plazo externo de 120 s:** la herramienta terminó el primer reinicio y sus
   descendientes antes de completar los siete. Se conservó su registro, se
   comprobó que no quedaban esos procesos y se reinició sin ese límite externo.
   Los PID finales constan en D; no hay duplicados.
3. **Consolidación auxiliar bloqueada:** los siete árboles Maven fueron
   correctos, pero la serialización desde objetos PowerShell agotó el plazo.
   Se cerró solo el auxiliar propio identificado por PID/argumentos/padre,
   sin detener microservicios. Se consolidaron los árboles reales como texto
   plano con Node/JSON y se validaron metadatos con jar del JDK existente.
   La comprobación corregida terminó satisfactoriamente, sin cambiar versiones.
4. **Rutas locales en disco:** se detectaron antes de publicar y se ocultaron
   como indica J, preservando originales y números.

Advertencias heredadas: compatibilidad MariaDB 5.5.5 reportada por Connector/J
frente al mínimo de MySQLDialect, open-in-view, caché simple LoadBalancer,
Eureka sin réplicas y validaciones internas de Gateway. No se alteraron
dependencias para ocultarlas. Estos GET no certifican todos los escenarios
SQL ni resiliencia ante fallos.

## N. Revisión manual y repetición

Siete enlaces completos en E/J. Comparación de formatos y negocio:

- http://localhost:8083/actuator/metrics
- http://localhost:8083/actuator/metrics/jvm.memory.used
- http://localhost:8083/actuator/prometheus
- http://localhost:8761/
- http://localhost:8080/api/productos
- http://localhost:8085/api/pedidos?detallado=true

Con los procesos activos:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verificar-Actuator.ps1 -Paso 03 -OmitirTrafico
& 'C:\Program Files\nodejs\node.exe' .\scripts\Verificar-Prometheus.mjs
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Integridad-Paso03.ps1 -Momento despues
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Finalizar-Paso03.ps1
```

Repetir cambia contadores y evidencias del PASO 03, no del PASO 02. No usar
verificadores históricos con PID nuevos ni arrancar otro conjunto con puertos
ocupados. No invocar escritura, refresh o descargas sensibles.

## O. Preparación para PASO 04

**Preparado para solicitar autorización:** siete exposiciones disponibles,
métricas y contadores comprobados, regresión satisfactoria e integridad preservada.

**PASO 04 no ejecutado:** no se instaló/configuró el servidor Prometheus, no
se instaló Grafana ni se ejecutó Docker. Los siete servicios quedan activos
para Chrome. Es necesaria una nueva autorización para continuar.
