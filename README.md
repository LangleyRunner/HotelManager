HotelManager es un proyecto universitario para administrar las habitaciones de un hotel. Permite registrar pisos y habitaciones, modificar sus datos y consultar su capacidad, tarifa y estado.

Esta parte administrativa servirá como base para desarrollar la asignación de habitaciones a huéspedes y grupos.
Qué incluye
- Inicio y cierre de sesión.
- Registro, consulta, edición y eliminación de pisos.
- Registro, consulta, edición y eliminación de habitaciones.
- Selección del piso mediante una lista cargada desde la base de datos.
- Indicadores de habitaciones, plazas configuradas y habitaciones en mantenimiento.
- Almacenamiento de los datos en PostgreSQL.
Core del proyecto
La propuesta es que el sistema encuentre cómo distribuir a un grupo entre las habitaciones disponibles, tomando en cuenta la cantidad de personas, las fechas y preferencias como quedarse en el mismo piso.

Para eso, primero se necesita administrar correctamente la capacidad, el piso, la tarifa y el estado de cada habitación.

Por ahora está desarrollada esa administración. La asignación automática, las reservas por fechas y el registro de entrada y salida quedan como siguientes etapas.
Tecnologías utilizadas
- Java 25.
- Spring Boot 4.1.1.
- Spring Security.
- Spring Data JPA y Hibernate.
- PostgreSQL.
- Maven.
- HTML, CSS y JavaScript.
- Docker.
- Git y GitHub.
La carpeta frontend conserva el proyecto inicial de Ext JS. Como hubo un problema durante su activación, la interfaz que funciona actualmente está hecha con HTML, CSS y JavaScript.
Organización del código
El proyecto sigue MVC. Las entidades representan los datos, las páginas HTML muestran la interfaz y los controladores reciben las solicitudes.

Dentro del backend están estas carpetas:
- model: entidades de habitaciones, pisos y usuarios.
- controller: operaciones disponibles en la API.
- service: reglas para consultar y modificar los datos.
- repository: acceso a la base de datos.
- security: configuración del login y los permisos.
La interfaz se encuentra en backend/src/main/resources/static.
Validaciones
La capacidad de una habitación es importante para la futura asignación de huéspedes. Por eso se valida en el backend que sea un número entero mayor que cero, aunque se envíe la solicitud sin usar el formulario.

También se comprueba que:
- La tarifa sea positiva y tenga como máximo dos decimales.
- El número de habitación sea positivo y no esté repetido.
- El piso seleccionado exista.
- El estado operativo sea válido.
- No se elimine un piso que tenga habitaciones asignadas.
El acceso a las operaciones requiere el rol ADMIN. Las contraseñas se guardan con BCrypt y las solicitudes de modificación están protegidas con CSRF.
Cómo ejecutarlo
Necesitas Java 25, PowerShell y PostgreSQL en ejecución.

Primero clona el repositorio:
git clone https://github.com/LangleyRunner/HotelManager.git
cd HotelManager
Compila el proyecto y ejecuta las pruebas:
powershell -NoProfile -ExecutionPolicy Bypass -File .\Maven.ps1 verify
Después inicia la aplicación:
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-HotelManager.ps1 -Port 8081
El script pide la contraseña de PostgreSQL y la del administrador. Luego puedes entrar en:

http://localhost:8081/login.html

El usuario es admin, con la contraseña configurada. Para registrar una habitación, primero debes crear un piso.

Puedes detener la aplicación con Ctrl+C en la terminal.
Base de datos
La configuración local utiliza la base hotelmanager_db, el usuario hotelmanager y el puerto 5432.

Si necesitas otra configuración, puedes usar las variables DB_URL, DB_USER y DB_PASSWORD. También se pueden definir por separado DB_HOST, DB_PORT y DB_NAME.

ADMIN_PASSWORD crea el administrador si todavía no existe. No cambia la contraseña de un usuario ya registrado.
Habitaciones registradas anteriormente
Los registros anteriores se conservan. Si una habitación no tiene capacidad, piso o estado operativo, aparece como pendiente de configurar. Estos datos se completan desde Editar.
Pruebas realizadas
Se ejecutaron 7 pruebas de integración sin fallos. Se revisaron el login, los permisos, el CRUD, las validaciones y la relación entre pisos y habitaciones.

También se comprobó que los datos permanecen en PostgreSQL después de reiniciar el backend, conservando la habitación 101.

Para repetir la verificación, usa un puerto libre:
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-HotelManager.ps1 -Verify -Port 8081
Estado de la entrega
La administración funciona localmente. Están preparados el Dockerfile y la configuración de Render, pero la publicación todavía está pendiente.

## Autor

[LangleyRunner](https://github.com/LangleyRunner)

## Licencia

El proyecto todavía no tiene una licencia definida.

No se ha añadido un archivo `LICENSE` para el código propio del proyecto. La licencia queda pendiente de decisión del autor.

Las dependencias mantienen sus licencias respectivas. Sencha Ext JS requiere respetar sus condiciones de licencia y activación; la alternativa temporal no modifica ni omite esa activación.
