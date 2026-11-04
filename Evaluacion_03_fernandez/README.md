# Sistema de Atención Veterinaria

Proyecto académico de la **Evaluación N.º 03** del curso **Desarrollo de Aplicaciones Web**.

El sistema permite administrar propietarios, mascotas y consultas veterinarias mediante una interfaz web conectada a tres microservicios Spring Boot con persistencia en MySQL.

## Trabajo realizado

Se implementó el frontend en `frontend-veterinaria`, utilizando **React, Vite, JavaScript/JSX, CSS y Fetch API**. Se revisaron los controladores, DTO y manejadores de errores del backend para respetar los endpoints, nombres de atributos y validaciones existentes.

Los tres microservicios ya estaban desarrollados y se conservaron sin modificaciones. No se cambiaron sus bases de datos ni sus archivos `application.yaml`.

### Funcionalidades

| Módulo | Funcionalidades implementadas |
| --- | --- |
| Inicio | Totales obtenidos de las APIs y accesos directos a cada módulo. |
| Propietarios — RF01 | Listar, buscar por ID, registrar, editar y eliminar con confirmación. |
| Mascotas — RF01/RF02 | CRUD, búsqueda por ID, filtro por propietario y selección de un propietario registrado. |
| Consultas — RF03 | CRUD, búsqueda por ID, filtro por mascota y selección de una mascota registrada. Costos decimales mostrados en soles (S/). |
| Validaciones — RF04 | Campos obligatorios, correo válido, límites de longitud, nacimiento no futuro, IDs positivos y costo no negativo con hasta 8 enteros y 2 decimales. |

La interfaz incluye menú lateral, diseño adaptable, mensajes de éxito/error y actualización de las tablas después de las operaciones. Los formularios muestran los errores bajo cada campo e interpretan los mensajes enviados por Spring Boot.

**No se utilizan datos simulados para llenar las tablas.** Si una API no está disponible, se informa el error; no se inventan registros ni totales.

## Estructura del proyecto

```text
Evaluacion_03_fernandez/
├── propietario-service/       Microservicio de propietarios
├── mascota-service/           Microservicio de mascotas
├── consulta-service/          Microservicio de consultas
├── frontend-veterinaria/      Aplicación React con Vite
│   ├── public/
│   ├── src/
│   │   ├── components/        Navegación, estructura y componentes compartidos
│   │   ├── pages/             Dashboard, pantallas CRUD y formularios
│   │   ├── services/          Comunicación HTTP mediante Fetch
│   │   ├── styles/            Estilos CSS
│   │   └── utils/             Validaciones y formatos
│   ├── scripts/               Comprobaciones de API e interfaz
│   ├── tests/                 Pruebas locales
│   ├── vite.config.js         Configuración del proxy
│   ├── README.md              Documentación detallada del frontend
│   └── VERIFICACION.md        Resultados de las pruebas y limitaciones
└── README.md
```

## Requisitos para ejecutar

- **JDK 17**, versión declarada en los `pom.xml`, con `JAVA_HOME` configurado.
- **MySQL** disponible en `localhost:3306`, con las bases y credenciales que ya utiliza el backend:
  - `bd_propietario`
  - `bd_mascota`
  - `bd_consulta`
- **Node.js 22.12 o posterior** y npm. El frontend se verificó con Node.js 24.15.0.
- Conexión a Internet para descargar dependencias en la primera ejecución.

Cada microservicio incluye **Maven Wrapper**, por lo que no es necesario instalar Maven por separado. No se incluyen instrucciones de recreación o limpieza de las bases de datos.

## Ejecución en Windows / PowerShell

### 1. Iniciar MySQL

Iniciar el servicio MySQL utilizado en el proyecto y comprobar que las tres bases existentes estén accesibles con la configuración original de los microservicios.

### 2. Iniciar los microservicios

Abrir **tres terminales independientes** y mantenerlas abiertas. Se recomienda iniciar primero Propietario, luego Mascota y finalmente Consulta, esperando a que cada servicio termine de arrancar.

**Terminal 1 — Propietario:**

```powershell
cd C:\Users\USER\Desktop\Evaluacion_03_fernandez\propietario-service
.\mvnw.cmd spring-boot:run
```

**Terminal 2 — Mascota:**

