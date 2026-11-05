package com.hotelmanager.backend.controller;

import com.hotelmanager.backend.model.EstadoOperativo;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record HabitacionRequest(
    @NotNull(message = "El número es obligatorio")
    @Min(value = 1, message = "El número debe ser mayor que cero") Integer numero,
    @NotBlank(message = "El tipo es obligatorio")
    @Size(max = 100, message = "El tipo admite hasta 100 caracteres") String tipo,
    @NotNull(message = "La tarifa es obligatoria")
    @DecimalMin(value = "0.01", message = "La tarifa debe ser mayor que cero")
    @Digits(integer = 8, fraction = 2, message = "La tarifa admite hasta 8 enteros y 2 decimales") BigDecimal precio,
    @NotNull(message = "Indica la disponibilidad actual") Boolean disponible,
    @NotNull(message = "La capacidad es obligatoria")
    @Min(value = 1, message = "La capacidad debe ser al menos 1 huésped") Integer capacidad,
    @NotNull(message = "Selecciona un piso")
    @Positive(message = "El piso seleccionado no es válido") Long pisoId,
    @NotNull(message = "Selecciona el estado operativo") EstadoOperativo estadoOperativo
) {}
