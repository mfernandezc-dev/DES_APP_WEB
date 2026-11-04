
package com.veterinaria.consulta.controller;

import com.veterinaria.consulta.dto.ConsultaDTO;
import com.veterinaria.consulta.model.Consulta;
import com.veterinaria.consulta.services.ConsultaService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/consultas")
public class ConsultaController {

    private final ConsultaService consultaService;

    public ConsultaController(ConsultaService consultaService) {
        this.consultaService = consultaService;
    }

    // GET - LISTAR TODAS
    @GetMapping
    public ResponseEntity<List<Consulta>> listar() {

        return ResponseEntity.ok(
                consultaService.listar()
        );
    }

    // GET - BUSCAR POR ID
    @GetMapping("/{id}")
    public ResponseEntity<Consulta> buscarPorId(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                consultaService.buscarPorId(id)
        );
    }

    // GET - CONSULTAS POR MASCOTA
    @GetMapping("/mascota/{idMascota}")
    public ResponseEntity<List<Consulta>> listarPorMascota(
            @PathVariable Long idMascota) {

        return ResponseEntity.ok(
                consultaService.listarPorMascota(idMascota)
        );
    }

    // POST - REGISTRAR
    @PostMapping
    public ResponseEntity<Consulta> registrar(
            @Valid @RequestBody ConsultaDTO dto) {

        Consulta consulta = consultaService.registrar(dto);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(consulta);
    }

    // PUT - ACTUALIZAR
    @PutMapping("/{id}")
    public ResponseEntity<Consulta> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody ConsultaDTO dto) {

        return ResponseEntity.ok(
                consultaService.actualizar(id, dto)
        );
    }

    // DELETE - ELIMINAR
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(
            @PathVariable Long id) {

        consultaService.eliminar(id);

        return ResponseEntity.noContent().build();
    }
}
