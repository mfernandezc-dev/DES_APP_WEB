
package com.veterinaria.mascota.controller;

import com.veterinaria.mascota.dto.MascotaDTO;
import com.veterinaria.mascota.model.Mascota;
import com.veterinaria.mascota.services.MascotaService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/mascotas")
public class MascotaController {

    private final MascotaService mascotaService;

    public MascotaController(MascotaService mascotaService) {
        this.mascotaService = mascotaService;
    }

    // GET - LISTAR TODAS
    @GetMapping
    public ResponseEntity<List<Mascota>> listar() {

        return ResponseEntity.ok(
                mascotaService.listar()
        );
    }

    // GET - BUSCAR POR ID
    @GetMapping("/{id}")
    public ResponseEntity<Mascota> buscarPorId(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                mascotaService.buscarPorId(id)
        );
    }

    // GET - MASCOTAS POR PROPIETARIO
    @GetMapping("/propietario/{idPropietario}")
    public ResponseEntity<List<Mascota>> listarPorPropietario(
            @PathVariable Long idPropietario) {

        return ResponseEntity.ok(
                mascotaService.listarPorPropietario(idPropietario)
        );
    }

    // POST - REGISTRAR
    @PostMapping
    public ResponseEntity<Mascota> registrar(
            @Valid @RequestBody MascotaDTO dto) {

        Mascota mascota = mascotaService.registrar(dto);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(mascota);
    }

    // PUT - ACTUALIZAR
    @PutMapping("/{id}")
    public ResponseEntity<Mascota> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody MascotaDTO dto) {

        return ResponseEntity.ok(
                mascotaService.actualizar(id, dto)
        );
    }

    // DELETE - ELIMINAR
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(
            @PathVariable Long id) {

        mascotaService.eliminar(id);

        return ResponseEntity.noContent().build();
    }
}
