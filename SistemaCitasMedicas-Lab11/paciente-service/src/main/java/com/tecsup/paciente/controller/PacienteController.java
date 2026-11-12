package com.tecsup.paciente.controller;
import com.tecsup.paciente.model.Paciente;
import com.tecsup.paciente.dto.PacienteDTO;
import com.tecsup.paciente.services.PacienteService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/pacientes")
public class PacienteController {
    private final PacienteService service;
    public PacienteController(PacienteService service) { this.service = service; }
    @GetMapping public List<Paciente> listar() { return service.listar(); }
    @GetMapping("/{id}") public Paciente obtener(@PathVariable Integer id) { return service.obtener(id); }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public Paciente registrar(@Valid @RequestBody PacienteDTO dto) { return service.registrar(dto); }
    @PutMapping("/{id}") public Paciente actualizar(@PathVariable Integer id, @Valid @RequestBody PacienteDTO dto) {
        return service.actualizar(id, dto);
    }
    @DeleteMapping("/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Integer id) { service.eliminar(id); }
}