```powershell
cd C:\Users\USER\Desktop\Evaluacion_03_fernandez\mascota-service
.\mvnw.cmd spring-boot:run
```

**Terminal 3 — Consulta:**

```powershell
cd C:\Users\USER\Desktop\Evaluacion_03_fernandez\consulta-service
.\mvnw.cmd spring-boot:run
```

También pueden iniciarse desde el IDE ejecutando la clase principal de cada aplicación Spring Boot. Estos comandos conservan la configuración existente del backend; no se ejecutaron como parte de la documentación.

| Servicio | URL base |
| --- | --- |
| Propietario | `http://localhost:8081/api/propietarios` |
| Mascota | `http://localhost:8082/api/mascotas` |
| Consulta | `http://localhost:8083/api/consultas` |

### 3. Iniciar el frontend

Abrir una **cuarta terminal**:

```powershell
cd C:\Users\USER\Desktop\Evaluacion_03_fernandez\frontend-veterinaria
npm install
npm run dev
```

`npm install` instala las dependencias; no es necesario repetirlo en cada inicio si ya están instaladas y no cambiaron.

### 4. Abrir la aplicación

Visitar **http://localhost:5173**.

El frontend realiza solicitudes relativas a `/api/propietarios`, `/api/mascotas` y `/api/consultas`. El proxy de Vite las dirige a los puertos **8081, 8082 y 8083**, respectivamente, evitando cambiar la configuración CORS del backend.

No se incorporaron un API Gateway ni un Eureka Server en este trabajo. La comunicación del frontend utiliza directamente las rutas de los microservicios a través del proxy.

### 5. Detener el sistema

Presionar **Ctrl+C** en cada terminal para detener el frontend y los microservicios. Detener Vite no detiene automáticamente las aplicaciones Java ni MySQL.

## Comprobaciones disponibles

Ejecutar desde `frontend-veterinaria`:

```powershell
# Pruebas de validaciones locales, sin peticiones ni escrituras en MySQL
npm test

# Generar la compilación de producción en dist/
npm run build

# Comprobar APIs reales mediante GET, con los microservicios encendidos
npm run check:api

# Comprobar también el proxy, con Vite encendido
npm run check:api -- http://localhost:5173
```

Para revisar localmente la compilación generada:

```powershell
npm run preview
```

Abrir **http://localhost:4173**. La vista previa también necesita los microservicios para mostrar registros reales; no sustituye un servidor de producción.

## Resultado de la verificación del frontend

- Compilación completada correctamente.
- **16 pruebas locales aprobadas**.
- **9 comprobaciones de interfaz aprobadas** en Microsoft Edge, incluyendo adaptación a pantallas de 390 y 320 píxeles.
- Sin errores JavaScript durante esas comprobaciones.
- Auditoría de dependencias: **0 vulnerabilidades reportadas** al ejecutarla.

**Limitación importante:** durante la verificación los tres microservicios rechazaron la conexión (`ECONNREFUSED`). Se comprobó que el proxy devuelve HTTP 503 y la interfaz muestra el problema claramente, pero **no se pudo verificar el CRUD ni la carga de registros contra MySQL**. No se crearon registros de prueba automáticamente ni se ejecutaron POST, PUT o DELETE durante las pruebas.

La lectura, el registro, la edición, la eliminación, los filtros y la actualización real de tablas deben verificarse manualmente con los servicios encendidos y registros autorizados.

## Problemas frecuentes

- **HTTP 503 / servicio no disponible:** comprobar que el microservicio correspondiente terminó de iniciar en el puerto correcto.
- **Errores de conexión a MySQL:** revisar la disponibilidad de MySQL y su configuración original; el frontend no configura ni crea las bases.
- **Puerto 5173 ocupado:** detener la instancia anterior de Vite antes de volver a ejecutar `npm run dev`.
- **Totales mostrados como `—`:** la API correspondiente no pudo consultarse; no significa que existan cero registros.
- **Las tablas no muestran datos al abrir `index.html`:** utilizar la URL de Vite; no abrir el archivo directamente.

## Documentación adicional

- [Instrucciones detalladas del frontend](frontend-veterinaria/README.md).
- [Resultados de verificación y puntos pendientes](frontend-veterinaria/VERIFICACION.md).
