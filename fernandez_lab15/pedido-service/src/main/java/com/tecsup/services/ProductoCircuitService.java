
package com.tecsup.services;

import com.tecsup.client.ProductoClient;
import com.tecsup.dto.ProductoDTO;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import org.springframework.stereotype.Service;

@Service
public class ProductoCircuitService {

    private final ProductoClient productoClient;

    public ProductoCircuitService(ProductoClient productoClient) {
        this.productoClient = productoClient;
    }

    @CircuitBreaker(
            name = "productoService",
            fallbackMethod = "productoFallback"
    )
    @Bulkhead(name = "productoBulkhead")
    public ProductoDTO obtenerProducto(Long id) {

        System.out.println("Consultando producto-service...");

        return productoClient.obtenerProducto(id);
    }

    public ProductoDTO productoFallback(Long id, Exception ex) {

        if (ex instanceof feign.FeignException.NotFound) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.NOT_FOUND, "Producto no encontrado", ex);
        }

        System.out.println(
                "Circuit Breaker producto activado: " + ex.getMessage()
        );

        return new ProductoDTO(
                id,
                "Producto temporalmente no disponible",
                null
        );
    }
}
