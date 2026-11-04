
package com.veterinaria.consulta.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientResponseException;

import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // RECURSO NO ENCONTRADO
    @ExceptionHandler(RecursoNoEncontradoException.class)
    public ResponseEntity<Map<String, String>> manejarNoEncontrado(
            RecursoNoEncontradoException ex) {

        Map<String, String> respuesta = new LinkedHashMap<>();
        respuesta.put("error", "Recurso no encontrado");
        respuesta.put("mensaje", ex.getMessage());

        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(respuesta);
    }

    // DATOS INVALIDOS
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> manejarValidaciones(
            MethodArgumentNotValidException ex) {

        Map<String, String> detalles = new LinkedHashMap<>();

        ex.getBindingResult().getFieldErrors().forEach(error ->
                detalles.put(
                        error.getField(),
                        error.getDefaultMessage()
                )
        );

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("error", "Datos invalidos");
        respuesta.put("detalles", detalles);

        return ResponseEntity.badRequest().body(respuesta);
    }

    // JSON INCORRECTO
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, String>> manejarJsonInvalido(
            HttpMessageNotReadableException ex) {

        Map<String, String> respuesta = new LinkedHashMap<>();
        respuesta.put("error", "Solicitud invalida");
        respuesta.put("mensaje", "El cuerpo JSON es incorrecto");

        return ResponseEntity.badRequest().body(respuesta);
    }

    // SERVICIO MASCOTA NO DISPONIBLE
    @ExceptionHandler(ResourceAccessException.class)
    public ResponseEntity<Map<String, String>> manejarConexion(
            ResourceAccessException ex) {

        Map<String, String> respuesta = new LinkedHashMap<>();
        respuesta.put("error", "Servicio no disponible");
        respuesta.put("mensaje",
                "No se pudo conectar con el microservicio Mascota");

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(respuesta);
    }

    // ERROR HTTP DEL SERVICIO MASCOTA
    @ExceptionHandler(RestClientResponseException.class)
    public ResponseEntity<Map<String, String>> manejarServicioExterno(
            RestClientResponseException ex) {

        Map<String, String> respuesta = new LinkedHashMap<>();
        respuesta.put("error", "Error de comunicacion");
        respuesta.put("mensaje",
                "El microservicio Mascota devolvio un error HTTP");

        return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                .body(respuesta);
    }
}
