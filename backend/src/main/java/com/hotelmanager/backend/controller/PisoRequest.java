package com.hotelmanager.backend.controller;

import jakarta.validation.constraints.*;

public record PisoRequest(
    @NotBlank(message = "El nombre del piso es obligatorio")
    @Size(max = 60, message = "El nombre admite hasta 60 caracteres") String nombre
) {}
