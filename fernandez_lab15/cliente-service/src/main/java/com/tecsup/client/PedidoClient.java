
package com.tecsup.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.Map;

@FeignClient(name = "pedido-service")
public interface PedidoClient {

    @GetMapping("/api/pedidos/{id}")
    Map<String, Object> obtenerPedido(@PathVariable("id") Long id);
}
