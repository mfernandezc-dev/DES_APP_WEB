# Sistema de Atención Veterinaria

Frontend académico de la Evaluación N.º 03 — Desarrollo de Aplicaciones Web.
React, Vite, JavaScript/JSX, CSS y Fetch API. Sin login, router externo, librerías de UI, mocks ni registros precargados.

## Requisitos y ejecución

- Node.js **22.12 o posterior** (también compatible con Node 24; verificado con 24.15.0).
- Los tres microservicios existentes y sus bases MySQL deben estar disponibles, usando su configuración original.

```powershell
cd C:\Users\USER\Desktop\Evaluacion_03_fernandez\frontend-veterinaria
npm install
npm run dev
```

Abrir **http://localhost:5173**. Detener con `Ctrl+C`.

El puerto es fijo: si 5173 está ocupado, Vite lo informa en lugar de cambiarlo silenciosamente. No hace falta abrir `index.html` directamente (eso no ejecuta Vite ni su proxy).

## Comunicación real con los microservicios

| Ruta relativa usada por Fetch | Destino del proxy |
| --- | --- |
| `/api/propietarios` | `http://localhost:8081/api/propietarios` |
| `/api/mascotas` | `http://localhost:8082/api/mascotas` |
| `/api/consultas` | `http://localhost:8083/api/consultas` |

El proxy conserva las rutas y funciona en desarrollo y en `npm run preview`. No requiere cambiar CORS, Java ni `application.yaml`. Si no puede conectar, devuelve HTTP 503 con un mensaje claro. «Entorno local» identifica el modo de trabajo, **no** indica que los servicios estén conectados.

Las tablas, los selectores y los totales usan únicamente las APIs. Un error no se convierte en un total cero: se muestra `—` y el motivo. El frontend no se conecta directamente a MySQL.

## Funcionalidades

- **Inicio:** totales reales de cada listado y accesos directos. Los servicios se consultan de manera independiente para que un fallo no oculte los demás.
- **Propietarios (RF01):** listar, buscar por ID, registrar, editar y eliminar con confirmación. Campos `nombre`, `apellido`, `telefono`, `correo`.
- **Mascotas (RF01/RF02):** CRUD, búsqueda por ID, filtro mediante `/propietario/{idPropietario}`, selector con nombre completo de los propietarios. Se envía `idPropietario` numérico.
- **Consultas (RF03):** CRUD, búsqueda por ID, filtro mediante `/mascota/{idMascota}`, selector con mascotas reales. `idMascota` y `costo` se envían como números. Costos en soles.
- **RF04:** validación antes del envío, mensajes bajo cada campo, límites de los DTO, correo opcional pero válido, fechas válidas, nacimiento no futuro, IDs positivos y costo no negativo (máximo 8 enteros y 2 decimales).
- Manejo de HTTP 200, 201, 204, 400, 404 y 503; también 409, 500 y 502. Lee `mensaje`, `error` y `detalles` de los manejadores de Spring Boot. No intenta interpretar JSON en una respuesta 204.
- Actualiza la tabla tras las operaciones manteniendo el filtro aplicado. «Mostrar todos» limpia búsqueda y filtro. Un registro recién creado puede quedar fuera del filtro actual.
- Formularios en la misma pantalla, navegación por fragmentos (`#propietarios`, etc.), menú adaptable y tablas con desplazamiento horizontal en pantallas pequeñas.

## Contrato revisado

Se inspeccionaron, en modo lectura, los controladores, DTO, modelos, servicios de relaciones y manejadores de excepciones de los tres proyectos Java.

| Entidad | Validaciones del DTO reflejadas en la interfaz |
| --- | --- |
| Propietario | Nombre y apellido obligatorios, máximo 100 caracteres; teléfono opcional, máximo 20; correo opcional con formato válido, máximo 100. El atributo es `correo`, no `email`. |
| Mascota | Nombre obligatorio, máximo 100; especie obligatoria, máximo 50; nacimiento obligatorio no futuro; ID de propietario obligatorio y positivo. |
| Consulta | ID de mascota obligatorio y positivo; fecha obligatoria; motivo obligatorio, máximo 255; diagnóstico obligatorio, máximo 500; costo obligatorio ≥ 0, hasta 8 enteros y 2 decimales. |

Las fechas son `LocalDate`: se envían como `YYYY-MM-DD` y se muestran sin convertirlas a UTC. No se restringen fechas futuras de consulta porque el DTO no lo hace.

Las relaciones se resuelven por ID desde los listados reales, sin modificar JPA. Si el backend conserva referencias a un propietario o mascota eliminado, se muestra su ID con «sin datos»; no se inventan nombres. Para editar se debe seleccionar una relación existente.

## Archivos principales

