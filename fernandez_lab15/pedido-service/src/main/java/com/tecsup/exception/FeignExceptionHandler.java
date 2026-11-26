package com.tecsup.exception;

import feign.FeignException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import java.util.Map;

@RestControllerAdvice
public class FeignExceptionHandler {
    @ExceptionHandler(FeignException.class)
    public ResponseEntity<Map<String, Object>> manejarReferenciaRemota(FeignException ex) {
        HttpStatus status = ex instanceof FeignException.NotFound
                ? HttpStatus.NOT_FOUND : HttpStatus.SERVICE_UNAVAILABLE;
        String mensaje = status == HttpStatus.NOT_FOUND
                ? "Cliente o producto no encontrado; no se registro el pedido"
                : "No se pudo validar el cliente o producto; servicio temporalmente no disponible";
        return ResponseEntity.status(status).body(Map.of("codigo", status.value(), "mensaje", mensaje));
    }
}
