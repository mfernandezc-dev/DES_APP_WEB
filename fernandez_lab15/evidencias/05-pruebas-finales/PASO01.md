# PASO 01 - Creacion y preparacion de la base

Fecha de ejecucion: 25/11/2026. Resultados de compilaciones, contextos y SQL
reales; no se generaron capturas ni se reutilizaron evidencias de Lab 14.

## A. Ruta

`C:\Users\USER\Desktop\4° Ciclo\Desarrollo de  App Web\DES_APP_WEB\fernandez_lab15`

La inexistencia del destino se comprobo antes de crearlo. Se copio desde el
directorio de trabajo, no desde el staging incompleto de Git.

## B. Arbol

Consultar [ESTRUCTURA-PASO01.txt](ESTRUCTURA-PASO01.txt): contiene todos los
directorios y archivos del destino, incluidos los generados ignorados.
La primera seccion permite identificar la estructura fuente versionable.

Se crearon las carpetas solicitadas de Prometheus, provisioning/dashboards
de Grafana y las cinco actividades de evidencias. Los `.gitkeep` solo
conservan directorios vacios: no representan configuraciones implementadas.

## C. Copia

| Servicio | Archivos copiados | Archivos excluidos dentro del servicio |
|---|---:|---:|
| config-server | 9 | 20 |
| eureka-server | 9 | 20 |
| gateway-service | 9 | 21 |
| categoria-service | 19 | 30 |
| producto-service | 19 | 30 |
| cliente-service | 17 | 28 |
| pedido-service | 28 | 44 |
| Total | **110** | **193** |

Se inventariaron 1530 archivos en el origen completo. Se excluyeron **1420**:
193 dentro de los servicios y 1227 fuera de ellos (operacion, evidencias,
IDE, README/scripts anteriores, etc.). Dentro de los 193: 185 generados y
8 innecesarios (siete HELP.md y gateway-service/img.png).

Los 56 archivos Java, incluidas las pruebas, y los siete POM permanecen
identicos al origen. Solo se ajustaron cinco YAML en el destino: la
referencia del Config Server y las defensas locales de los cuatro clientes.
Los scripts, README, .gitignore, marcadores e informes son archivos nuevos.

## D-E. Entorno y compilacion

JDK: Amazon Corretto **26.0.2.1**, instalado en
`C:\Users\USER\.jdks\corretto-26.0.2.1`. `java`, `javac` y Maven fueron
comprobados. Maven **3.9.16** uso ese JDK dentro del proceso de compilacion.
JAVA_HOME y PATH de Windows no se modificaron permanentemente; el entorno
padre sigue seleccionando Temurin 17.

Spring Boot **4.1.2**, Spring Cloud **2025.1.4** y todas las versiones de
dependencias se conservaron. No se modificaron los POM.

| Servicio | Nivel Java conservado | Resultado Maven | Pruebas ejecutadas |
|---|---:|---|---|
| config-server | 17 | BUILD SUCCESS, exit 0 | Ninguna |
| eureka-server | 17 | BUILD SUCCESS, exit 0 | Ninguna |
| gateway-service | 17 | BUILD SUCCESS, exit 0 | Ninguna |
| categoria-service | 25 | BUILD SUCCESS, exit 0 | Ninguna |
| producto-service | 25 | BUILD SUCCESS, exit 0 | Ninguna |
| cliente-service | 25 | BUILD SUCCESS, exit 0 | Ninguna |
| pedido-service | 25 | BUILD SUCCESS, exit 0 | Ninguna |

Se utilizo `-Dmaven.test.skip=true -DskipTests package`. No se compilaron ni
ejecutaron pruebas. No existen reportes surefire de esta compilacion.
Se inspeccionaron los JAR: bytecode major 61 para Java 17 y 69 para Java 25.
Logs originales en `.runtime/build-<servicio>.log`.

## F. Puertos

Se mantienen 8888 (Config), 8761 (Eureka), 8080 (Gateway), 8082 (Categoria),
8083 (Producto), 8084 (Cliente), 8085 (Pedido), 3306 (MariaDB), 9090
(Prometheus futuro) y 3000 (Grafana futuro). No se agregaron puertos alternos.

Antes de comprobar los contextos, todos los puertos Java estaban libres.
Al terminar, todos los anteriores excepto 3306 volvieron a estar sin escucha.
MariaDB/XAMPP conserva PID 12400. No quedaron procesos Java activos.

## G. Config Server fijo

Repositorio: `https://github.com/mfernandezc-dev/config-repo`.

Commit: `39a22fc2d854d3549ce77cbb347cd20101b0d13f`.

El Config Server de Lab 15 usa `git.default-label` con ese SHA completo y
`clone-on-start=true`. El lanzador fija tambien el label de los clientes.
El cache Git queda fuera del repositorio y se crea con identificador unico.

Se comprobo mediante HTTP que `/servicio/dev` y `/servicio/dev/<commit>`
devuelven la misma version esperada para los cuatro servicios. Despues se
arranco cada contexto de negocio y se verifico su `config.client.version`.
Las cuatro versiones efectivamente recibidas coinciden con el SHA fijado.
Esto comprueba el mecanismo con Spring Cloud Config Server **5.0.6** real.
No se escribio en el repositorio remoto.

Una consulta complementaria final a la API publica de GitHub no estuvo
disponible (WebException). No se utiliza para afirmar el estado de su rama
actual: la referencia consumida fue comprobada directamente por Config Server.

