package com.hotelmanager.backend.controller;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
@RestControllerAdvice
public class ApiExceptionHandler {
 @ExceptionHandler(DataIntegrityViolationException.class)
 public ProblemDetail conflict(DataIntegrityViolationException error){
 return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT,"El número de habitación ya existe o los datos incumplen las restricciones.");
 }
}