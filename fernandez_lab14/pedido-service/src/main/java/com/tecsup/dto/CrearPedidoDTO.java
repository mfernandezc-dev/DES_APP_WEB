package com.tecsup.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record CrearPedidoDTO(
        @NotNull(message = "El clienteId es obligatorio") Long clienteId,
        @NotNull(message = "El productoId es obligatorio") Long productoId,
        @NotNull(message = "La cantidad es obligatoria")
        @Min(value = 1, message = "La cantidad debe ser mayor a cero") Integer cantidad
) {
}
