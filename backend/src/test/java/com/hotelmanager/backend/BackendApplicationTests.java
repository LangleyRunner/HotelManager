package com.hotelmanager.backend;

import com.hotelmanager.backend.model.Habitacion;
import com.hotelmanager.backend.model.Usuario;
import com.hotelmanager.backend.repository.HabitacionRepository;
import com.hotelmanager.backend.repository.UsuarioRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestExecutionListeners;
import org.springframework.test.context.support.DependencyInjectionTestExecutionListener;

import java.math.BigDecimal;
import java.net.*;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
    "spring.datasource.url=jdbc:h2:mem:hotelmanager_test;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=create-drop"
})
// Real HTTP/JPA tests use no mocks; do not attach an instrumentation agent.
@TestExecutionListeners(listeners = DependencyInjectionTestExecutionListener.class,
    mergeMode = TestExecutionListeners.MergeMode.REPLACE_DEFAULTS)
class BackendApplicationTests {
    static final String TEST_PASSWORD = UUID.randomUUID().toString();
    @DynamicPropertySource static void secrets(DynamicPropertyRegistry r) {
        r.add("ADMIN_PASSWORD", () -> TEST_PASSWORD);
    }

    @LocalServerPort int port;
    @Autowired UsuarioRepository users;
    @Autowired HabitacionRepository habitaciones;
    @Autowired PasswordEncoder encoder;
    HttpClient client;

    @BeforeEach void setup() {
        client = HttpClient.newBuilder()
            .cookieHandler(new CookieManager(null, CookiePolicy.ACCEPT_ALL))
            .followRedirects(HttpClient.Redirect.NEVER).build();
    }

