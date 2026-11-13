package com.tecsup.services;

import com.tecsup.client.ClienteClient;
import com.tecsup.client.ProductoClient;
import com.tecsup.dto.ClienteDTO;
import com.tecsup.dto.CrearPedidoDTO;
import com.tecsup.dto.PedidoRespuestaDTO;
import com.tecsup.dto.ProductoDTO;
import com.tecsup.model.DetallePedido;
import com.tecsup.model.EstadoPedido;
import com.tecsup.model.Pedido;
import com.tecsup.repository.PedidoRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@Service
public class PedidoService {

    private final PedidoRepository repository;
    private final ClienteClient clienteClient;
    private final ProductoClient productoClient;

    public PedidoService(PedidoRepository repository,
                         ClienteClient clienteClient,
                         ProductoClient productoClient) {
        this.repository = repository;
        this.clienteClient = clienteClient;
        this.productoClient = productoClient;
    }

    @Transactional(readOnly = true)
    public List<Pedido> listar() {
        return repository.findAll();
    }

    @Transactional
    public PedidoRespuestaDTO guardar(CrearPedidoDTO datos) {
        // Consultar las APIs remotas antes de registrar.
        clienteClient.obtenerCliente(datos.clienteId());
        productoClient.obtenerProducto(datos.productoId());

        Pedido pedido = new Pedido();
        pedido.setFecha(LocalDate.now());
        pedido.setIdCliente(datos.clienteId());
        pedido.setEstado(EstadoPedido.PENDIENTE);

        DetallePedido detalle = new DetallePedido();
        detalle.setIdProducto(datos.productoId());
        detalle.setCantidad(datos.cantidad());
        detalle.setPedido(pedido);

        pedido.setDetalles(List.of(detalle));
        Pedido guardado = repository.save(pedido);
        return construirRespuesta(guardado);
    }

    @Transactional(readOnly = true)
    public PedidoRespuestaDTO obtener(Long id) {
        return construirRespuesta(buscarPedido(id));
    }

    @Transactional
    public PedidoRespuestaDTO cambiarEstado(Long id, EstadoPedido estado) {
        Pedido pedido = buscarPedido(id);
        pedido.setEstado(estado);
        repository.save(pedido);
        return construirRespuesta(pedido);
    }

    private Pedido buscarPedido(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Pedido no encontrado"));
    }

    private PedidoRespuestaDTO construirRespuesta(Pedido pedido) {
        List<DetallePedido> detalles = pedido.getDetalles();
        if (detalles == null || detalles.size() != 1) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Esta consulta requiere un pedido con un detalle");
        }

        DetallePedido detalle = detalles.get(0);
        ClienteDTO cliente = clienteClient.obtenerCliente(pedido.getIdCliente());
        ProductoDTO producto = productoClient.obtenerProducto(detalle.getIdProducto());

        return new PedidoRespuestaDTO(pedido.getIdPedido(), detalle.getCantidad(),
                pedido.getEstado(), cliente, producto);
    }
}
