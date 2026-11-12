package com.tecsup.citas.controller;
import com.tecsup.citas.dto.*;
import com.tecsup.citas.model.*;
import com.tecsup.citas.services.CitaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
public class CitaController {
    private final CitaService service;
    public CitaController(CitaService service) { this.service = service; }
    @GetMapping("/api/citas") public List<Cita> listar() { return service.listar(); }
    @GetMapping("/api/citas/{id}") public Cita obtener(@PathVariable Integer id) { return service.obtener(id); }
    @PostMapping("/api/citas") @ResponseStatus(HttpStatus.CREATED)
    public Cita registrar(@Valid @RequestBody CitaDTO dto) { return service.registrar(dto); }
    @PatchMapping("/api/citas/{id}/estado")
    public Cita cambiarEstado(@PathVariable Integer id, @Valid @RequestBody EstadoCitaDTO dto) {
        return service.cambiarEstado(id, dto);
    }
    @PatchMapping("/api/citas/{id}/cancelar")
    public Cita cancelar(@PathVariable Integer id) { return service.cancelar(id); }
    @GetMapping("/api/atenciones") public List<Atencion> atenciones() { return service.listarAtenciones(); }
    @PostMapping("/api/atenciones") @ResponseStatus(HttpStatus.CREATED)
    public Atencion registrarAtencion(@Valid @RequestBody AtencionDTO dto) { return service.registrarAtencion(dto); }
}
