package com.tecsup.services;

import com.tecsup.client.ClienteClient;
import com.tecsup.client.ProductoClient;
import com.tecsup.dto.ClienteDTO;
import com.tecsup.dto.CrearPedidoDTO;
import com.tecsup.repository.PedidoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class PedidoServiceValidationTests {
    private PedidoRepository repository;
    private ClienteClient cliente;
    private ProductoClient producto;
    private ProductoCircuitService circuito;
    private ClienteRetryService retry;
    private PedidoService service;

    @BeforeEach
    void setUp() {
        repository = mock(PedidoRepository.class);
        cliente = mock(ClienteClient.class);
        producto = mock(ProductoClient.class);
        circuito = mock(ProductoCircuitService.class);
        retry = mock(ClienteRetryService.class);
        service = new PedidoService(repository, cliente, producto, circuito, retry);
    }

    @Test
    void noGuardaSiClienteNoExiste() {
        when(cliente.obtenerCliente(99L)).thenThrow(new IllegalArgumentException("Cliente inexistente"));
        assertThrows(IllegalArgumentException.class, () -> service.guardar(new CrearPedidoDTO(99L,1L,1)));
        verifyNoInteractions(repository, producto, circuito, retry);
    }

    @Test
    void noGuardaSiProductoNoExisteNiUsaFallbackParaValidar() {
        when(cliente.obtenerCliente(1L)).thenReturn(new ClienteDTO(1L,"Carlos","Ramirez"));
        when(producto.obtenerProducto(99L)).thenThrow(new IllegalArgumentException("Producto inexistente"));
        assertThrows(IllegalArgumentException.class, () -> service.guardar(new CrearPedidoDTO(1L,99L,1)));
        verifyNoInteractions(repository, circuito, retry);
    }
}