    HttpResponse<String> send(String path, String method, String body, String token) throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path));
        if (token != null) request.header("X-CSRF-TOKEN", token);
        if (body != null) request.header("Content-Type",
            path.equals("/login") ? "application/x-www-form-urlencoded" : "application/json");
        return client.send(request.method(method, body == null
            ? HttpRequest.BodyPublishers.noBody()
            : HttpRequest.BodyPublishers.ofString(body)).build(), HttpResponse.BodyHandlers.ofString());
    }

    String csrf() throws Exception {
        var response = send("/api/csrf", "GET", null, null);
        assertEquals(200, response.statusCode());
        var matcher = Pattern.compile("\"token\":\"([^\"]+)\"").matcher(response.body());
        assertTrue(matcher.find());
        return matcher.group(1);
    }

    String login() throws Exception { return login("admin", TEST_PASSWORD); }
    String login(String username, String password) throws Exception {
        var response = send("/login", "POST",
            "username=" + URLEncoder.encode(username, StandardCharsets.UTF_8)
                + "&password=" + URLEncoder.encode(password, StandardCharsets.UTF_8)
                + "&_csrf=" + URLEncoder.encode(csrf(), StandardCharsets.UTF_8), null);
        assertEquals(302, response.statusCode());
        assertFalse(response.headers().firstValue("Location").orElse("").contains("error"));
        return csrf();
    }

    long idOf(HttpResponse<String> response) {
        var matcher = Pattern.compile("\"id\":(\\d+)").matcher(response.body());
        assertTrue(matcher.find(), response.body());
        return Long.parseLong(matcher.group(1));
    }

    long piso(String token) throws Exception {
        var response = send("/api/pisos", "POST",
            "{\"nombre\":\"Piso prueba " + UUID.randomUUID() + "\"}", token);
        assertEquals(201, response.statusCode(), response.body());
        return idOf(response);
    }

    String room(long floor, int number) {
        return """
            {"numero":%d,"tipo":"Doble","precio":55.00,"disponible":true,
             "capacidad":2,"pisoId":%d,"estadoOperativo":"HABILITADA"}
            """.formatted(number, floor).replaceAll("\\s+", "");
    }

    @Test void anonymousAndCsrfProtection() throws Exception {
        for (String path : new String[]{"/api/habitaciones", "/api/pisos"}) {
            assertEquals(401, send(path, "GET", null, null).statusCode());
            assertEquals(403, send(path, "POST", "{}", null).statusCode());
            assertEquals(401, send(path, "POST", "{}", csrf()).statusCode());
        }
        assertEquals(302, send("/", "GET", null, null).statusCode());
        assertEquals(200, send("/login.html", "GET", null, null).statusCode());
        assertEquals(200, send("/health", "GET", null, null).statusCode());
    }

    @Test void loginLogoutAndBcrypt() throws Exception {
        var admin = users.findByUsername("admin").orElseThrow();
        assertTrue(admin.getPassword().startsWith("$2"));
        assertNotEquals(TEST_PASSWORD, admin.getPassword());
        assertTrue(encoder.matches(TEST_PASSWORD, admin.getPassword()));
        var wrong = send("/login", "POST", "username=admin&password=incorrect&_csrf="
            + URLEncoder.encode(csrf(), StandardCharsets.UTF_8), null);
        assertEquals(302, wrong.statusCode());
        assertTrue(wrong.headers().firstValue("Location").orElse("").contains("error"));
        String token = login();
        assertEquals(200, send("/", "GET", null, null).statusCode());
        assertEquals(200, send("/admin.js", "GET", null, null).statusCode());
        assertEquals(403, send("/api/habitaciones", "POST", "{}", null).statusCode());
        assertEquals(403, send("/api/pisos", "POST", "{}", null).statusCode());
        assertEquals(403, send("/logout", "POST", null, null).statusCode());
        assertEquals(302, send("/logout", "POST", null, token).statusCode());
        assertEquals(401, send("/api/habitaciones", "GET", null, null).statusCode());
    }

    @Test void roomCrudAndDuplicateNumber() throws Exception {
        String token = login();
        long floor = piso(token);
        var created = send("/api/habitaciones", "POST", room(floor, 9091), token);
        assertEquals(201, created.statusCode(), created.body());
        String path = "/api/habitaciones/" + idOf(created);
        try {
            assertEquals(200, send("/api/habitaciones", "GET", null, null).statusCode());
            var found = send(path, "GET", null, null);
            assertEquals(200, found.statusCode());
            assertTrue(found.body().contains("\"piso\":{"));
            assertTrue(found.body().contains("\"capacidad\":2"));
            assertEquals(409, send("/api/habitaciones", "POST", room(floor, 9091), token).statusCode());
            String updated = room(floor, 9091).replace("55.00", "65.00")
                .replace("HABILITADA", "MANTENIMIENTO");
            assertEquals(200, send(path, "PUT", updated, token).statusCode());
            assertTrue(send(path, "GET", null, null).body().contains("65.00"));
            assertTrue(send(path, "GET", null, null).body().contains("MANTENIMIENTO"));
        } finally {
            assertEquals(204, send(path, "DELETE", null, token).statusCode());
            assertEquals(204, send("/api/pisos/" + floor, "DELETE", null, token).statusCode());
        }
        assertEquals(404, send(path, "GET", null, null).statusCode());
    }

    @Test void backendCapacityAndForeignKeyValidationBeforeSaving() throws Exception {
        String token = login();
        long floor = piso(token);
        long before = habitaciones.count();
        try {
            for (String invalid : new String[]{
                room(floor, 9092).replace("\"capacidad\":2", "\"capacidad\":0"),
                room(floor, 9092).replace("\"capacidad\":2", "\"capacidad\":-1"),
                room(floor, 9092).replace("\"capacidad\":2", "\"capacidad\":null"),
                room(floor, 9092).replace("\"capacidad\":2", "\"capacidad\":1.5"),
                room(floor, 9092).replace("\"precio\":55.00", "\"precio\":0"),
                room(floor, 9092).replace("\"pisoId\":" + floor, "\"pisoId\":null"),
                room(floor, 9092).replace("HABILITADA", "ESTADO_INVENTADO")
            }) {
                var response = send("/api/habitaciones", "POST", invalid, token);
                assertEquals(400, response.statusCode(), response.body());
                assertEquals(before, habitaciones.count(), "El servidor no debe guardar solicitudes inválidas");
            }
            var badReference = send("/api/habitaciones", "POST", room(999999999L, 9092), token);
            assertEquals(404, badReference.statusCode());
            assertEquals(before, habitaciones.count());
            var invalidCapacity = send("/api/habitaciones", "POST",
                room(floor, 9092).replace("\"capacidad\":2", "\"capacidad\":0"), token);
            assertTrue(invalidCapacity.body().contains("capacidad"), invalidCapacity.body());
        } finally {
            send("/api/pisos/" + floor, "DELETE", null, token);
        }
    }

    @Test void pisoCrudAndReferencedDeletionProtection() throws Exception {
        String token = login();
        long floor = piso(token);
        String floorPath = "/api/pisos/" + floor;
        var created = send("/api/habitaciones", "POST", room(floor, 9093), token);
        assertEquals(201, created.statusCode());
        String path = "/api/habitaciones/" + idOf(created);
        try {
            assertEquals(409, send(floorPath, "DELETE", null, token).statusCode());
            assertEquals(200, send(floorPath, "PUT", "{\"nombre\":\"Piso renombrado\"}", token).statusCode());
            assertTrue(send(path, "GET", null, null).body().contains("Piso renombrado"));
            var invalid = send(path, "PUT", room(floor, 9093).replace("\"capacidad\":2", "\"capacidad\":0"), token);
            assertEquals(400, invalid.statusCode());
            assertTrue(send(path, "GET", null, null).body().contains("\"capacidad\":2"));
            assertEquals(400, send("/api/pisos", "POST", "{\"nombre\":\"   \"}", token).statusCode());
            assertEquals(409, send("/api/pisos", "POST", "{\"nombre\":\"piso renombrado\"}", token).statusCode());
        } finally {
            send(path, "DELETE", null, token);
            assertEquals(204, send(floorPath, "DELETE", null, token).statusCode());
        }
        assertEquals(404, send(floorPath, "GET", null, null).statusCode());
    }

    @Test void nonAdminCannotManageEitherCatalog() throws Exception {
        Usuario user = new Usuario();
        user.setUsername("restricted-" + UUID.randomUUID());
        user.setPassword(encoder.encode(TEST_PASSWORD));
        user.setRol("USER");
        users.saveAndFlush(user);
        try {
            String token = login(user.getUsername(), TEST_PASSWORD);
            for (String path : new String[]{"/api/habitaciones", "/api/pisos"}) {
                assertEquals(403, send(path, "GET", null, null).statusCode());
                assertEquals(403, send(path, "POST", "{}", token).statusCode());
            }
        } finally {
            users.deleteById(user.getId());
        }
    }

    @Test void legacyRoomsRemainReadableWithoutInventingCapacityOrFloor() throws Exception {
        Habitacion old = new Habitacion();
        old.setNumero(9094);
        old.setTipo("Individual");
        old.setPrecio(new BigDecimal("55.00"));
        old.setDisponible(true);
        old = habitaciones.saveAndFlush(old);
        try {
            login();
            var result = send("/api/habitaciones/" + old.getId(), "GET", null, null);
            assertEquals(200, result.statusCode());
            assertTrue(result.body().contains("\"capacidad\":null"));
            assertTrue(result.body().contains("\"piso\":null"));
        } finally {
            habitaciones.deleteById(old.getId());
        }
    }
}
