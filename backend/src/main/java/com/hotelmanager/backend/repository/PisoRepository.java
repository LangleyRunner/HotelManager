package com.hotelmanager.backend.repository;

import com.hotelmanager.backend.model.Piso;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PisoRepository extends JpaRepository<Piso, Long> {
    boolean existsByNombreIgnoreCase(String nombre);
    boolean existsByNombreIgnoreCaseAndIdNot(String nombre, Long id);
}
