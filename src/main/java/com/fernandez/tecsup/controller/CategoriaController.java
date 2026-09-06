package com.fernandez.tecsup.controller;

import com.fernandez.tecsup.model.Categoria;
import com.fernandez.tecsup.service.CategoriaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/categorias")
public class CategoriaController {
    @Autowired
    private CategoriaService service;

    @GetMapping
    public List<Categoria> listar() { return service.listar(); }

    @PostMapping
    public ResponseEntity<Categoria> guardar(@RequestBody Categoria c) {
        return ResponseEntity.status(201).body(service.guardar(c));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Categoria> obtener(@PathVariable Long id) {
        Categoria c = service.obtener(id);
        return (c != null) ? ResponseEntity.ok(c) : ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<Categoria> actualizar(@PathVariable Long id, @RequestBody Categoria c) {
        Categoria exist = service.obtener(id);
        if (exist == null) return ResponseEntity.notFound().build();
        exist.setNombre(c.getNombre());
        exist.setDescripcion(c.getDescripcion());
        return ResponseEntity.ok(service.guardar(exist));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        Categoria c = service.obtener(id);
        if (c == null) return ResponseEntity.notFound().build();
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}