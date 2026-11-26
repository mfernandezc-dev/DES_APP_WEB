# PASO 02 — Spring Boot Actuator y verificación real

**Resultado: satisfactorio.** Ejecución local del 25/11/2026 (UTC-05).
Los siete microservicios quedan ejecutándose en segundo plano y escuchan
exclusivamente en `127.0.0.1`. No se ejecutó el PASO 03.

Se reutilizaron README, scripts, sondas e informes del PASO 01. No se encontró
un PDF de la guía en el checkout; se verificaron las actividades y URL
indicadas expresamente en la autorización, sin atribuir una lectura del PDF.

Fuentes de evidencia:

- [VERIFICACION-PASO02.json](VERIFICACION-PASO02.json): comprobaciones,
  respuestas, procesos, protecciones, integridad y consolidación final.
- [respuestas/](respuestas/): 147 respuestas HTTP reales en JSON, con URL,
  código HTTP y cuerpo; datos personales ocultados antes de persistir.
- [CAPTURAS-PASO02.json](CAPTURAS-PASO02.json): navegador, archivos, URL,
  fecha y códigos de las 18 capturas reales.
- Operación no publicable: `../../.runtime/paso02/`, ignorada por Git.

## A. Dependencias por servicio

| Servicio | Acción sobre spring-boot-starter-actuator |
|---|---|
| config-server | Agregada directamente |
| eureka-server | Declarada directamente; antes era transitiva |
| categoria-service | Agregada directamente |
| gateway-service | Ya existente; conservada sin duplicar |
| producto-service | Ya existente; conservada sin duplicar |
| cliente-service | Ya existente; conservada sin duplicar |
| pedido-service | Ya existente; conservada sin duplicar |

Los siete POM tienen exactamente una declaración directa. Se conservaron
Spring Boot **4.1.2**, Spring Cloud **2025.1.4**, Resilience4j **2.4.0** y los
niveles Java originales. Los siete JAR se inspeccionaron: ninguno contiene
`micrometer-registry-prometheus` ni bibliotecas Prometheus.

## B. Archivos modificados y configuración

Archivos preexistentes modificados (13):

1. `config-server/pom.xml`.
2. `eureka-server/pom.xml`.
3. `categoria-service/pom.xml`.
4. `config-server/src/main/resources/application.yaml`.
5. `eureka-server/src/main/resources/application.yaml`.
6. `gateway-service/src/main/resources/application.yaml`.
7. `categoria-service/src/main/resources/application.yml`.
8. `producto-service/src/main/resources/application.yml`.
9. `cliente-service/src/main/resources/application.yml`.
10. `pedido-service/src/main/resources/application.yml`.
11. `scripts/Entorno-Lab15.ps1`.
12. `scripts/VerificarContexto.java` (sonda externa a los JAR).
13. `README.md`.

Nuevos scripts: `Integridad-Paso02.ps1`, `Huellas-Bases.ps1`,
`Iniciar-Lab15.ps1`, `Detener-Lab15.ps1`, `Verificar-Actuator.ps1`,
`Finalizar-Paso02.ps1`, `Capturar-Ventana.ps1` y `Capturas-Actuator.mjs`.
También se agregaron este informe, los JSON y los 18 PNG de esta carpeta.
No se modificó ninguna fuente Java de los siete servicios, ni sus contratos
CRUD/Feign, configuraciones Resilience4j o informes históricos del PASO 01.

Configuración integrada en los siete servicios, sin duplicar claves dentro
de un documento YAML:

```yaml
server:
  address: 127.0.0.1
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always
```

Se conservó la separación de documentos `---` de los clientes. Las
propiedades se fijan además por argumentos de arranque, que prevalecen
sobre Config Server. `env` y `configprops` mantienen `show-values=never`.
No se descargaron sus respuestas completas ni heapdumps.

**Solo entorno académico local:** listeners de negocio y Actuator en loopback.
El discovery locator del Gateway queda desactivado; se conservan las cuatro
rutas explícitas de negocio. Las cinco pruebas
`http://localhost:8080/<servicio>/actuator/health` devolvieron **404**.
No se publica Actuator de otros servicios mediante el Gateway. El Actuator
propio del Gateway continúa disponible directamente en su puerto local.

## C. Compilaciones

