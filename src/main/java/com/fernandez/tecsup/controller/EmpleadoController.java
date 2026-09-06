package com.fernandez.tecsup.controller;

import com.fernandez.tecsup.model.Empleado;
import com.fernandez.tecsup.service.EmpleadoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/empleados")
public class EmpleadoController {
    @Autowired
    private EmpleadoService service;

    @GetMapping
    public List<Empleado> listar() { return service.listar(); }

    @PostMapping
    public ResponseEntity<Empleado> guardar(@RequestBody Empleado e) {
        return ResponseEntity.status(201).body(service.guardar(e));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Empleado> obtener(@PathVariable Long id) {
        Empleado e = service.obtener(id);
        return (e != null) ? ResponseEntity.ok(e) : ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<Empleado> actualizar(@PathVariable Long id, @RequestBody Empleado e) {
        Empleado exist = service.obtener(id);
        if (exist == null) return ResponseEntity.notFound().build();
        exist.setNombre(e.getNombre());
        exist.setApellido(e.getApellido());
        exist.setCargo(e.getCargo());
        exist.setTelefono(e.getTelefono());
        return ResponseEntity.ok(service.guardar(exist));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        Empleado e = service.obtener(id);
        if (e == null) return ResponseEntity.notFound().build();
        service.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}