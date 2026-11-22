
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
    private final ProductoCircuitService productoCircuitService;
    private final ClienteRetryService clienteRetryService;

    public PedidoService(
            PedidoRepository repository,
            ClienteClient clienteClient,
            ProductoClient productoClient,
            ProductoCircuitService productoCircuitService,
            ClienteRetryService clienteRetryService) {

        this.repository = repository;
        this.clienteClient = clienteClient;
        this.productoClient = productoClient;
        this.productoCircuitService = productoCircuitService;
        this.clienteRetryService = clienteRetryService;
    }

    // ==========================================
    // LISTAR PEDIDOS
    // ==========================================

    @Transactional(readOnly = true)
    public List<Pedido> listar() {
        return repository.findAll();
    }

    @Transactional(readOnly = true)
    public List<PedidoRespuestaDTO> listarDetallados() {
        return repository.findAll().stream().map(this::construirRespuesta).toList();
    }

    // ==========================================
    // GUARDAR PEDIDO
    // ==========================================

    @Transactional
    public PedidoRespuestaDTO guardar(CrearPedidoDTO datos) {

        // Validar que el cliente exista.
        clienteClient.obtenerCliente(datos.clienteId());

        // Validar que el producto exista.
        // No utilizar fallback para validar registros nuevos.
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

    // ==========================================
    // BUSCAR PEDIDO POR ID
    // ==========================================

    @Transactional(readOnly = true)
    public PedidoRespuestaDTO obtener(Long id) {
        return construirRespuesta(buscarPedido(id));
    }

    // ==========================================
    // CAMBIAR ESTADO DEL PEDIDO
    // ==========================================

    @Transactional
    public PedidoRespuestaDTO cambiarEstado(
            Long id,
            EstadoPedido estado) {

        Pedido pedido = buscarPedido(id);

        pedido.setEstado(estado);

        repository.save(pedido);

        return construirRespuesta(pedido);
    }

    // ==========================================
    // BUSCAR PEDIDO EN LA BASE DE DATOS
    // ==========================================

    private Pedido buscarPedido(Long id) {

        return repository.findById(id)
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Pedido no encontrado"
                        )
                );
    }

    // ==========================================
    // CONSTRUIR RESPUESTA DEL PEDIDO
    // ==========================================

    private PedidoRespuestaDTO construirRespuesta(Pedido pedido) {

        List<DetallePedido> detalles = pedido.getDetalles();

        if (detalles == null || detalles.size() != 1) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Esta consulta requiere un pedido con un detalle"
            );
        }

        DetallePedido detalle = detalles.get(0);

        // Consultar la información del cliente.
        ClienteDTO cliente =
                clienteRetryService.obtenerCliente(
                        pedido.getIdCliente()
                );

        // Consultar el producto mediante Circuit Breaker.
        ProductoDTO producto =
                productoCircuitService.obtenerProducto(
                        detalle.getIdProducto()
                );

        return new PedidoRespuestaDTO(
                pedido.getIdPedido(),
                detalle.getCantidad(),
                pedido.getEstado(),
                cliente,
                producto
        );
    }
}
