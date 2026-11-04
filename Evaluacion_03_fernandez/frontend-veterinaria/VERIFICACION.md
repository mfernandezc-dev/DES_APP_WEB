# Resultado de verificación

## Comprobaciones ejecutadas

| Comprobación | Resultado real | Qué demuestra |
| --- | --- | --- |
| Instalación de dependencias | Correcta; Node 24.15.0 y npm 11.12.1 | React/React DOM y Vite/plugin de React disponibles. |
| `npm run build` | Correcto, código de salida 0 | JSX, CSS, imports y configuración compilan; se genera `dist/`. |
| `npm audit --audit-level=moderate` | 0 vulnerabilidades reportadas | Sin avisos de seguridad conocidos en las dependencias instaladas al ejecutar la auditoría. |
| `npm test` | **16 pruebas correctas, 0 fallos** | Validaciones locales, límites de los DTO, fechas, IDs, costo, payload numérico y moneda. No demuestra persistencia. |
| `npm run dev` | Inicio correcto en `http://localhost:5173` | Servidor Vite accesible y aplicación renderizada en Edge. |
| `npm run check:browser` | **9 comprobaciones correctas** | Inicio, navegación, formularios de los tres módulos, errores locales por campos vacíos/correo inválido/ID cero, atributos del costo y fecha y adaptación móvil. |
| Navegador Edge, escritorio | 1440 × 1000, sin errores JavaScript | Secciones y formulario de propietario renderizados. |
| Navegador Edge, móvil | 390 y 320 px, sin desbordamiento de página en los cuatro módulos | Menú y contenido adaptables; las tablas usan contenedor desplazable. |
| Peticiones a 8081, 8082 y 8083 | **ECONNREFUSED en los tres** | Los microservicios no estaban accesibles durante la verificación. |
| Peticiones a `/api/propietarios`, `/api/mascotas` y `/api/consultas` mediante Vite | **HTTP 503 con mensaje legible** | El proxy identifica la indisponibilidad y la interfaz informa el error, sin inventar registros o mostrar totales cero. |

Las nueve comprobaciones del navegador son grupos de aserciones, no nueve operaciones CRUD. Las 16 pruebas de Node usan entradas de funciones puras; no son respuestas simuladas ni datos cargados en tablas.

## Evidencias locales

En `tests/artifacts/` se guardaron:

- `inicio-desktop.png`
- `inicio-mobile.png`
- `propietario-validacion.png`
- `browser-result.json`: comprobaciones, errores JavaScript (ninguno), intentos de escritura bloqueados (ninguno) y códigos HTTP realmente observados (503).

La carpeta de artefactos contiene también el perfil temporal del navegador. Está excluida de Git y no es necesaria para ejecutar el frontend.

## Requisitos implementados y alcance probado

| Requisito | Implementación | Pendiente de verificar contra MySQL |
| --- | --- | --- |
| RF01 — Propietarios | CRUD, búsqueda por ID, confirmación, validaciones y recarga de tabla. | Lectura de registros existentes, POST, PUT, DELETE y actualización real posterior. |
| RF01/RF02 — Mascotas | CRUD, selector de propietarios reales, ID numérico, nacimiento no futuro y filtro por propietario. | Carga de propietarios, persistencia de la relación, búsquedas, filtro y operaciones reales. |
| RF03 — Consultas | CRUD, selector de mascotas, filtro, fecha, motivo, diagnóstico y costo decimal en soles. | Carga de mascotas, persistencia, operaciones reales, búsqueda y filtro. |
| RF04 — Validaciones | Validación cliente y lectura de `mensaje`, `error`, `detalles`; distinción de estados HTTP. | HTTP 400 con `detalles`, 404 y 503 originados por Spring y respuestas de éxito 200/201/204. La indisponibilidad **del proxy** sí se probó en navegador. |
| Inicio | Obtención independiente de totales desde los tres listados. | Valores numéricos reales; se verificó únicamente el estado de indisponibilidad. |

## Problemas encontrados y soluciones

1. **Servicios apagados o no accesibles:** no se arrancaron ni cambiaron para evitar efectos sobre las bases. Se documenta la limitación y se proporciona `npm run check:api` de solo lectura para repetir la conexión.
2. **Posibles errores CORS entre puertos:** se usa el proxy de Vite, sin tocar Java ni `application.yaml`.
3. **Servicio inaccesible a través del proxy:** se configura una respuesta JSON 503 clara en lugar de un 500 sin explicación.
4. **Diferencias entre nombres generales y contrato real:** se usa `correo`; se respetan longitudes de cada DTO y precisión del costo. No se impone fecha pasada a las consultas porque su DTO no la exige.
5. **Respuesta DELETE vacía:** se trata HTTP 204 sin ejecutar `response.json()`.
6. **Fallos tras una escritura confirmada:** el mensaje de éxito corresponde solo a la mutación confirmada; si falla la recarga, aparece por separado y no se muestran datos antiguos como si estuvieran actualizados.

## Restricciones respetadas

- Archivos de implementación y herramientas locales únicamente en `frontend-veterinaria`.
- Sin modificaciones de controladores, DTO, servicios Java, bases de datos o configuración del backend.
- Sin POST, PUT o DELETE ejecutados durante las pruebas; ningún registro de prueba creado automáticamente.
- Sin tablas simuladas, datos precargados, mocks, autenticación, Gateway, Eureka ni módulos extra.
- Sin creación de ramas, commits o push.

**Conclusión:** frontend compilado y listo para ejecución y pruebas manuales. No se afirma que el CRUD sobre MySQL esté verificado: requiere encender los tres microservicios y probar operaciones autorizadas siguiendo `README.md`.
