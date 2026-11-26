package com.tecsup.dto;

import com.tecsup.model.EstadoPedido;

public record PedidoRespuestaDTO(
        Long id,
        Integer cantidad,
        EstadoPedido estado,
        ClienteDTO cliente,
        ProductoDTO producto
) {
}
