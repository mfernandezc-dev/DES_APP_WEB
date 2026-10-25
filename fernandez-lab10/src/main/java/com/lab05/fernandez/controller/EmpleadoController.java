
package com.lab05.fernandez.controller;

import com.lab05.fernandez.empleados.model.Empleado;
import com.lab05.fernandez.service.EmpleadoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/empleados")
public class EmpleadoController {

    private final EmpleadoService empleadoService;

    public EmpleadoController(EmpleadoService empleadoService) {
        this.empleadoService = empleadoService;
    }

    // GET: Listar todos los empleados
    @GetMapping
    public List<Empleado> listar() {
        return empleadoService.listar();
    }

    // GET: Buscar empleado por ID
    @GetMapping("/{id}")
    public ResponseEntity<Empleado> buscarPorId(@PathVariable Long id) {
        return empleadoService.buscarPorId(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // POST: Registrar un empleado
    @PostMapping
    public ResponseEntity<Empleado> registrar(@RequestBody Empleado empleado) {
        Empleado nuevo = empleadoService.registrar(empleado);
        return ResponseEntity.status(HttpStatus.CREATED).body(nuevo);
    }

    // PUT: Actualizar un empleado
    @PutMapping("/{id}")
    public ResponseEntity<Empleado> actualizar(
            @PathVariable Long id,
            @RequestBody Empleado datos) {

        return empleadoService.actualizar(id, datos)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // DELETE: Eliminar un empleado
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        if (empleadoService.eliminar(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
