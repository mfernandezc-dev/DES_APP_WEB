package com.tecsup.medico.controller;
import com.tecsup.medico.dto.MedicoDTO;
import com.tecsup.medico.model.*;
import com.tecsup.medico.services.MedicoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
public class MedicoController {
    private final MedicoService service;
    public MedicoController(MedicoService service) { this.service = service; }
    @GetMapping("/api/medicos") public List<Medico> listar() { return service.listar(); }
    @GetMapping("/api/medicos/{id}") public Medico obtener(@PathVariable Integer id) { return service.obtener(id); }
    @PostMapping("/api/medicos") @ResponseStatus(HttpStatus.CREATED)
    public Medico registrar(@Valid @RequestBody MedicoDTO dto) { return service.registrar(dto); }
    @PutMapping("/api/medicos/{id}")
    public Medico actualizar(@PathVariable Integer id, @Valid @RequestBody MedicoDTO dto) { return service.actualizar(id, dto); }
    @DeleteMapping("/api/medicos/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Integer id) { service.eliminar(id); }
    @GetMapping("/api/especialidades") public List<Especialidad> especialidades() { return service.listarEspecialidades(); }
    @PostMapping("/api/especialidades") @ResponseStatus(HttpStatus.CREATED)
    public Especialidad crearEspecialidad(@RequestBody Especialidad e) { return service.guardarEspecialidad(e); }
    @GetMapping("/api/horarios") public List<HorarioMedico> horarios() { return service.listarHorarios(); }
    @PostMapping("/api/horarios") @ResponseStatus(HttpStatus.CREATED)
    public HorarioMedico crearHorario(@RequestBody HorarioMedico h) { return service.guardarHorario(h); }
}
