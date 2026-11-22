# Inventario de cambios de esta continuación

## Código/configuración modificados

- `producto-service/pom.xml`: procesador de anotaciones Lombok explícito, sin cambiar versiones.
- `producto-service/src/main/java/com/tecsup/services/CategoriaCircuitService.java`: Retry y Bulkhead junto al circuito existente; 404 no se presenta como indisponibilidad.
- `pedido-service/src/main/java/com/tecsup/services/ProductoCircuitService.java`: Bulkhead junto al circuito existente y propagación de 404.
- `pedido-service/src/main/java/com/tecsup/services/PedidoService.java`: Retry en las lecturas de cliente y listado detallado adicional; las validaciones de guardado siguen usando los clientes directos, sin fallback.
- `pedido-service/src/main/java/com/tecsup/controller/PedidoController.java`: opción `detallado=true`; el método/listado anterior se conserva.
- `producto-service/src/main/resources/application.yml`: Retry/Bulkhead, composición AOP, timeouts y Actuator DEV.
- `pedido-service/src/main/resources/application.yml`: Retry/Bulkhead, timeouts y Actuator DEV.
- `cliente-service/src/main/resources/application.yml`: timeout y Actuator DEV.
- `categoria-service/src/main/resources/application-dev.yml` y `application-prod.yml`: se conservan los archivos, quitando duplicados ya centralizados.
- `producto-service/src/main/resources/application-dev.yml`: se quitan duplicados ya centralizados.
- `pedido-service/src/main/resources/application-dev.yml`: ambiente `desarrollo`.
- `README.md`: documentación académica de Lab 14; el contenido heredado se conserva en un apéndice desplegable.

## Archivos creados

- `.gitignore`: exclusión local de IDE, targets, secretos de entorno y datos operativos.
- `categoria-service/src/main/java/com/tecsup/config/LabDelayFilter.java`.
- `cliente-service/src/main/java/com/tecsup/config/LabDelayFilter.java`.
- `producto-service/src/main/java/com/tecsup/config/LabDelayFilter.java`.
- `producto-service/src/main/java/com/tecsup/config/LabFeignConfig.java`.
- `pedido-service/src/main/java/com/tecsup/config/LabFeignConfig.java`.
- `pedido-service/src/main/java/com/tecsup/services/ClienteRetryService.java`.
- `pedido-service/src/main/java/com/tecsup/exception/FeignExceptionHandler.java`: referencias inexistentes devuelven 404, no un 500 sin control; fallo de validación remota devuelve 503 sin guardar.
- `pedido-service/src/test/java/com/tecsup/services/PedidoServiceValidationTests.java`.
- `pedido-service/src/test/java/com/tecsup/exception/FeignExceptionHandlerTests.java`.
- `scripts/Servicios-Lab.ps1`: control de procesos identificados del laboratorio.
- `scripts/Probar-Resiliencia.ps1`: recorrido HTTP con aserciones y concurrencia real.
- `scripts/Probar-Validaciones.ps1`: casos negativos opcionales, comprobando previamente que no existen las referencias y que el listado permanece intacto.
- `scripts/Capturar-Evidencia.ps1`: captura real de páginas HTTP locales con navegador headless y metadatos de origen.
- `scripts/Finalizar-Pruebas.ps1`: capturas reales del circuito, validaciones HTTP y salida del perfil LAB.
- `scripts/Generar-Informe.py` y `evidencias/informe.html`: visualización reproducible de las respuestas/consolas reales, expresamente diferenciada de Postman o de una captura en vivo del backend.
- `scripts/postman-pedido.js`: aserciones reutilizables sobre los datos existentes del pedido 1.
- `scripts/Probar-Circuitos-Existentes.ps1`: regresión de caída, OPEN y recuperación de los dos circuitos previamente implementados.
- `evidencias/`: diagnóstico, instrucciones, respuestas JSON, resultados Maven, capturas reales y resúmenes. Consultar el listado físico para todos los archivos generados por escenario.

## Conservación y publicación

- Se conservaron nombres de clases/paquetes, CRUD y validaciones existentes; no se recrearon servicios.
- `PedidoClient` y `PedidoCircuitService` de Cliente ya estaban implementados por el estudiante y no se modificaron en esta continuación.
- Config Server, Eureka y Gateway conservan su implementación y versiones.
- `config-repo` remoto permanece sin cambios; sus circuitos y perfiles existentes se reutilizan. No fue necesario escribir en ese repositorio para los patrones locales de la guía.
- El índice Git preexistente se mantuvo: no se ejecutó `git add`, commit, pull ni push. Otras carpetas del repositorio no se modificaron.
