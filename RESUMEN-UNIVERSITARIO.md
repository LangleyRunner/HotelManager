# Cumplimiento
MVC: entidades Habitacion/Usuario y repositorios forman el modelo; HabitacionController expone las operaciones; HabitacionService contiene la lógica; las páginas HTML representan la vista y llaman al controlador.
CRUD: crear, listar, consultar por ID, editar y eliminar mediante POST/GET/PUT/DELETE, con validación y respuestas HTTP.
Seguridad: usuarios en la base, hashes BCrypt, rol ADMIN, sesiones de Spring Security, CSRF habilitado incluso en login/logout y mutaciones, cookies HttpOnly/SameSite. No se desactiva seguridad en las pruebas.
Persistencia: PostgreSQL configurado por variables; JPA update conserva los registros. La prueba contra PostgreSQL y reinicio debe completarse con el lanzador y credenciales reales.
Interfaz: login personalizado, dashboard con métricas, tabla, formularios, consulta individual para editar, confirmación de borrado, mensajes y navegación.
Ext JS: proyecto conservado; la interfaz temporal se entrega separada de su instalación y licencia.
