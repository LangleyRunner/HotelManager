# Guion de demostración — Administración MVC

Duración aproximada: 3 minutos. Prepara un número de habitación libre y un piso de prueba. No muestres contraseñas ni variables con secretos.

## 0:00–0:25 · Relación con el core

“Este es HotelManager. El core propuesto es asignar habitaciones a huéspedes y grupos según su capacidad, las fechas y sus preferencias. Para alimentar ese proceso desarrollé la administración de pisos y habitaciones. La asignación automática es una etapa posterior.”

Muestra el login e inicia sesión como administrador.

## 0:25–1:10 · Administración y relación entre tablas

“Primero registro un piso llamado Segundo piso. Ahora creo una habitación e ingreso su número, tipo, capacidad, tarifa y estado operativo.”

Crea el piso, vuelve al formulario de habitaciones y abre el selector.

“Para asignar el piso no escribo una clave foránea. Esta lista carga los registros desde PostgreSQL y aquí aparece el piso que acabo de crear.”

Selecciona el piso y guarda una habitación de prueba. Muestra su nombre en la tabla.

## 1:10–1:35 · MVC

“El modelo contiene las entidades Habitación, Piso y Usuario. La vista son los formularios y las tablas. Los controladores reciben las solicitudes y los servicios aplican las reglas antes de guardar.”

Muestra las carpetas model, controller, service y repository, y la relación ManyToOne en Habitacion.java.

## 1:35–2:15 · Validación en el backend

“La capacidad es un dato crítico para el core: si es incorrecta, la distribución podría no tener espacio para todos. Por eso el servidor exige que sea un entero mayor que cero.”

Muestra HabitacionRequest.java: @NotNull y @Min(1), y el @Valid de HabitacionController.

“Esta prueba envía directamente una petición a la API con capacidad cero, sin depender de JavaScript. Comprueba que se recibe HTTP 400 y que no aumenta el número de registros en la base.”

Muestra backendCapacityAndForeignKeyValidationBeforeSaving y el resultado satisfactorio de Maven. Para grabar una petición real sin pruebas automatizadas, usa un cliente HTTP autenticado con su token CSRF; no confundas el bloqueo del formulario con validación del servidor.

## 2:15–2:40 · Editar, restricciones y eliminar

Cambia la capacidad o tarifa de la habitación de prueba y muestra el resultado.

“El sistema también impide eliminar un piso mientras tenga habitaciones asignadas.”

Intenta eliminar el piso y muestra el rechazo. Después elimina únicamente la habitación de prueba y su piso.

## 2:40–3:00 · Git y despliegue

“El código está versionado en GitHub. El README explica cómo instalarlo, probarlo y ejecutarlo.”

Muestra el repositorio y su historial.

Cuando el despliegue esté completado, muestra la URL HTTPS real y el login. No presentes localhost como despliegue público.

## Pendiente antes de entregar el video

- Publicar la aplicación en Render u otra plataforma.
- Comprobar login y CRUD en la URL pública.
- Grabar la pantalla y tu explicación con Loom u OBS.
- Subir el video a Loom o YouTube y entregar su enlace junto al repositorio.

La aplicación está preparada para desplegarse, pero no se ha publicado ni se ha grabado un video desde este entorno.
