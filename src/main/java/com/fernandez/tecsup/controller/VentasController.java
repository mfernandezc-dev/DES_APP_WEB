package com.fernandez.tecsup.controller;

import com.fernandez.tecsup.model.Ventas;
import com.fernandez.tecsup.service.VentasService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/ventas")
public class VentasController {
    @Autowired
    private VentasService service;

    @GetMapping
    public List<Ventas> listar() { return service.listar(); }

    @PostMapping
    public ResponseEntity<Ventas> guardar(@RequestBody Ventas v) {
        return ResponseEntity.status(201).body(service.guardar(v));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Ventas> obtener(@PathVariable Long id) {
        Ventas v = service.obtener(id);
        return (v != null) ? ResponseEntity.ok(v) : ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<Ventas> actualizar(@PathVariable Long id, @RequestBody Ventas v) {

        Ventas exist = service.obtener(id);

        if (exist == null)
            return ResponseEntity.notFound().build();

        exist.setFecha(v.getFecha());
        exist.setTotal(v.getTotal());
        exist.setCliente(v.getCliente());
        exist.setEmpleado(v.getEmpleado());

        return ResponseEntity.ok(service.guardar(exist));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        Ventas v = service.obtener(id);
        if (v == null) return ResponseEntity.notFound().build();
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}