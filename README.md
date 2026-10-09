HotelManager

<img width="1142" height="628" alt="image" src="https://github.com/user-attachments/assets/ade7085d-449a-496a-aee3-67ec2cfca201" />


Proyecto universitario para administrar las habitaciones de un hotel. Permite iniciar sesión como administrador, registrar habitaciones, cambiar sus datos y eliminarlas. Los usuarios y las habitaciones se guardan en PostgreSQL.

## Qué se puede hacer

- Iniciar y cerrar sesión.
- Ver cuántas habitaciones hay, cuáles están disponibles y cuáles están ocupadas.
- Crear, consultar, editar y eliminar habitaciones.
- Cambiar el número, tipo, precio y disponibilidad de una habitación.

Para acceder a las operaciones hay que iniciar sesión. Las contraseñas se guardan con BCrypt y los formularios usan protección CSRF.

## Tecnologías

- Java 25 y Spring Boot 4.1.1.
- Spring Security y Spring Data JPA.
- PostgreSQL 18 y Docker.
- Maven.
- HTML, CSS y JavaScript.

El frontend original de Ext JS está en la carpeta `frontend`. Como su instalación presentó un error de activación, la versión actual usa una interfaz HTML, CSS y JavaScript servida por el backend.

## Cómo ejecutar el proyecto

Necesitas Java 25, Git, PowerShell y una base PostgreSQL configurada. En el entorno de desarrollo se usa el contenedor `hotelmanager-postgres`, con la base `hotelmanager_db` y el usuario `hotelmanager`, en el puerto 5432.

Clona el repositorio:

```powershell
git clone https://github.com/LangleyRunner/HotelManager.git
cd HotelManager
```

Con PostgreSQL en ejecución, compila el proyecto:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Maven.ps1 verify
```

Luego inicia el backend:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-HotelManager.ps1 -Port 8081
```

El script pide la contraseña de la base de datos y la del administrador. Si `admin` ya existe, debes usar su contraseña actual: introducir otra no la cambia.

Abre [http://localhost:8081/login.html](http://localhost:8081/login.html) e inicia sesión con el usuario `admin`.

Para detener el backend, presiona `Ctrl+C` en la terminal. Si el puerto está ocupado, puedes usar otro con `-Port` y cambiar la dirección en el navegador.

Si tu base tiene otra dirección o usuario, configura `DB_URL` y `DB_USER` antes de ejecutar el lanzador. Las contraseñas se pasan mediante `DB_PASSWORD` y `ADMIN_PASSWORD`; no se guardan en el código.

## Organización

El proyecto sigue MVC:

- **Modelo:** entidades `Habitacion` y `Usuario`, junto con sus repositorios.
- **Vista:** páginas de login y administración en `backend/src/main/resources/static`.
- **Controlador:** endpoints que reciben las solicitudes de la interfaz.

La lógica del CRUD está en `HabitacionService` y la configuración de seguridad en la carpeta `security`.

## Pruebas
<img width="1142" height="634" alt="image" src="https://github.com/user-attachments/assets/093ea314-3a97-4a29-8f53-e526a0febf70" />

La compilación pasó con 3 pruebas automatizadas y sin errores. Estas usan H2 y comprueban autenticación, CRUD, validación y seguridad.

También se probó el acceso con PostgreSQL, el CRUD y la persistencia de la habitación 101 después de reiniciar el backend. Los detalles están en [RESULTADOS-PRUEBAS.md](RESULTADOS-PRUEBAS.md).

Para repetir la prueba de PostgreSQL, detén la ejecución anterior o elige un puerto libre:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-HotelManager.ps1 -Verify -Port 8081
```

## Ayuda y demostración

Si encuentras un error, puedes abrir un [Issue](https://github.com/LangleyRunner/HotelManager/issues) con el mensaje y los pasos para reproducirlo, sin incluir contraseñas.

El [guion de demostración](GUION-DEMO.md) sirve como guía para presentar el login, el CRUD y la seguridad.

## Autor

[LangleyRunner](https://github.com/LangleyRunner)

## Licencia

El proyecto todavía no tiene una licencia definida.

No se ha añadido un archivo `LICENSE` para el código propio del proyecto. La licencia queda pendiente de decisión del autor.

Las dependencias mantienen sus licencias respectivas. Sencha Ext JS requiere respetar sus condiciones de licencia y activación; la alternativa temporal no modifica ni omite esa activación.
