package com.hotelmanager.backend.security;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
@Configuration
public class SecurityConfig {
 @Bean public PasswordEncoder passwordEncoder(){return new BCryptPasswordEncoder();}
 @Bean public SecurityFilterChain securityFilterChain(HttpSecurity http, UserDetailsService users) throws Exception {
  http.authorizeHttpRequests(auth -> auth
   .requestMatchers("/login.html","/login","/api/csrf","/error").permitAll()
   .requestMatchers("/api/habitaciones/**").hasRole("ADMIN").anyRequest().authenticated())
   .userDetailsService(users)
   .formLogin(form -> form.loginPage("/login.html").loginProcessingUrl("/login")
    .defaultSuccessUrl("/",true).failureUrl("/login.html?error").permitAll())
   .exceptionHandling(errors -> errors.authenticationEntryPoint(
    (request,response,exception) -> {if(request.getRequestURI().startsWith(request.getContextPath()+"/api/")) response.sendError(401); else response.sendRedirect("/login.html");}))
   .logout(logout -> logout.logoutSuccessUrl("/login.html?logout").permitAll());
  return http.build();
 }
}