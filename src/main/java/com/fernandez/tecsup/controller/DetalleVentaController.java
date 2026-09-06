package com.fernandez.tecsup.controller;

import com.fernandez.tecsup.model.DetalleVenta;
import com.fernandez.tecsup.service.DetalleVentaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/detalle-ventas")
public class DetalleVentaController {
    @Autowired
    private DetalleVentaService service;

    @GetMapping
    public List<DetalleVenta> listar() { return service.listar(); }

    @PostMapping
    public ResponseEntity<DetalleVenta> guardar(@RequestBody DetalleVenta d) {
        return ResponseEntity.status(201).body(service.guardar(d));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DetalleVenta> obtener(@PathVariable Long id) {
        DetalleVenta d = service.obtener(id);
        return (d != null) ? ResponseEntity.ok(d) : ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<DetalleVenta> actualizar(
            @PathVariable Long id,
            @RequestBody DetalleVenta d) {

        DetalleVenta exist = service.obtener(id);

        if (exist == null)
            return ResponseEntity.notFound().build();

        exist.setVenta(d.getVenta());
        exist.setProducto(d.getProducto());
        exist.setCantidad(d.getCantidad());
        exist.setPrecio(d.getPrecio());
        exist.setSubtotal(d.getSubtotal());

        return ResponseEntity.ok(service.guardar(exist));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        DetalleVenta d = service.obtener(id);
        if (d == null) return ResponseEntity.notFound().build();
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}