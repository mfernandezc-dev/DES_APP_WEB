
package com.tecsup.services;

import com.tecsup.dto.CategoriaDTO;
import com.tecsup.model.Producto;
import com.tecsup.repository.ProductoRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProductoService {

    private final ProductoRepository repo;
    private final CategoriaCircuitService categoriaCircuitService;

    public ProductoService(
            ProductoRepository repo,
            CategoriaCircuitService categoriaCircuitService) {

        this.repo = repo;
        this.categoriaCircuitService = categoriaCircuitService;
    }

    // LISTAR PRODUCTOS
    public List<Producto> listar() {

        List<Producto> productos = repo.findAll();

        productos.forEach(p -> {
            CategoriaDTO categoria =
                    categoriaCircuitService.obtenerCategoria(
                            p.getCategoriaId()
                    );

            p.setCategoria(categoria);
        });

        return productos;
    }

    // GUARDAR PRODUCTO
    public Producto guardar(Producto p) {

        Producto producto = repo.save(p);

        CategoriaDTO categoria =
                categoriaCircuitService.obtenerCategoria(
                        producto.getCategoriaId()
                );

        producto.setCategoria(categoria);

        return producto;
    }

    // BUSCAR PRODUCTO POR ID
    public Producto obtener(Long id) {

        Producto producto = repo.findById(id)
                .orElse(null);

        if (producto != null) {

            CategoriaDTO categoria =
                    categoriaCircuitService.obtenerCategoria(
                            producto.getCategoriaId()
                    );

            producto.setCategoria(categoria);
        }

        return producto;
    }

    // ELIMINAR PRODUCTO
    public void eliminar(Long id) {
        repo.deleteById(id);
    }
}
