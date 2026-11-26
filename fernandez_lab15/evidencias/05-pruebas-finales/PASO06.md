# PASO 06 — Recuperación y cierre académico del Laboratorio 15

El estado definitivo, fecha, cantidad y bytes publicables se encuentran en
[VERIFICACION-PASO06.json](VERIFICACION-PASO06.json) e
[INVENTARIO-PUBLICACION.txt](INVENTARIO-PUBLICACION.txt). Este informe no
autoriza publicar ni ejecutar el PASO 07.

## A. Actividades recuperadas

Se continuó desde `.runtime/paso06/`, sin reiniciar el trabajo del Prompt 08.
Los checkpoints inicial, capturas, scripts, FG, UI y pruebas finales estaban
completos. Se conservaron:

- Auditoría técnica/visual de 59 PNG históricos y 794 archivos de evidencia.
- Seis capturas reales nuevas ya obtenidas antes de la interrupción.
- Pruebas finales válidas: 21 consultas Actuator, siete exportadores, seis
  rutas funcionales GET y siete rechazos de proxy administrativo.
- Consultas de 17 paneles de datos, siete filtros, Explore y refresco UI de 5s.
- Inicio idempotente y detención `-WhatIf` ya verificados, sin repetirlos.
- README de 24 secciones con 29 imágenes, entregable y cinco conclusiones en
  cada documento; selección de imágenes con hashes y procedencia.
- Auditoría académica y vista previa local terminadas correctamente.

La validación documental anterior era provisional: registraba enlaces a
archivos de cierre que aún no existían. `VERIFICACION-PASO06.json` tenía
`Completed: false`, el inventario era provisional y faltaba este informe.

## B. Pendientes completados

Se consolidaron la verificación, este informe, el inventario exacto y la
validación documental. Se contrastaron los hashes de evidencias e imágenes
con los manifiestos recuperados. No se repitieron instalaciones,
compilaciones, tráfico de prueba ni capturas válidas de las actividades.

**Incidencia real al reanudar:** ninguno de los nueve procesos del laboratorio
estaba activo; MariaDB sí lo estaba. No era correcto declarar que los PID
históricos seguían saludables. Se preservaron sus registros en
`.runtime/paso06/registros-previos-recuperacion/` y se ejecutó una sola vez
`Iniciar-Todo-Lab15.ps1`, reutilizando instalaciones y artefactos aprobados.
Las protecciones JDBC/DDL se verificaron en los nuevos contextos. No se
inició ni detuvo MariaDB y no se crearon procesos duplicados.

Se corrigió la preparación de Grafana para reutilizar una ACL privada ya
correcta, sin exigir privilegios de SACL ni cambiar credenciales. El arranque
de Prometheus volvió a validar su YAML; su helper ahora guarda las siguientes
validaciones en `.runtime/` cuando ya existe evidencia histórica. El JSON
histórico se recuperó desde el resultado embebido del PASO 04 y se comprobó
su SHA-256 idéntico a la línea base; la validación nueva queda privada.

README y entregable aclaran esta recuperación. La vista previa anterior se
preservó en la carpeta privada antes de regenerarla por ese cambio textual;
esto no añade ni sustituye capturas académicas publicables.

## C–D. Capturas e imágenes incorporadas

| Concepto | Cantidad |
|---|---:|
| Actuator | 18 |
| Micrometer | 10 |
| Prometheus | 17 |
| Grafana | 14 |
| Capturas nuevas ya existentes del PASO 06 | 6 |
| Total publicable | **65** |
| Imágenes insertadas directamente en README | **29** |
| Originales reutilizados en README | 23 |
| Capturas de `evidencias/readme/` en README | 6 |
| Capturas académicas creadas durante esta recuperación | **0** |

El diagrama Mermaid es arquitectura técnica identificada, no una captura
ficticia. La vista previa y hojas de revisión son operativas, privadas e
ignoradas; no se suman a las 65 capturas publicables. Grafana está destacado
al principio del README. Las imágenes mantienen resolución de 1500 × 850 y
se pueden abrir a tamaño original. El detalle de Pedido tiene máscaras
documentadas sobre datos personales; el original no es publicable.

## E. Validación de imágenes y enlaces

