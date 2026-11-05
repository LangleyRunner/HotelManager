# HotelManager

HotelManager es un proyecto universitario para administrar las habitaciones de un hotel. Permite registrar pisos y habitaciones, modificar sus datos y consultar su capacidad, tarifa y estado.

Esta administración servirá como base para desarrollar la asignación de habitaciones a huéspedes individuales y grupos.

## Qué incluye

- Inicio y cierre de sesión del administrador.
- Crear, consultar, editar y eliminar pisos y habitaciones.
- Seleccionar el piso desde una lista cargada de la base de datos.
- Registrar capacidad, tipo, tarifa y estado operativo.
- Consultar indicadores de habitaciones y plazas configuradas.
- Guardar la información en PostgreSQL.

## Core del proyecto

La propuesta es buscar una distribución de habitaciones según la cantidad de huéspedes, las fechas y preferencias como quedarse en el mismo piso. La capacidad, el piso, la tarifa y el estado de cada habitación alimentarán ese proceso.

Por ahora está desarrollada la administración. La asignación automática, las reservas por fechas y el registro de entrada y salida siguen pendientes.

## Tecnologías

Java 25, Spring Boot 4.1.1, Spring Security, Spring Data JPA, Hibernate, PostgreSQL, Maven, HTML, CSS, JavaScript y Docker.

La carpeta `frontend` conserva el proyecto inicial de Ext JS. La interfaz actual usa HTML, CSS y JavaScript debido a un problema durante su activación.

## Organización del código

El proyecto sigue MVC. Las entidades representan los datos, las páginas muestran la interfaz y los controladores reciben las solicitudes.

- `model`: entidades Habitación, Piso y Usuario.
- `controller`: endpoints y validación de las solicitudes.
- `service`: reglas antes de consultar o modificar datos.
- `repository`: acceso a PostgreSQL.
- `security`: login, permisos y CSRF.

La interfaz está en `backend/src/main/resources/static`.

## Validaciones

La capacidad es un dato crítico para el core: una capacidad incorrecta podría generar una distribución sin espacio para todos los huéspedes.

El backend valida que la capacidad sea un entero mayor que cero, incluso si se envía una solicitud sin usar el formulario. También comprueba:

- Tarifa positiva, con hasta dos decimales.
- Número de habitación positivo y único.
- Existencia del piso seleccionado.
- Estado operativo válido.
- Que un piso con habitaciones no se pueda eliminar.

Las operaciones requieren el rol `ADMIN`. Las contraseñas se guardan con BCrypt y las modificaciones requieren un token CSRF.

## Cómo ejecutarlo

Necesitas Java 25, PowerShell y PostgreSQL en ejecución.

```powershell
git clone https://github.com/LangleyRunner/HotelManager.git
cd HotelManager
powershell -NoProfile -ExecutionPolicy Bypass -File .\Maven.ps1 verify
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-HotelManager.ps1 -Port 8081
```

El lanzador pide las contraseñas de PostgreSQL y del administrador. Después abre [http://localhost:8081/login.html](http://localhost:8081/login.html).

El usuario es `admin`, con su contraseña configurada. Primero registra un piso y luego una habitación. Para detener la aplicación en primer plano, presiona `Ctrl+C`.

La configuración local usa la base `hotelmanager_db`, el usuario `hotelmanager` y el puerto `5432`. Se puede cambiar mediante `DB_URL`, `DB_USER` y `DB_PASSWORD`, o definir `DB_HOST`, `DB_PORT` y `DB_NAME` por separado.

`ADMIN_PASSWORD` crea el administrador si falta; no cambia la contraseña de un usuario existente. No hay credenciales incluidas en el repositorio.

## Registros anteriores

Las habitaciones anteriores se conservan. Si les falta capacidad, piso o estado operativo, aparecen como pendientes de configurar. Estos datos se completan desde **Editar**.

## Pruebas

El 5 de noviembre de 2026 se ejecutaron 7 pruebas de integración sin fallos. Se comprobaron autenticación, permisos, CSRF, CRUD, validación del backend y relaciones entre tablas.

También se comprobó la persistencia en PostgreSQL después de reiniciar el backend, conservando la habitación 101. La interfaz se verificó con pruebas DOM conectadas a la API real; no equivale a una revisión manual completa del navegador.

Para repetir la verificación de PostgreSQL, usa un puerto libre:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-HotelManager.ps1 -Verify -Port 8081
```

## Despliegue

El `Dockerfile` y `render.yaml` preparan el despliegue en Render con una base PostgreSQL separada. La configuración YAML se validó contra el esquema oficial, pero la construcción de la imagen no se comprobó desde este entorno.

Para publicarlo:

1. Crear una cuenta en Render y conectar este repositorio.
2. Crear un **Blueprint** usando `render.yaml`.
3. Introducir `ADMIN_PASSWORD` cuando Render lo solicite.
4. Revisar los planes y confirmar la creación del servicio y la base.
5. Cuando termine, abrir la URL HTTPS asignada y entrar en `/login.html`.

Las credenciales de la base se obtienen desde Render; el backend usa su variable `PORT`. La ruta `/health` comprueba la conexión sin mostrar credenciales.

El despliegue público sigue pendiente. Según la [documentación de Render](https://render.com/docs/free), la base gratuita caduca a los 30 días. La base local no se copia automáticamente al nuevo servicio.

## Demostración

El guion está en [GUION-DEMO.md](GUION-DEMO.md). Antes de grabar la entrega final hay que completar el despliegue y mostrar la dirección pública, tal como pide la consigna.

## Autor

[LangleyRunner](https://github.com/LangleyRunner)

El proyecto aún no tiene una licencia propia definida.
