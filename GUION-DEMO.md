# Guion de demostración — máximo 3 minutos
- 0:00–0:20: HotelManager y arquitectura MVC: modelo JPA/PostgreSQL, controladores REST, servicio y vista web.
- 0:20–0:40: Abrir login, ingresar como admin y mostrar dashboard e indicadores. No mostrar contraseñas ni variables de entorno.
- 0:40–1:10: Mostrar 101. Crear una habitación temporal con número libre, tipo y precio; mostrar mensaje y tabla.
- 1:10–1:35: Editar esa habitación, cambiar precio/disponibilidad y mostrar los cambios; eliminarla con confirmación.
- 1:35–2:00: Mostrar 101 en PostgreSQL y el informe PASS del lanzador después del reinicio, únicamente si se ha generado.
- 2:00–2:25: Cerrar sesión. Abrir /api/habitaciones en ventana privada y mostrar acceso 401; intentar POST sin sesión y explicar que se bloquea. Mostrar la prueba automatizada que rechaza mutaciones sin CSRF.
- 2:25–2:45: Mostrar consulta SQL que indica bcrypt=true y longitud=60, sin copiar hashes ni mostrar credenciales.
- 2:45–3:00: Mostrar README, repositorio y resultados reales. Explicar que HTML/CSS/JS es la alternativa temporal y Ext JS sigue pendiente si no se pudo activar.
No afirmar que PostgreSQL/reinicio se verificaron si el informe real todavía no existe.
