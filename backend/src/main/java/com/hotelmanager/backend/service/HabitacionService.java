
package com.hotelmanager.backend.service;

import com.hotelmanager.backend.model.Habitacion;
import com.hotelmanager.backend.repository.HabitacionRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.List;

@Service
public class HabitacionService {

    private final HabitacionRepository repository;

    public HabitacionService(HabitacionRepository repository) {
        this.repository = repository;
    }

    // READ: Listar habitaciones
    public List<Habitacion> listar() {
        return repository.findAll();
    }

    // READ: Buscar por ID
    public Habitacion buscarPorId(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "Habitación no encontrada"));
    }

    // CREATE: Crear habitación
    public Habitacion crear(Habitacion habitacion) {
        habitacion.setId(null);
        return repository.save(habitacion);
    }

    // UPDATE: Actualizar habitación
    public Habitacion actualizar(Long id, Habitacion datos) {
        Habitacion habitacion = buscarPorId(id);

        habitacion.setNumero(datos.getNumero());
        habitacion.setTipo(datos.getTipo());
        habitacion.setPrecio(datos.getPrecio());
        habitacion.setDisponible(datos.getDisponible());

        return repository.save(habitacion);
    }

    // DELETE: Eliminar habitación
    public void eliminar(Long id) {
        Habitacion habitacion = buscarPorId(id);
        repository.delete(habitacion);
    }
}