Comando utilizado desde Lab 15:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Compilar-Lab15.ps1
```

| Servicio | Java objetivo conservado | Resultado Maven | Pruebas |
|---|---:|---|---|
| config-server | 17 | BUILD SUCCESS, exit 0 | Omitidas |
| eureka-server | 17 | BUILD SUCCESS, exit 0 | Omitidas |
| gateway-service | 17 | BUILD SUCCESS, exit 0 | Omitidas |
| categoria-service | 25 | BUILD SUCCESS, exit 0 | Omitidas |
| producto-service | 25 | BUILD SUCCESS, exit 0 | Omitidas |
| cliente-service | 25 | BUILD SUCCESS, exit 0 | Omitidas |
| pedido-service | 25 | BUILD SUCCESS, exit 0 | Omitidas |

Maven **3.9.16**, Amazon Corretto **26.0.2.1**; argumentos
`-Dmaven.test.skip=true -DskipTests package`. No se compilaron ni ejecutaron
las pruebas heredadas que podrían conectar con las bases compartidas.
Logs: `.runtime/build-<servicio>.log`; resumen `.runtime/compilacion-todos.json`.
JAVA_HOME se seleccionó solo dentro de los procesos, nunca globalmente.

## D. Servicios en ejecución

Orden real: Config Server → Eureka → Categoria → Producto → Cliente → Pedido
→ Gateway. Se comprobaron puertos libres antes de cada inicio y se esperó
la disponibilidad HTTP y el resultado válido de la sonda antes de continuar.

| Orden | Servicio | Puerto | PID | Salud final | Escucha |
|---:|---|---:|---:|---|---|
| 1 | config-server | 8888 | 19780 | UP | 127.0.0.1 |
| 2 | eureka-server | 8761 | 23920 | UP | 127.0.0.1 |
| 3 | categoria-service | 8082 | 8000 | UP | 127.0.0.1 |
| 4 | producto-service | 8083 | 23628 | UP | 127.0.0.1 |
| 5 | cliente-service | 8084 | 9632 | UP | 127.0.0.1 |
| 6 | pedido-service | 8085 | 25120 | UP | 127.0.0.1 |
| 7 | gateway-service | 8080 | 24332 | UP | 127.0.0.1 |

MariaDB de XAMPP permanece activa en **3306, PID 12400**. No se reinició.
Se comprobó nuevamente la identidad y fecha de cada proceso, sus listeners
y su salud después de las verificaciones. No hay procesos Java duplicados.

Registro propio: `.runtime/paso02/procesos.json`, con PID, puerto, fecha,
JAR, ejecutable y logs stdout/stderr. Los argumentos están en archivos
`.args` de esa misma carpeta; no contienen credenciales JDBC.

Para detener exclusivamente estos procesos, en orden inverso:

```powershell
# Vista previa, comprobada sin detener nada:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Detener-Lab15.ps1 -WhatIf
# Detención efectiva cuando termine la revisión manual:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Detener-Lab15.ps1
```

El script valida ejecutable, argumentos propios, ubicación del registro y
fecha de inicio. No mata por puerto o por nombre genérico `java.exe` y no
detiene MariaDB. No ejecutar simultáneamente Lab 14 y Lab 15.

## E. Las 21 comprobaciones principales de Actuator

Todas fueron peticiones **GET reales**. En cada columna se muestra el código
de una petición distinta a la base local de la fila.

| Servicio / base | /actuator | /actuator/health | /actuator/metrics |
|---|---:|---:|---:|
| Producto — http://localhost:8083 | 200 | 200 | 200 |
| Categoria — http://localhost:8082 | 200 | 200 | 200 |
| Cliente — http://localhost:8084 | 200 | 200 | 200 |
| Pedido — http://localhost:8085 | 200 | 200 | 200 |
| Config Server — http://localhost:8888 | 200 | 200 | 200 |
| Eureka — http://localhost:8761 | 200 | 200 | 200 |
| Gateway — http://localhost:8080 | 200 | 200 | 200 |

Primero se verificó Producto, después Categoria, Cliente y Pedido, y
finalmente la infraestructura. Los 21 cuerpos están en
`respuestas/<servicio>-actuator.json`, `-health.json` y `-metrics.json`.

El verificador principal registró **150 GET: 144 HTTP 200 y seis HTTP 404**.
Los 404 corresponden a cinco rutas proxy deliberadamente inexistentes y a
`/actuator/gateway/routes`; ninguno corresponde a las 21 pruebas principales
ni a las rutas funcionales. Las capturas, sondas de arranque y consolidación
final hacen GET adicionales y no se suman artificialmente a esos 150.

## F. Interpretación real de health y Eureka

`health` resume indicadores presentes, no demuestra por sí solo todos los
casos funcionales o la ausencia futura de fallos.

| Servicio | Estado general | Componentes relevantes realmente observados |
|---|---|---|
| Producto | UP | db UP, clientConfigServer UP, discoveryComposite UP |
| Categoria | UP | db UP, clientConfigServer UP, discoveryComposite UP |
| Cliente | UP | db UP, clientConfigServer UP, discoveryComposite UP |
| Pedido | UP | db UP, clientConfigServer UP, discoveryComposite UP |
| Config Server | UP | configServer UP; clientConfigServer UNKNOWN; discoveryComposite UNKNOWN |
| Eureka | UP | discoveryComposite UP; no componente db |
| Gateway | UP | discoveryComposite UP y reactiveDiscoveryClients UP; no componente db |

En los cuatro servicios de negocio, `discoveryComposite.components` muestra
`discoveryClient=UP` y `eureka=UP`; los detalles de Eureka indican registro
remoto `UP`. El componente JDBC dice `database: MySQL` porque así lo reporta
Connector/J; el servidor real sigue siendo **MariaDB/XAMPP**, no MySQL Server.

Los `UNKNOWN` de Config Server son reales y se conservan en la evidencia:
su indicador de cliente indica `no property sources located` y el de
descubrimiento `Discovery Client not initialized`. No consume configuración
remota como cliente de negocio ni está configurado para registrarse en Eureka.
Su indicador servidor `configServer` y su salud agregada son `UP`.

Eureka `/eureka/apps` devolvió HTTP 200 con cinco aplicaciones, una instancia
`UP` por aplicación: Categoria, Producto, Cliente, Pedido y Gateway; todas
anuncian `127.0.0.1` y sus puertos establecidos. **Config Server no debe
registrarse** con la configuración actual. Eureka tiene
`register-with-eureka=false` y `fetch-registry=false`; no se exige que se
registre a sí mismo.

No se inventa un componente `circuitBreakers` dentro de `health`: no apareció
en estos cuerpos. La resiliencia se verificó por sus endpoints y métricas.

## G. Pruebas funcionales y ausencia de fallbacks inesperados

| GET | HTTP | Resultado real |
|---|---:|---|
| http://localhost:8080/api/categorias | 200 | 2 categorías |
| http://localhost:8080/api/productos | 200 | 2 productos con categorías reales |
| http://localhost:8080/api/clientes | 200 | 1 cliente |
| http://localhost:8080/api/pedidos | 200 | 1 pedido |
| http://localhost:8085/api/pedidos?detallado=true | 200 | 1 pedido con cliente y producto reales |
| http://localhost:8084/api/clientes/pedidos/1 | 200 | Consulta real Cliente → Pedido |

Las cuatro respuestas Gateway coincidieron con sus respuestas directas.
Las relaciones Producto–Categoria y Pedido–Cliente–Producto se compararon
con los objetos reales devueltos, en memoria. Los conteos corresponden a las
tablas existentes. No se usaron respuestas mock ni fallbacks inesperados.

Se generaron **tres rondas secuenciales** de los cuatro GET Gateway (12
peticiones controladas), además de las consultas funcionales y directas.
No se realizó POST, PUT, PATCH o DELETE; no se alteraron registros.

## H. Métricas verificadas

`/actuator/metrics` enumera los nombres disponibles. Cada nombre específico
se consultó solo si realmente figuraba en el catálogo. Los valores cambian
con el tiempo; las cifras siguientes son instantáneas, no valores esperados
para futuras consultas.

| Servicio | jvm.memory.used, bytes | process.cpu.usage | hikaricp.connections.active | GET de negocio 200, COUNT |
|---|---:|---:|---:|---:|
| Producto | 284176824 | 0.07654 | 0 | 5 |
| Categoria | 253421560 | 0.08009 | 0 | 7 |
| Cliente | 293098792 | 0.06797 | 0 | 5 |
| Pedido | 277192720 | 0.09158 | 0 | 6 |
| Config Server | 130779840 | 0.04914 | No aplica | No aplica |
| Eureka | 137795600 | 0.07675 | No aplica | No aplica |
| Gateway | 213921928 | 0.08647 | No aplica | Ver métricas HTTP del Gateway |

Las cuatro columnas de métricas específicas aplicables devolvieron **200**.
Las series HTTP de negocio se filtraron por `uri`, `method:GET` y
`status:200`, no se confundieron con las peticiones al propio Actuator.
Pedido tiene dos mappings en el mismo path, por lo que su serie puede incluir
la consulta detallada. Categoria también recibió consultas GET desde Feign.

Además:

- `system.cpu.usage` y `http.server.requests`: HTTP 200 en los siete servicios.
- `jdbc.connections.active`, `jdbc.connections.max` y
  `jdbc.connections.min`: HTTP 200 en los cuatro servicios JDBC. Pool máximo
  y mínimo observados: 10; activas 0 al consultar, situación normal en reposo.
- No se atribuyen métricas JDBC a Config Server, Eureka o Gateway.
- Resilience4j: **10 nombres** reales en Producto, **7** en Cliente y **10**
  en Pedido. No aparecen en Categoria ni en la infraestructura.

Nombres Resilience4j observados en Producto y Pedido:

```text
resilience4j.bulkhead.available.concurrent.calls
resilience4j.bulkhead.max.allowed.concurrent.calls
resilience4j.circuitbreaker.buffered.calls
resilience4j.circuitbreaker.calls
resilience4j.circuitbreaker.failure.rate
resilience4j.circuitbreaker.not.permitted.calls
resilience4j.circuitbreaker.slow.call.rate
resilience4j.circuitbreaker.slow.calls
resilience4j.circuitbreaker.state
resilience4j.retry.calls
```

Cliente presenta los siete nombres `resilience4j.circuitbreaker.*` de esa
lista; no se le atribuyen métricas de Retry/Bulkhead ausentes.
Los GET a `circuitbreakers`, `circuitbreakerevents`, `retries`, `retryevents`,
`bulkheads` y `bulkheadevents` devolvieron 200 en los tres servicios con esa
dependencia; disponibilidad del endpoint no significa que todos tengan
instancias configuradas.

Confirmación complementaria por etiquetas de `circuitbreaker.calls`:

| Servicio / circuito | successful | failed | ignored |
|---|---:|---:|---:|
| Producto / categoriaService | 12 | 0 | 0 |
| Cliente / pedidoService | 1 | 0 | 0 |
| Pedido / productoService | 2 | 0 | 0 |

Una consulta sin etiquetas agrega series y su descripción no basta para
interpretar las llamadas como fallidas. Una tasa `-1` en circuitos con pocas
llamadas significa que aún no hay muestra mínima; no equivale a una falla.
No se ejecutaron pruebas de interrupción o sobrecarga en este paso.

## I. Capturas reales

Las 18 capturas provienen de **Chrome 158.0.8127.37 real**, con perfil
aislado ignorado por Git. Se navegó mediante CDP por pipe, sin abrir un
puerto de depuración. Win32 `PrintWindow` capturó la ventana del navegador
con su barra de direcciones, sin montar HTML ni fabricar capturas.

| Archivo | URL mostrada |
|---|---|
| [01-producto-actuator.png](01-producto-actuator.png) | http://localhost:8083/actuator |
| [02-producto-health.png](02-producto-health.png) | http://localhost:8083/actuator/health |
| [03-producto-metrics.png](03-producto-metrics.png) | http://localhost:8083/actuator/metrics |
| [04-categoria-actuator.png](04-categoria-actuator.png) | http://localhost:8082/actuator |
| [05-categoria-health.png](05-categoria-health.png) | http://localhost:8082/actuator/health |
| [06-categoria-metrics.png](06-categoria-metrics.png) | http://localhost:8082/actuator/metrics |
| [07-cliente-actuator.png](07-cliente-actuator.png) | http://localhost:8084/actuator |
| [08-cliente-health.png](08-cliente-health.png) | http://localhost:8084/actuator/health |
| [09-cliente-metrics.png](09-cliente-metrics.png) | http://localhost:8084/actuator/metrics |
| [10-pedido-actuator.png](10-pedido-actuator.png) | http://localhost:8085/actuator |
| [11-pedido-health.png](11-pedido-health.png) | http://localhost:8085/actuator/health |
| [12-pedido-metrics.png](12-pedido-metrics.png) | http://localhost:8085/actuator/metrics |
| [13-eureka-servicios.png](13-eureka-servicios.png) | http://localhost:8761/ |
| [14-gateway-actuator.png](14-gateway-actuator.png) | http://localhost:8080/actuator |
| [15-config-server-health.png](15-config-server-health.png) | http://localhost:8888/actuator/health |
| [16-gateway-pruebas.png](16-gateway-pruebas.png) | http://localhost:8080/api/categorias |
| [17-metrica-http-requests.png](17-metrica-http-requests.png) | http://localhost:8083/actuator/metrics/http.server.requests |
| [18-metrica-jvm-memory.png](18-metrica-jvm-memory.png) | http://localhost:8083/actuator/metrics/jvm.memory.used |

**Pendientes: ninguna de las 18 solicitadas.** La captura 16 muestra la ruta
de categorías; las otras tres rutas están respaldadas por respuestas JSON.
Las dos capturas de métricas se renovaron tras generar tráfico funcional.
El navegador de evidencia fue cerrado; los siete Java permanecen activos.

## J. Protección efectiva de bases de datos

En los cuatro contextos reales se comprobó:

- Perfil activo exclusivamente `dev`; no se utilizó `lab`.
- Config recibida y label en el commit
  `39a22fc2d854d3549ce77cbb347cd20101b0d13f`.
- `spring.jpa.hibernate.ddl-auto=validate` y propiedad real
  `EntityManagerFactory.hibernate.hbm2ddl.auto=validate`.
- `spring.jpa.generate-ddl=false`, `spring.sql.init.mode=never`,
  `spring.flyway.enabled=false`, `spring.liquibase.enabled=false`.
- Hikari de solo lectura, conexión JDBC de solo lectura y
  `@@session.tx_read_only=1`, mediante
  `SET SESSION TRANSACTION READ ONLY` sin cambios SQL globales.

La sonda se ejecuta en el mismo contexto que sigue atendiendo HTTP; no es
una segunda instancia temporal. Se mantiene el arranque estricto contra
Config Server, sin fallback opcional a configuración incompleta.

Al finalizar se hicieron **61 GET dirigidos a `/actuator/env/{propiedad}`**
para comprobar nuevamente origen efectivo, perfil y protecciones. En todos
los casos prevalece `commandLineArgs` y el argumento propio coincide con el
valor esperado. Los valores HTTP continúan enmascarados (`******`), incluso
los no sensibles: no se debilitó la protección de `env`. El resultado inicial
de Hibernate/JDBC, la identidad del mismo proceso y esta comprobación final
de precedencia se conservan juntos en el JSON; no se confunde una respuesta
HTTP enmascarada con una lectura directa del EntityManagerFactory.

| Base / tabla | Antes | Después | Estructura SHA-256 | Filas SHA-256 |
|---|---:|---:|---|---|
| bd_categoria_dev.categoria | 2 | 2 | Igual | Igual |
| bd_producto_dev.producto | 2 | 2 | Igual | Igual |
| bd_cliente_dev.clientes | 1 | 1 | Igual | Igual |
| bd_pedido_dev.detalle_pedido | 1 | 1 | Igual | Igual |
| bd_pedido_dev.pedido | 1 | 1 | Igual | Igual |

Las comparaciones incluyen todas las tablas base de esas cuatro bases y
todas sus filas, no solo una muestra. Se repitió la comparación al consolidar
el informe. Las credenciales se obtuvieron en memoria desde Config Server y
se pasaron a JDBC por stdin; no se persistieron ni se imprimieron.

No se verificaron otras bases ajenas al laboratorio ni se modificaron sus
configuraciones. Estas verificaciones no certifican operaciones de escritura.

## K. Integridad de Lab 14 y Git

- **1530 archivos de Lab 14 intactos**, comprobados mediante SHA-256.
- **2878 archivos externos** inventariados antes y después: ninguno agregado,
  eliminado o modificado. Incluye los otros laboratorios del checkout; se
  excluyen `.git`, `node_modules` y `.npm-cache` como directorios operativos.
- Índice Git idéntico byte a byte, SHA-256 antes/después:
  `8F774F87CFBD49BF356E4FBB00A0E431C30CD23F402C3250B8161A9301898B07`.
- Staging previo y estado Git fuera de Lab 15 sin cambios; rama `main` y HEAD
  conservados. Todos los cambios de este paso quedan sin staging en Lab 15.
- No se ejecutó `git add`, `commit`, `push`, `pull`, `reset`, `stash` o `checkout`.
- No se modificó `config-repo` local ni remoto. El cache de lectura JGit sigue
  el mecanismo temporal ya preparado en PASO 01; no es una edición del remoto.
- `.runtime`, archivos de argumentos, PID/logs, JAR/target y perfiles Chrome
  se comprobaron ignorados con `git check-ignore`.
- El análisis de JSON publicables no detectó valores sensibles. Nombres de
  clientes, apellidos, dirección y DNI se ocultaron antes de guardar respuestas;
  no se usaron capturas de clientes que expusieran datos personales.

Las huellas detalladas permanecen en `.runtime/paso02/integridad-*.json`; el
resumen publicable se incluye en `VERIFICACION-PASO02.json`.

## L. Problemas reales y soluciones

1. **Discovery locator del Gateway habilitado:** podía crear rutas
   administrativas automáticas. Se desactivó y se verificaron los cinco 404
   esperados sin perder las cuatro rutas de negocio.
2. **Clase de Eureka en el nuevo lanzador:** el primer intento usó
   `com.tecsup.EurekaServerApplication`; la clase real pertenece al paquete
   `com.tecsup.eureka`. Se corrigió solo el lanzador. El intento fallido cerró
   exclusivamente sus procesos; después se inició el conjunto sin duplicados.
3. **Arrays en Windows PowerShell 5.1:** envolver directamente la salida de
   `ConvertFrom-Json` creó un array anidado y una consulta CIM de PID inválida.
   Se corrigió la deserialización, se normalizaron los arrays de los informes
   y se repitió la verificación. No se detuvo ningún proceso ajeno.
4. **Content-Type Actuator:** sin `Accept: application/json`, PowerShell podía
   entregar un `byte[]` y convertir sus bytes en números JSON. Se agregó
   negociación explícita y decodificación UTF-8; se repitieron las consultas
   finales y se sustituyó la evidencia incorrectamente decodificada por JSON
   real, nunca por valores inventados.
5. **Captura Chromium vacía al renovar métricas:** se detectó en la revisión
   visual. Se forzó activación y renderizado de la pestaña real, se aisló cada
   sesión y se agregó control de contenido visible. La captura final usa la
   ventana real; no se guardó una captura de escritorio ajeno ni se simuló HTML.
6. **Inventario de un cache npm externo con rutas largas:** PowerShell no pudo
   resolver una ruta operativa. Se excluyeron `.npm-cache` y `node_modules`
   antes de crear la línea base; se mantuvo el inventario de fuentes y de los
   1530 archivos de Lab 14. No se editó o eliminó ese cache.
7. **`/actuator/gateway/routes` devolvió 404:** el endpoint administrativo
   específico no está habilitado por el acceso predeterminado de esta versión.
   `exposure.include="*"` no habilita por sí solo todos los accesos posibles.
   No se abrió innecesariamente para aprobar las tres pruebas requeridas;
   el enrutamiento efectivo se demostró con GET de negocio reales.

Advertencias conservadas, sin cambios de versiones o funciones ajenas:

- Hibernate identifica MariaDB mediante Connector/J como compatibilidad 5.5.5
  y advierte mínimo MySQL 8 para MySQLDialect. Las validaciones y GET concretos
  funcionaron; esto no certifica toda operación SQL posible.
- `open-in-view` habilitado y cache simple de Spring Cloud LoadBalancer:
  recomendaciones de configuración, no fallos de los GET comprobados.
- Eureka standalone informa ausencia de réplicas; no se exige un clúster.
- Hibernate Validator advierte `@Valid` en contenedores dentro de Gateway.
- Avisos de herramientas Java 26 se conservan en logs; los siete Maven
  terminaron con código real 0.

## M. Revisión manual y repetición

La tabla E contiene las siete bases y tres paths exactos. Comenzar por:

- http://localhost:8083/actuator
- http://localhost:8083/actuator/health
- http://localhost:8083/actuator/metrics
- http://localhost:8761/
- http://localhost:8080/api/productos
- http://localhost:8085/api/pedidos?detallado=true

Las tablas G e I incluyen los enlaces restantes. No invocar endpoints de
escritura, `refresh`, cambios de logging ni descargas con información sensible.

Para repetir las verificaciones con los siete procesos ya activos:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verificar-Actuator.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Integridad-Paso02.ps1 -Momento despues
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Finalizar-Paso02.ps1
```

No volver a ejecutar el lanzador mientras estén activos: abortará ante puertos
ocupados. Los resultados y contadores de una repetición pueden variar.

## N. Preparación para PASO 03

**Base preparada para solicitar autorización del PASO 03:** siete servicios
reales disponibles, Actuator funcional, métricas JVM/CPU/HTTP/JDBC y
Resilience4j verificadas, evidencia reproducible e integridad preservada.

**PASO 03 no ejecutado.** No se agregó el registro Prometheus, no se instaló
Prometheus ni Grafana y no se creó su configuración. Se requiere una nueva
autorización antes de continuar. Los siete microservicios quedan en segundo
plano para la revisión del usuario.
