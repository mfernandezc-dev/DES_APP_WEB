package com.lab05.fernandez.controller;

import com.lab05.fernandez.dto.ProductoDTO;
import com.lab05.fernandez.model.Producto;
import com.lab05.fernandez.service.ProductoService;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/productos")
public class ProductoController {

    private final ProductoService service;

    public ProductoController(ProductoService service) {
        this.service = service;
    }

    // GET todos
    @GetMapping
    public ResponseEntity<List<Producto>> listar(){

        return ResponseEntity.ok(service.listar());
    }

    // POST
    @PostMapping
    public ResponseEntity<?> guardar(
            @Valid @RequestBody ProductoDTO dto){

        Producto producto = new Producto();
        producto.setNombre(dto.getNombre());
        producto.setPrecio(dto.getPrecio());
        producto.setStock(dto.getStock());

        return ResponseEntity
                .status(201)
                .body(service.guardar(producto));
    }

    // GET por ID
    @GetMapping("/{id}")
    public ResponseEntity<?> obtener(
            @PathVariable Long id){

        Producto producto = service.obtener(id);

        if(producto == null){

            return ResponseEntity
                    .status(404)
                    .body("Producto no encontrado");
        }

        return ResponseEntity.ok(producto);
    }

    @GetMapping("/buscar")
    public ResponseEntity<List<Producto>> buscar(
            @RequestParam String nombre){

        return ResponseEntity.ok(
                service.buscarPorNombre(nombre)
        );
    }

    // PUT
    @PutMapping("/{id}")
    public ResponseEntity<?> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody ProductoDTO dto){

        Producto producto = service.obtener(id);

        if(producto == null){

            return ResponseEntity
                    .status(404)
                    .body("Producto no existe");
        }

        producto.setNombre(dto.getNombre());
        producto.setPrecio(dto.getPrecio());
        producto.setStock(dto.getStock());

        return ResponseEntity.ok(
                service.guardar(producto)
        );
    }

    // DELETE
    @DeleteMapping("/{id}")
    public ResponseEntity<?> eliminar(
            @PathVariable Long id){

        Producto producto = service.obtener(id);

        if(producto == null){

            return ResponseEntity
                    .status(404)
                    .body("Producto no existe");
        }

        service.eliminar(id);

        return ResponseEntity.ok(
                "Producto eliminado correctamente"
        );
    }
}