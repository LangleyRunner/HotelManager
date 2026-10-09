
package com.hotelmanager.backend.repository;

import com.hotelmanager.backend.model.Habitacion;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HabitacionRepository
        extends JpaRepository<Habitacion, Long> {
}
