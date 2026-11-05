package com.hotelmanager.backend.controller;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import java.util.Comparator;
import java.util.List;

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ApiExceptionHandler {
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ProblemDetail conflict(DataIntegrityViolationException error) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT,
            "Los datos duplican un registro o el registro está relacionado con otros datos.");
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail validation(MethodArgumentNotValidException error) {
        List<String> mensajes = error.getBindingResult().getFieldErrors().stream()
            .sorted(Comparator.comparing(e -> e.getField()))
            .map(e -> e.getField() + ": " + e.getDefaultMessage()).toList();
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST,
            String.join(". ", mensajes));
        problem.setProperty("errors", mensajes);
        return problem;
    }
}