Las 29 referencias del README son rutas relativas a archivos PNG reales,
con mayúsculas/minúsculas exactas, no ignorados por Git y hashes coincidentes.
Se comprueban también las ocho inserciones del entregable: 37 usos en total,
sin duplicar físicamente las imágenes. El resultado actualizado y los
enlaces relativos están en
[VALIDACION-DOCUMENTACION.json](VALIDACION-DOCUMENTACION.json).

No se afirma haber auditado la disponibilidad de sitios web externos.
El dashboard local se comprueba por su API. Las rutas locales de informes
históricos pueden revelar nombres de máquina/carpeta, no credenciales; la
atribución académica del autor se conserva. La revisión de secretos usa
reglas de alta confianza y no equivale a una auditoría exhaustiva.

## F. Auditoría académica

[AUDITORIA-GUIA.json](AUDITORIA-GUIA.json) terminó con `Completed: true` y
17 requisitos obligatorios verificados. Se distingue lo obligatorio de las
mejoras de dashboard, filtros, scripts e integridad. No se atribuyen tracing,
logs centralizados ni alertas a prácticas no implementadas.

**Límite de la fuente:** no se dispone del PDF de la guía en este checkout.
La matriz utiliza las 17 actividades enumeradas en la autorización previa;
no se declara una comparación directa con páginas de un PDF ausente.

## G. Vista previa del README

[VISTA-PREVIA-README.json](VISTA-PREVIA-README.json) verifica la carga de
29 imágenes y 24 secciones. El HTML y las vistas completa/ventana están en
`.runtime/paso06/`, fuera del inventario publicable. El renderizador local
interpreta el subconjunto usado de GFM; conserva Mermaid como código.
Esto no demuestra publicación ni renderizado efectivo en GitHub.

## H. Inventario publicable

[INVENTARIO-PUBLICACION.txt](INVENTARIO-PUBLICACION.txt) contiene cada ruta y
sus bytes exactos; incluye el propio inventario y la verificación definitiva.
La consolidación resuelve el tamaño hasta estabilizarlo y lo compara contra
los archivos reales. Se incluyen las 65 capturas, fuentes, configuración,
scripts y evidencias publicables del Lab 15 exclusivamente.

Se excluyen `.runtime/`, `target/`, IDE, dependencias locales, binarios,
perfiles de navegador, credenciales, SQLite operativa y TSDB. El escaneo
publicable no muestra valores secretos. No se prepara el staging ni se
copia contenido a otro repositorio en esta fase.

## I. Estado final de los servicios

La comprobación final identifica nueve procesos únicos con binarios/JAR
aprobados, listeners limitados a localhost y salud correcta. Eureka conserva
cinco aplicaciones UP; Prometheus presenta siete targets UP, cero DOWN y
sin errores de scrape. Grafana y datasource están saludables y el dashboard
provisionado mantiene 18 paneles y refresco de 5s. MariaDB sigue activa.
Los PID y fechas actuales están en `VERIFICACION-PASO06.json`; las pruebas
funcionales anteriores no se presentan como ejecutadas nuevamente.

## J. Integridad y restricciones

Se comparan los hashes externos con la línea base del PASO 06, incluido Lab
14 y los otros laboratorios. Se contrastan índice Git, HEAD y estado externo,
sin alterar staging. Las cuatro bases DEV y sus cinco tablas se leen mediante
el lector ya compilado, en sesiones READ ONLY con rollback: conteos y hashes
de estructura/datos deben coincidir con la línea base.

No se modifica `fernandez_lab14`, otros laboratorios, datos de negocio ni
config-repo. No se ejecuta `git add`, `commit`, `push`, `pull`, `reset` ni
`stash`. Los resultados válidos anteriores se conservan íntegros. Las
pruebas de integridad operativas quedan privadas en `.runtime/paso06/`.

## K. Preparación para PASO 07

Solo se marca `Completed: true` tras verificar todos los controles de cierre.
La preparación no es una publicación. El PASO 07 requiere nueva autorización;
se recomienda otra copia limpia del remoto y copiar únicamente este
inventario, sin trasladar el staging existente ni otros laboratorios.

**Se dejan los servicios funcionando. Se detiene el trabajo en PASO 06.**
