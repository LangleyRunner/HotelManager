package com.hotelmanager.backend.controller;

import com.hotelmanager.backend.model.Piso;
import com.hotelmanager.backend.service.PisoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/pisos")
public class PisoController {
    private final PisoService service;
    public PisoController(PisoService service) { this.service = service; }

    @GetMapping public List<Piso> listar() { return service.listar(); }
    @GetMapping("/{id}") public Piso buscar(@PathVariable Long id) { return service.buscar(id); }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public Piso crear(@Valid @RequestBody PisoRequest datos) { return service.crear(datos.nombre()); }
    @PutMapping("/{id}")
    public Piso actualizar(@PathVariable Long id, @Valid @RequestBody PisoRequest datos) {
        return service.actualizar(id, datos.nombre());
    }
    @DeleteMapping("/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Long id) { service.eliminar(id); }
}
