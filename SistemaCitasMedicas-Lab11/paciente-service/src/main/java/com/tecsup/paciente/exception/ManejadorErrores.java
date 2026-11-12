package com.tecsup.paciente.exception;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class ManejadorErrores {
    @ExceptionHandler(RecursoNoEncontradoException.class)
    public ResponseEntity<Map<String,String>> noEncontrado(RecursoNoEncontradoException ex) {
        return ResponseEntity.status(404).body(Map.of("mensaje", ex.getMessage()));
    }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String,String>> validacion(MethodArgumentNotValidException ex) {
        Map<String,String> errores = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(e -> errores.put(e.getField(), e.getDefaultMessage()));
        return ResponseEntity.badRequest().body(errores);
    }
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String,String>> integridad(DataIntegrityViolationException ex) {
        return ResponseEntity.status(409).body(Map.of("mensaje", "Registro duplicado o relacionado con otros datos"));
    }
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String,String>> estado(ResponseStatusException ex) {
        String razon = ex.getReason() == null ? "Solicitud no válida" : ex.getReason();
        return ResponseEntity.status(ex.getStatusCode()).body(Map.of("mensaje", razon));
    }
}
