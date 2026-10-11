package com.tecsup.service;

import com.tecsup.model.Producto;
import com.tecsup.repository.ProductoRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;


public class ProductoServiceTest {

    @Mock
    private ProductoRepository repo;

    @InjectMocks
    private ProductoService service;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    // TEST LISTAR
    @Test
    void testListarProductos() {

        List<Producto> lista = List.of(
                new Producto(1L, "Monitor", 500, 10)
        );

        when(repo.findAll()).thenReturn(lista);

        List<Producto> resultado = service.listar();

        assertEquals(1, resultado.size());
        assertEquals("Monitor", resultado.get(0).getNombre());

        verify(repo, times(1)).findAll();
    }

    // TEST GUARDAR
    @Test
    void testGuardarProducto() {

        Producto producto = new Producto(1L, "Laptop", 3000, 5);

        when(repo.save(producto)).thenReturn(producto);

        Producto resultado = service.guardar(producto);

        assertNotNull(resultado);
        assertEquals("Laptop", resultado.getNombre());

        verify(repo).save(producto);
    }

    // TEST OBTENER
    @Test
    void testObtenerProducto() {

        Producto producto = new Producto(1L, "Teclado", 100, 20);

        when(repo.findById(1L)).thenReturn(Optional.of(producto));

        Producto resultado = service.obtener(1L);

        assertNotNull(resultado);
        assertEquals("Teclado", resultado.getNombre());

        verify(repo).findById(1L);
    }

    // TEST ELIMINAR
    @Test
    void testEliminarProducto() {

        doNothing().when(repo).deleteById(1L);

        service.eliminar(1L);

        verify(repo, times(1)).deleteById(1L);
    }

    // TEST ACTUALIZAR
    @Test
    void testActualizarProducto() {
        Producto producto = new Producto(1L, "Laptop Gamer", 3500, 8);
        when(repo.save(any(Producto.class))).thenReturn(producto);

        Producto resultado = service.actualizar(producto);

        assertNotNull(resultado);
        assertEquals("Laptop Gamer", resultado.getNombre());
        verify(repo, times(1)).save(producto);
    }

    // TEST OBTENER CUANDO NO EXISTE
    @Test
    void testObtenerProductoNoExiste() {
        when(repo.findById(99L)).thenReturn(Optional.empty());

        // Si tu servicio retorna null al no encontrar el producto:
        Producto resultado = service.obtener(99L);
        assertNull(resultado);

        verify(repo, times(1)).findById(99L);
    }
}