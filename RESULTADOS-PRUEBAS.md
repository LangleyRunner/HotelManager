# Verificación de la administración MVC — 5 de noviembre de 2026

- Maven verify: BUILD SUCCESS. 7 pruebas, 0 fallos, 0 errores.
- Pruebas HTTP reales con Spring Boot y H2: capacidad cero, negativa, nula y fraccionaria rechazada; tarifa cero rechazada; piso inexistente rechazado; errores antes de persistir; CRUD; duplicados; roles; CSRF; logout y registros anteriores legibles.
- PostgreSQL real: CRUD de pisos y habitaciones, relación FK, capacidad cero rechazada con HTTP 400 sin guardar, protección de eliminación de piso relacionado, persistencia después de reiniciar el backend y habitación 101 conservada. Resultado PASS del lanzador actualizado.
- Prueba DOM conectada a PostgreSQL: creación de piso desde el formulario, aparición en el dropdown, creación y edición de habitación y visualización del nombre del piso. Resultado PASS. Se retiraron solo los registros temporales de esas pruebas.
- La habitación 101 anterior sigue registrada. Capacidad, piso y estado operativo permanecen sin configurar hasta que el administrador indique sus datos reales.
- render.yaml validado contra el esquema oficial https://render.com/schema/render.yaml.json.
- No se comprobó la construcción de Docker ni se publicó en Render. El usuario pidió dejar el despliegue preparado.
- No se realizó una revisión manual completa del navegador ni se grabó el video.
- Se creó un respaldo PostgreSQL local en work fuera del repositorio. No se publica.
- No se implementó el algoritmo de asignación ni reservas. Esta entrega contiene la administración que alimentará ese core.
