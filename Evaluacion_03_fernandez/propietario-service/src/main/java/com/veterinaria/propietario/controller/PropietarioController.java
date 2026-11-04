
package com.veterinaria.propietario.controller;

import com.veterinaria.propietario.dto.PropietarioDTO;
import com.veterinaria.propietario.model.Propietario;
import com.veterinaria.propietario.services.PropietarioService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/propietarios")
public class PropietarioController {

    private final PropietarioService propietarioService;

    public PropietarioController(
            PropietarioService propietarioService) {
        this.propietarioService = propietarioService;
    }

    // GET - LISTAR TODOS
    @GetMapping
    public ResponseEntity<List<Propietario>> listar() {

        return ResponseEntity.ok(
                propietarioService.listar()
        );
    }

    // GET - BUSCAR POR ID
    @GetMapping("/{id}")
    public ResponseEntity<Propietario> buscarPorId(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                propietarioService.buscarPorId(id)
        );
    }

    // POST - REGISTRAR
    @PostMapping
    public ResponseEntity<Propietario> registrar(
            @Valid @RequestBody PropietarioDTO dto) {

        Propietario propietario = propietarioService.registrar(dto);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(propietario);
    }

    // PUT - ACTUALIZAR
    @PutMapping("/{id}")
    public ResponseEntity<Propietario> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody PropietarioDTO dto) {

        return ResponseEntity.ok(
                propietarioService.actualizar(id, dto)
        );
    }

    // DELETE - ELIMINAR
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(
            @PathVariable Long id) {

        propietarioService.eliminar(id);

        return ResponseEntity.noContent().build();
    }
}
