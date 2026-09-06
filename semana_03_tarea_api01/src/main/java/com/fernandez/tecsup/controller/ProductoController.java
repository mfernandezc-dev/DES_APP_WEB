package com.fernandez.tecsup.controller;

import com.fernandez.tecsup.model.Producto;
import com.fernandez.tecsup.service.ProductoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/productos")
public class ProductoController {
    @Autowired
    private ProductoService service;

    @GetMapping
    public List<Producto> listar() { return service.listar(); }

    @PostMapping
    public ResponseEntity<Producto> guardar(@RequestBody Producto p) {
        return ResponseEntity.status(201).body(service.guardar(p));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Producto> obtener(@PathVariable Long id) {
        Producto p = service.obtener(id);
        return (p != null) ? ResponseEntity.ok(p) : ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<Producto> actualizar(@PathVariable Long id, @RequestBody Producto p) {
        Producto exist = service.obtener(id);
        if (exist == null) return ResponseEntity.notFound().build();
        exist.setNombre(p.getNombre());
        exist.setDescripcion(p.getDescripcion());
        exist.setPrecio(p.getPrecio());
        exist.setStock(p.getStock());
        exist.setCategoria(p.getCategoria());
        return ResponseEntity.ok(service.guardar(exist));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        Producto p = service.obtener(id);
        if (p == null) return ResponseEntity.notFound().build();
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}