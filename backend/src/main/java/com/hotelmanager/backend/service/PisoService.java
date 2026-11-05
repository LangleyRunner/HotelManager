package com.hotelmanager.backend.service;

import com.hotelmanager.backend.model.Piso;
import com.hotelmanager.backend.repository.PisoRepository;
import com.hotelmanager.backend.repository.HabitacionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;

@Service
@Transactional
public class PisoService {
    private final PisoRepository pisos;
    private final HabitacionRepository habitaciones;

    public PisoService(PisoRepository pisos, HabitacionRepository habitaciones) {
        this.pisos = pisos;
        this.habitaciones = habitaciones;
    }

    @Transactional(readOnly = true)
    public List<Piso> listar() { return pisos.findAll(); }

    @Transactional(readOnly = true)
    public Piso buscar(Long id) {
        return pisos.findById(id).orElseThrow(() ->
            new ResponseStatusException(HttpStatus.NOT_FOUND, "El piso no existe"));
    }

    public Piso crear(String nombre) {
        String limpio = nombre.strip();
        if (pisos.existsByNombreIgnoreCase(limpio)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Ya existe un piso con ese nombre");
        }
        Piso piso = new Piso();
        piso.setNombre(limpio);
        return pisos.saveAndFlush(piso);
    }

    public Piso actualizar(Long id, String nombre) {
        Piso piso = buscar(id);
        String limpio = nombre.strip();
        if (pisos.existsByNombreIgnoreCaseAndIdNot(limpio, id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Ya existe un piso con ese nombre");
        }
        piso.setNombre(limpio);
        return pisos.saveAndFlush(piso);
    }

    public void eliminar(Long id) {
        Piso piso = buscar(id);
        if (habitaciones.existsByPisoId(id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                "No puedes eliminar un piso que tiene habitaciones asignadas");
        }
        pisos.delete(piso);
        pisos.flush();
    }
}
