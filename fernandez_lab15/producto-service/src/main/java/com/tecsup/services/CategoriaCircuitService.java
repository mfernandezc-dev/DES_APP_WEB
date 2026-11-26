
package com.tecsup.services;

import com.tecsup.client.CategoriaClient;
import com.tecsup.dto.CategoriaDTO;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import org.springframework.stereotype.Service;

@Service
public class CategoriaCircuitService {

    private final CategoriaClient categoriaClient;

    public CategoriaCircuitService(CategoriaClient categoriaClient) {
        this.categoriaClient = categoriaClient;
    }

    @CircuitBreaker(
            name = "categoriaService",
            fallbackMethod = "categoriaFallback"
    )
    @Bulkhead(name = "categoriaBulkhead")
    @Retry(name = "categoriaRetry")
    public CategoriaDTO obtenerCategoria(Long id) {

        System.out.println("Llamando a categoria-service...");

        return categoriaClient.obtenerCategoria(id);
    }

    public CategoriaDTO categoriaFallback(Long id, Exception ex) {

        if (ex instanceof feign.FeignException.NotFound) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.NOT_FOUND, "Categoria no encontrada", ex);
        }

        System.out.println(
                "Circuit Breaker fallback activado: " + ex.getMessage()
        );

        CategoriaDTO dto = new CategoriaDTO();
        dto.setId(id);
        dto.setNombre("Categoría temporal no disponible");
        dto.setEstado("NO DISPONIBLE");

        return dto;
    }
}
