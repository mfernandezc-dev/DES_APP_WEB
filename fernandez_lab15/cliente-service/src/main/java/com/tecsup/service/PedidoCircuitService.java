
package com.tecsup.service;

import com.tecsup.client.PedidoClient;
import feign.FeignException;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class PedidoCircuitService {

    private final PedidoClient pedidoClient;

    public PedidoCircuitService(PedidoClient pedidoClient) {
        this.pedidoClient = pedidoClient;
    }

    @CircuitBreaker(
            name = "pedidoService",
            fallbackMethod = "pedidoFallback"
    )
    public Map<String, Object> obtenerPedido(Long id) {

        System.out.println("Consultando pedido-service...");

        return pedidoClient.obtenerPedido(id);
    }

    public Map<String, Object> pedidoFallback(
            Long id, Exception ex) {

        // No ocultar un pedido inexistente.
        if (ex instanceof FeignException.NotFound) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.NOT_FOUND,
                    "Pedido no encontrado",
                    ex
            );
        }

        System.out.println(
                "Circuit Breaker pedido activado: "
                        + ex.getMessage()
        );

        return Map.of(
                "idSolicitado", id,
                "disponible", false,
                "mensaje", "Pedido Service temporalmente no disponible"
        );
    }
}
