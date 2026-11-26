package com.tecsup.services;

import com.tecsup.client.ClienteClient;
import com.tecsup.dto.ClienteDTO;
import feign.FeignException;
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ClienteRetryService {

    private final ClienteClient clienteClient;

    public ClienteRetryService(ClienteClient clienteClient) {
        this.clienteClient = clienteClient;
    }

    @Retry(name = "clienteRetry", fallbackMethod = "clienteFallback")
    public ClienteDTO obtenerCliente(Long id) {
        System.out.println("Intento HTTP hacia cliente-service, id=" + id);
        return clienteClient.obtenerCliente(id);
    }

    public ClienteDTO clienteFallback(Long id, Exception ex) {
        if (ex instanceof FeignException.NotFound) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Cliente no encontrado", ex);
        }
        System.out.println("Retry cliente agotado: " + ex.getClass().getSimpleName());
        return new ClienteDTO(id, "Cliente temporalmente no disponible", null);
    }
}
