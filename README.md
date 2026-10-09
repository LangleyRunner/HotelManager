<h1 align="center">HotelManager</h1>

<p align="center">Aplicación web de gestión hotelera con autenticación y persistencia en PostgreSQL.</p>

![Portada de HotelManager con un edificio ilustrado y las tecnologías principales](docs/hotelmanager-banner.svg)

<p align="center">
  <img alt="Java 25" src="https://img.shields.io/badge/Java-25-e8af52">
  <img alt="Spring Boot 4.1.1" src="https://img.shields.io/badge/Spring_Boot-4.1.1-6DB33F">
  <img alt="PostgreSQL 18" src="https://img.shields.io/badge/PostgreSQL-18-4169E1">
  <img alt="Estado: funcional en entorno local" src="https://img.shields.io/badge/Estado-Funcional_local-146d83">
</p>

## Índice

- [Descripción](#descripción)
- [Estado del proyecto](#estado-del-proyecto)
- [Funcionalidades](#funcionalidades)
- [Demostración](#demostración)
- [Tecnologías](#tecnologías)
- [Arquitectura MVC](#arquitectura-mvc)
- [Instalación y ejecución](#instalación-y-ejecución)
- [API y seguridad](#api-y-seguridad)
- [Pruebas](#pruebas)
- [Publicación en GitHub](#publicación-en-github)
- [Ayuda](#ayuda)
- [Autoría y contribuciones](#autoría-y-contribuciones)
- [Licencia](#licencia)

## Descripción

HotelManager permite administrar las habitaciones de un hotel desde una interfaz web. El administrador puede registrar habitaciones, consultar sus datos, actualizar precios y disponibilidad y eliminar registros.

El proyecto universitario aplica la arquitectura **MVC**, las operaciones **CRUD**, la autenticación mediante **Spring Security** y la persistencia con **PostgreSQL**.

## Estado del proyecto

**Funcional en el entorno local verificado el 8 de octubre de 2026.**

- Backend compilado y 3 pruebas de integración automatizadas aprobadas.
- Login, CRUD, CSRF, acceso anónimo bloqueado y logout comprobados contra PostgreSQL.
- Habitación 101 comprobada después de reiniciar el backend mediante el lanzador de verificación.
- Interfaz temporal HTML/CSS/JavaScript disponible. El proyecto Sencha Ext JS se conserva; su instalación falla con `spawn EINVAL` durante la activación.
- Publicación en GitHub y grabación del video pendientes. No hay despliegue público.

Consulta la evidencia y sus límites en [RESULTADOS-PRUEBAS.md](RESULTADOS-PRUEBAS.md). Las insignias de esta portada describen el proyecto; no representan una ejecución de CI en GitHub.

## Funcionalidades

| Función | Descripción |
| --- | --- |
| Inicio de sesión | Acceso del administrador mediante usuario y contraseña. |
| Dashboard | Indicadores de habitaciones totales, disponibles y ocupadas. |
| Crear y consultar | Formulario de registro, listado y consulta individual. |
| Editar | Actualización de número, tipo, precio y disponibilidad. |
| Eliminar | Borrado con confirmación del usuario. |
| Persistencia | Almacenamiento de usuarios y habitaciones en PostgreSQL. |
| Seguridad | Rol ADMIN, contraseñas BCrypt, sesiones y protección CSRF. |
| Cierre de sesión | Invalidación de la sesión mediante POST protegido. |

Cada habitación contiene `id`, `numero`, `tipo`, `precio` y `disponible`. El número es único y el precio se almacena con `BigDecimal`.

## Demostración

1. Abrir [http://localhost:8081/login.html](http://localhost:8081/login.html).
2. Iniciar sesión con el usuario `admin` y la contraseña configurada.
3. Revisar el dashboard y la tabla de habitaciones.
4. Crear una habitación con un número libre; editar su precio o disponibilidad.
5. Eliminar ese registro temporal y cerrar sesión.
6. Abrir `/api/habitaciones` sin sesión para mostrar el bloqueo de acceso.

La URL es local: solo funciona en el equipo donde esté iniciado el backend. El guion de presentación de máximo 3 minutos está en [GUION-DEMO.md](GUION-DEMO.md). No se incluye un enlace de video porque aún no se ha publicado.

## Tecnologías

| Área | Tecnologías |
| --- | --- |
| Backend | Java 25, Spring Boot 4.1.1, Maven Wrapper 3.9.16 |
| Seguridad | Spring Security, BCrypt, sesiones HTTP y CSRF |
| Persistencia | Spring Data JPA, Hibernate y PostgreSQL 18 |
| Entorno de base de datos | Docker Desktop; contenedor verificado `hotelmanager-postgres` |
| Interfaz activa | HTML, CSS y JavaScript con Fetch API |
| Frontend conservado | Sencha Ext JS 8; Node.js y npm para su instalación |
| Pruebas automatizadas | JUnit y H2 aislado, con servidor HTTP real |

H2 se utiliza exclusivamente en pruebas automatizadas. La aplicación ejecutada utiliza PostgreSQL.

## Arquitectura MVC

| Capa | Responsabilidad | Archivos principales |
| --- | --- | --- |
| Modelo | Entidades y acceso a los datos. | `Habitacion`, `Usuario` y repositorios JPA |
| Vista | Pantallas de login, dashboard y formularios. | `login.html` e `index.html` |
| Controlador | Endpoints y respuestas HTTP. | `HabitacionController` y `SessionController` |
| Servicio | Lógica de las operaciones de habitaciones. | `HabitacionService` |
| Seguridad | Autorización, autenticación y creación inicial de admin. | `SecurityConfig`, `CustomUserDetailsService`, `AdminInitializer` |

La vista llama a los controladores; estos usan el servicio y los repositorios para consultar PostgreSQL.

```text
HotelManager/
├── backend/
│   ├── src/main/java/com/hotelmanager/backend/
│   │   ├── controller/
│   │   ├── model/
│   │   ├── repository/
│   │   ├── service/
│   │   └── security/
│   ├── src/main/resources/static/
│   ├── src/test/
│   └── pom.xml
├── frontend/hotel-manager-app/
├── docs/hotelmanager-banner.svg
├── Maven.ps1
├── Start-HotelManager.ps1
└── README.md
```

## Instalación y ejecución

### Requisitos

- Java 25.
- PowerShell para los lanzadores incluidos.
- PostgreSQL disponible y una base `hotelmanager_db` con el rol `hotelmanager`, o un destino configurado mediante variables de entorno.
- Docker Desktop si se usa la base del contenedor. En el equipo verificado, PostgreSQL publica `127.0.0.1:5432`.

La interfaz activa no requiere instalar Node.js, npm ni Ext JS.

### Obtener el código

Desde GitHub, descargar el ZIP del repositorio o clonarlo cuando se haya publicado:

```powershell
git clone https://github.com/TU_USUARIO/HotelManager.git
cd HotelManager
```

Reemplazar `TU_USUARIO` por el propietario real del repositorio. Esta dirección es un ejemplo, no un enlace publicado.

### Compilar

Desde la raíz del proyecto:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Maven.ps1 verify
```

El lanzador usa Maven del wrapper y la caché del usuario. La compilación genera `backend/target/backend-0.0.1-SNAPSHOT.jar`.

### Iniciar

Con PostgreSQL activo, ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-HotelManager.ps1 -Port 8081
```

El script solicita las contraseñas de forma oculta y las pasa mediante variables de entorno. No las escribe en archivos.

| Variable | Uso |
| --- | --- |
| `DB_URL` | URL JDBC; por defecto `jdbc:postgresql://localhost:5432/hotelmanager_db`. |
| `DB_USER` | Usuario PostgreSQL; por defecto `hotelmanager`. |
| `DB_PASSWORD` | Contraseña real del rol PostgreSQL. |
| `ADMIN_PASSWORD` | Crea el administrador si falta; un admin existente conserva su contraseña. |
| `SERVER_PORT` | Puerto HTTP; el lanzador lo configura con `-Port`. |

Abrir **[http://localhost:8081/login.html](http://localhost:8081/login.html)** y usar `admin` con su contraseña configurada. Para detener una ejecución en primer plano, presionar `Ctrl+C`.

En el equipo de desarrollo, 8080 responde con un servidor anterior. Se usa 8081 para esta versión; si está ocupado, elegir un puerto libre y ajustar la URL.

## API y seguridad

| Método | Endpoint | Operación |
| --- | --- | --- |
| GET | `/api/habitaciones` | Listar habitaciones |
| GET | `/api/habitaciones/{id}` | Consultar una habitación |
| POST | `/api/habitaciones` | Crear |
| PUT | `/api/habitaciones/{id}` | Editar |
| DELETE | `/api/habitaciones/{id}` | Eliminar |

Todos los endpoints de habitaciones requieren el rol **ADMIN**. Las contraseñas se almacenan como hashes **BCrypt**; no se incluyen credenciales en este README.

`GET /api/csrf` entrega el token vinculado a la sesión. Login, logout y mutaciones deben enviar ese token; la vista obtiene uno nuevo después de iniciar sesión.

Respuestas principales: `201` al crear, `204` al eliminar, `400` para datos inválidos, `401` sin autenticación, `403` ante una mutación sin CSRF, `404` para un registro inexistente y `409` para un número duplicado.

## Pruebas

### Automatizadas

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Maven.ps1 verify
```

Resultado comprobado: **3 pruebas, 0 fallos, 0 errores**. Cubren login, BCrypt, CRUD, validación, duplicados, CSRF y logout con H2 aislado y un puerto aleatorio.

### PostgreSQL y reinicio

Con un puerto libre:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-HotelManager.ps1 -Verify -Port 8081
```

Esta verificación crea 101 solo si falta, comprueba edición y restaura sus datos; elimina un registro de prueba separado, reinicia su propio backend y consulta 101 otra vez. Si pasa, genera `VERIFICACION-POSTGRESQL.txt` y deja el backend activo mostrando su PID.

Las pruebas automatizadas con H2 y la verificación PostgreSQL son comprobaciones distintas. La revisión visual de clics en navegador no se ha completado.

## Publicación en GitHub

Crear un repositorio vacío y ejecutar desde la raíz:

```powershell
git init
git add .
git status
git diff --cached
git commit -m "Documentar HotelManager y completar gestion de habitaciones"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/HotelManager.git
git push -u origin main
```

Reemplazar la URL por la del repositorio real. Revisar los archivos preparados antes del commit. `.gitignore` excluye secretos, `.npmrc`, logs, cachés, `target` y `node_modules`. No subir archivos de datos o volúmenes PostgreSQL.

## Ayuda

| Problema | Acción |
| --- | --- |
| `password authentication failed` | Verificar la contraseña de PostgreSQL; no es necesariamente la misma del login web. Para el contenedor de este proyecto, usar `Recover-DockerDatabasePassword.ps1`, que comprueba el acceso local antes de cambiarla. |
| Login rechazado | Usar la contraseña del admin existente. Cambiar `ADMIN_PASSWORD` no restablece un usuario ya creado. |
| Puerto ocupado | Elegir otro con `-Port`; no detener procesos ajenos. |
| Archivos de `target` bloqueados | Detener la ejecución propia de HotelManager antes de limpiar. |
| Fallo de Ext JS | Consultar [DIAGNOSTICO-EXTJS.md](frontend/DIAGNOSTICO-EXTJS.md) y usar la interfaz temporal. |

Más información: [resultados de pruebas](RESULTADOS-PRUEBAS.md), [resumen universitario](RESUMEN-UNIVERSITARIO.md) y [guion de demostración](GUION-DEMO.md).

Cuando se publique el repositorio, usar su sección **Issues** para reportar errores, indicando el comando, el puerto y el mensaje recibido, sin contraseñas.

## Autoría y contribuciones

**Autor del proyecto:** LangleyRunner.

No se han identificado colaboradores adicionales. Para proponer una mejora, abrir un Issue o un Pull Request cuando el repositorio esté publicado, explicando el cambio y cómo se comprobó.

## Licencia

No se ha añadido un archivo `LICENSE` para el código propio del proyecto. La licencia queda pendiente de decisión del autor.

Las dependencias mantienen sus licencias respectivas. Sencha Ext JS requiere respetar sus condiciones de licencia y activación; la alternativa temporal no modifica ni omite esa activación.
