package com.tecsup.controller;

import com.tecsup.dto.CrearPedidoDTO;
import com.tecsup.dto.PedidoRespuestaDTO;
import com.tecsup.model.EstadoPedido;
import com.tecsup.model.Pedido;
import com.tecsup.services.PedidoService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/pedidos")
public class PedidoController {

    private final PedidoService service;

    public PedidoController(PedidoService service) {
        this.service = service;
    }

    @GetMapping
    public List<Pedido> listar() {
        return service.listar();
    }

    // Opcion adicional: conserva el contrato y el metodo listar() existentes.
    @GetMapping(params = "detallado=true")
    public List<PedidoRespuestaDTO> listarDetallados() {
        return service.listarDetallados();
    }

    @GetMapping("/{id}")
    public PedidoRespuestaDTO obtener(@PathVariable Long id) {
        return service.obtener(id);
    }

    @PostMapping
    public ResponseEntity<PedidoRespuestaDTO> guardar(
            @Valid @RequestBody CrearPedidoDTO datos) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(service.guardar(datos));
    }

    @PutMapping("/{id}/estado")
    public PedidoRespuestaDTO cambiarEstado(
            @PathVariable Long id,
            @RequestBody CambioEstadoRequest datos) {
        if (datos.estado() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El estado es obligatorio");
        }
        return service.cambiarEstado(id, datos.estado());
    }

    public record CambioEstadoRequest(@NotNull EstadoPedido estado) {
    }
}
