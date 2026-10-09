
package com.hotelmanager.backend.security;

import com.hotelmanager.backend.model.Usuario;
import com.hotelmanager.backend.repository.UsuarioRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class AdminInitializer {

    @Bean
    CommandLineRunner crearAdministrador(
            UsuarioRepository repository,
            PasswordEncoder encoder, @Value("${ADMIN_PASSWORD:}") String password) {

        return args -> {
            String username = "admin";


            if (repository.findByUsername(username).isEmpty()) {

                if (password == null || password.isBlank()) {
                    throw new IllegalStateException(
                        "Debes configurar ADMIN_PASSWORD");
                }

                Usuario admin = new Usuario();
                admin.setUsername(username);
                admin.setPassword(encoder.encode(password));
                admin.setRol("ADMIN");

                repository.save(admin);

                System.out.println(
                    "Administrador creado correctamente");
            }
        };
    }
}