## H. Proteccion y comprobacion SQL

El origen remoto conserva `ddl-auto=update`. El lanzador soportado impone
por linea de comandos las propiedades Spring y Hibernate con `validate`,
desactiva generacion DDL, inicializacion SQL, Flyway y Liquibase y exige
Config Server disponible. El YAML local no se considera suficiente por si solo.

| Servicio | Perfil | Puerto | Base efectiva | Spring DDL / Hibernate real | Sesion SQL |
|---|---|---:|---|---|---|
| categoria-service | dev | 8082 | bd_categoria_dev | validate / validate | Solo lectura |
| producto-service | dev | 8083 | bd_producto_dev | validate / validate | Solo lectura |
| cliente-service | dev | 8084 | bd_cliente_dev | validate / validate | Solo lectura |
| pedido-service | dev | 8085 | bd_pedido_dev | validate / validate | Solo lectura |

La sonda obtuvo las propiedades reales del EntityManagerFactory y verifico
`@@session.tx_read_only=1`. Para la comprobacion se configuro Hikari de solo
lectura y proteccion de sesion, sin cambios globales de MariaDB.

Se revisaron inicializadores SQL, CommandLineRunner, ApplicationRunner,
PostConstruct, eventos, tareas programadas y migraciones: no se encontraron
inicializadores de arranque que escriban datos. Los metodos CRUD existentes
se preservan, pero no fueron invocados. Las pruebas con SpringBootTest no
se ejecutaron.

| Base / tabla | Filas antes | Filas despues |
|---|---:|---:|
| bd_categoria_dev.categoria | 2 | 2 |
| bd_producto_dev.producto | 2 | 2 |
| bd_cliente_dev.clientes | 1 | 1 |
| bd_pedido_dev.detalle_pedido | 1 | 1 |
| bd_pedido_dev.pedido | 1 | 1 |

Coinciden ademas los SHA-256 de las definiciones y de todas las filas de las
cinco tablas. No se emitieron INSERT, UPDATE, DELETE ni DDL. Las credenciales
se manejaron en memoria/stdin; no se incluyen en informes ni argumentos.

La comprobacion mantuvo Config Server y **un solo cliente de negocio por
vez**. Eureka se desactivo exclusivamente para estas sondas. No se levanto
el conjunto de siete servicios ni se probaron rutas Gateway/Feign de negocio.

## I-J. Integridad y Git

- Los **1530 archivos** del Lab 14 se compararon mediante SHA-256: ninguno
  agregado, eliminado o modificado.
- Los **754 archivos preexistentes** inventariados del repositorio conservan
  sus contenidos; no se alteraron otros laboratorios.
- No hay `.git` anidados dentro de Lab 15.
- El indice Git mantiene exactamente los mismos bytes y SHA-256.
- La rama sigue siendo `main` y HEAD sigue en `3caec9f`.
- Antes: 57 entradas AM (staging mas cambios posteriores) y 509 archivos
  sin seguimiento. Despues: las mismas 57 entradas AM y **638** archivos sin
  seguimiento: los 509 anteriores mas **129** exclusivamente de Lab 15,
  todos sin staging.
- `target`, `.runtime`, binarios de herramientas, datos operativos, secretos
  y preferencias locales estan ignorados; se comprobo con `git check-ignore`.
- No se ejecutaron add, commit, push, pull, reset o stash.

El JSON adjunto registra los conteos Git finales y las huellas de integridad.

## K. Incidencias y soluciones

1. **Advertencias Java 26 por stderr:** PowerShell 5.1 interrumpia el script
   pese a compilaciones correctas. Se separo el manejo de stderr del codigo
   de salida real de Maven, conservando los avisos en logs.
2. **Hint JDBC insuficiente en MariaDB:** `setReadOnly(true)` no activaba
   `@@session.tx_read_only`. Se agrego proteccion de sesion explicita y su
   comprobacion; no se modifico configuracion global ni datos.
3. **Cache JGit reutilizado en Windows:** AccessDeniedException sobre un
   packfile al recrear el directorio. Se usan caches nuevos fuera del proyecto,
   sin eliminar manualmente archivos ni cambiar dependencias.
4. **ExitCode de Start-Process:** una sonda Categoria valida fue interpretada
   como fallida porque PowerShell perdia el codigo. Se retiene el handle antes
   de esperar; la comprobacion completa posterior termino correctamente.
5. **Advertencia de dialecto:** Connector/J identifica MariaDB como 5.5.5 y
   Hibernate advierte que MySQLDialect requiere MySQL >= 8.0. Se documenta;
   no bloquea las comprobaciones realizadas ni autoriza cambiar driver/dialecto.

No se cambiaron fuentes Java de servicios, dependencias, niveles Java ni
funcionalidades para corregir estas incidencias.

## L. Preparacion para PASO 02

**Preparado para Spring Boot Actuator**, sujeto a nueva autorizacion.

Limites: compilacion y arranques individuales no certifican todas las
operaciones SQL, CRUD, registro Eureka, rutas Gateway o resiliencia de extremo
a extremo. No se agregaron dependencias de Actuator/Micrometer ni se instalaron
Prometheus/Grafana. El PASO 02 no se ejecuto.

Resultados estructurados: [VERIFICACION-PASO01.json](VERIFICACION-PASO01.json).
