package com.hotelmanager.backend.service;

import com.hotelmanager.backend.controller.HabitacionRequest;
import com.hotelmanager.backend.model.Habitacion;
import com.hotelmanager.backend.repository.HabitacionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.util.List;

@Service
@Transactional
public class HabitacionService {
    private final HabitacionRepository repository;
    private final PisoService pisos;

    public HabitacionService(HabitacionRepository repository, PisoService pisos) {
        this.repository = repository;
        this.pisos = pisos;
    }

    @Transactional(readOnly = true)
    public List<Habitacion> listar() { return repository.findAll(); }

    @Transactional(readOnly = true)
    public Habitacion buscarPorId(Long id) {
        return repository.findById(id).orElseThrow(() ->
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Habitación no encontrada"));
    }

    public Habitacion crear(HabitacionRequest datos) {
        Habitacion habitacion = new Habitacion();
        aplicar(habitacion, datos);
        return repository.saveAndFlush(habitacion);
    }

    public Habitacion actualizar(Long id, HabitacionRequest datos) {
        Habitacion habitacion = buscarPorId(id);
        aplicar(habitacion, datos);
        return repository.saveAndFlush(habitacion);
    }

    private void aplicar(Habitacion habitacion, HabitacionRequest datos) {
        habitacion.setNumero(datos.numero());
        habitacion.setTipo(datos.tipo().strip());
        habitacion.setPrecio(datos.precio());
        habitacion.setDisponible(datos.disponible());
        habitacion.setCapacidad(datos.capacidad());
        // Resolve the reference on the server: never persist a client-supplied Piso entity.
        habitacion.setPiso(pisos.buscar(datos.pisoId()));
        habitacion.setEstadoOperativo(datos.estadoOperativo());
    }

    public void eliminar(Long id) {
        repository.delete(buscarPorId(id));
        repository.flush();
    }
}
