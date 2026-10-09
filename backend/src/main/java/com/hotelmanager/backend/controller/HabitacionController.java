
package com.hotelmanager.backend.controller;

import jakarta.validation.Valid;
import com.hotelmanager.backend.model.Habitacion;
import com.hotelmanager.backend.service.HabitacionService;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;

import java.util.List;

@RestController
@RequestMapping("/api/habitaciones")
public class HabitacionController {

    private final HabitacionService service;

    public HabitacionController(HabitacionService service) {
        this.service = service;
    }

    @GetMapping
    public List<Habitacion> listar() {
        return service.listar();
    }

    @GetMapping("/{id}")
    public Habitacion buscar(@PathVariable Long id) {
        return service.buscarPorId(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Habitacion crear(@Valid @RequestBody Habitacion habitacion) {
        return service.crear(habitacion);
    }

    @PutMapping("/{id}")
    public Habitacion actualizar(
            @PathVariable Long id,
            @Valid @RequestBody Habitacion habitacion) {
        return service.actualizar(id, habitacion);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Long id) {
        service.eliminar(id);
    }
}