```text
public/favicon.svg
src/
  components/     Sidebar, Navbar, Layout, ConfirmDialog, CrudPage, EntityForm, Notice, Icon
  pages/          Dashboard y páginas/formularios de propietarios, mascotas y consultas
  services/       api.js y un servicio Fetch por microservicio
  styles/         global.css, layout.css, tables.css, forms.css
  utils/          validaciones, conversión de payloads y formato
  App.jsx
  main.jsx
scripts/check-api.js    Comprobación real y de solo lectura
scripts/check-browser.js  Comprobación opcional de interfaz con Edge
tests/validation.test.js
vite.config.js
```

`CrudPage` y `EntityForm` reúnen el comportamiento compartido para no duplicar el CRUD; cada módulo conserva su formulario y contrato. React y React DOM son las únicas dependencias de ejecución. La caché de npm queda dentro de esta carpeta.

## Comprobaciones locales

```powershell
npm test
npm run build
npm run preview
```

La vista previa de la compilación está en **http://localhost:4173**. Es una comprobación local, no un servidor de producción. Para un despliegue real se necesitaría configurar un proxy equivalente en el servidor web; no forma parte de esta evaluación.

Pruebas unitarias con el ejecutor incluido en Node: entradas de validación, límites, fechas, IDs, decimales, payloads numéricos y presentación de moneda. No usan respuestas simuladas, no envían formularios y no crean registros.

Con los servicios encendidos se pueden comprobar listados, atributos, búsquedas, filtros y errores 404 **sin escribir en MySQL**:

```powershell
npm run check:api
# Con Vite encendido, también comprobar el proxy:
npm run check:api -- http://localhost:5173
```

El script solo hace GET. Una conexión fallida devuelve código de salida 1 e informa «no verificado»; un listado vacío no impide la comprobación, pero deja pendiente buscar y filtrar registros existentes.

### Repetir la comprobación de navegador (opcional)

Con Microsoft Edge instalado y Vite ejecutándose, se puede repetir el smoke test usado en la entrega sin añadir dependencias permanentes:

```powershell
npm exec --yes --package=playwright -- playwright --version
npm run check:browser
```

Playwright se guarda únicamente en la caché local, no en `dependencies`. Se utiliza Edge ya instalado; no se descargan navegadores. El script revisa navegación, formularios inválidos y adaptación a 390/320 px, y guarda capturas y un resumen en `tests/artifacts/` (ignorado por Git). Como protección adicional bloquea cualquier intento de escritura: no prueba el guardado real ni simula respuestas de las APIs. Las comprobaciones GET siguen usando los servicios reales y su disponibilidad actual.

## Prueba manual del CRUD

Usar registros autorizados por el responsable del proyecto. **No se han creado registros de prueba automáticamente.**

1. Encender los tres servicios como se hacía al utilizar Postman y comprobar que MySQL esté accesible.
2. Abrir Inicio y contrastar los tres totales con los listados de las APIs.
3. En Propietarios, buscar un ID existente y uno inexistente; probar «Mostrar todos».
4. Abrir «Nuevo propietario»: comprobar nombre/apellido vacíos, correo inválido y límites. Registrar solo si se desea modificar la base; verificar que aparece en la tabla, editarlo y confirmar la actualización.
5. En Mascotas, comprobar los nombres de los propietarios en el selector; rechazar nacimiento futuro y datos vacíos. Registrar y editar con un propietario existente; filtrar por propietario y buscar por ID.
6. En Consultas, comprobar el selector de mascotas; rechazar datos vacíos, costo negativo, más de dos decimales o más de ocho enteros. Registrar y editar una consulta; verificar costo en S/, filtro y búsqueda.
7. Cancelar una eliminación y comprobar que el registro permanece. Confirmar solo eliminaciones autorizadas, empezando por consultas, luego mascotas y finalmente propietarios para no dejar referencias sin datos.
8. Para un HTTP 400 de Spring, comprobar que sus `detalles` aparecen bajo los campos. La interfaz bloquea los errores de entrada comunes antes del envío; la validación del servidor sigue siendo la autoridad.
9. Verificar errores 404 y, si un servicio ya está apagado, 503. No debe aparecer un éxito para una petición fallida. Si falla solo la recarga después de una escritura confirmada, se informa por separado y se ofrece actualizar.

## Alcance y restricciones

Todo el trabajo está en `frontend-veterinaria`. No se modifican los microservicios, endpoints, bases de datos, configuración Java ni relaciones JPA. No se incluyen Eureka, Gateway, autenticación, pagos ni módulos extra. No se ejecutan commits, push ni creación de ramas.

Los resultados concretos de verificación y sus limitaciones están en [VERIFICACION.md](VERIFICACION.md).
