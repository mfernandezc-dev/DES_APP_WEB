package com.tecsup.medico.services;
import com.tecsup.medico.dto.MedicoDTO;
import com.tecsup.medico.model.*;
import com.tecsup.medico.repository.*;
import com.tecsup.medico.exception.RecursoNoEncontradoException;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class MedicoService {
    private final MedicoRepository medicos;
    private final EspecialidadRepository especialidades;
    private final HorarioMedicoRepository horarios;
    public MedicoService(MedicoRepository medicos, EspecialidadRepository especialidades, HorarioMedicoRepository horarios) {
        this.medicos = medicos; this.especialidades = especialidades; this.horarios = horarios;
    }
    public List<Medico> listar() { return medicos.findAll(); }
    public Medico obtener(Integer id) { return medicos.findById(id).orElseThrow(() -> new RecursoNoEncontradoException("Médico no encontrado: " + id)); }
    public Medico registrar(MedicoDTO dto) { return medicos.save(aplicar(new Medico(), dto)); }
    public Medico actualizar(Integer id, MedicoDTO dto) { return medicos.save(aplicar(obtener(id), dto)); }
    public void eliminar(Integer id) { medicos.delete(obtener(id)); }
    private Medico aplicar(Medico m, MedicoDTO dto) {
        if (!especialidades.existsById(dto.idEspecialidad())) throw new RecursoNoEncontradoException("Especialidad no encontrada: " + dto.idEspecialidad());
        m.setCmp(dto.cmp()); m.setNombres(dto.nombres()); m.setApellidos(dto.apellidos());
        m.setTelefono(dto.telefono()); m.setCorreo(dto.correo());
        m.setIdEspecialidad(dto.idEspecialidad()); m.setEstado(dto.estado() == null ? "A" : dto.estado());
        return m;
    }
    public List<Especialidad> listarEspecialidades() { return especialidades.findAll(); }
    public Especialidad guardarEspecialidad(Especialidad e) { e.setIdEspecialidad(null); return especialidades.save(e); }
    public List<HorarioMedico> listarHorarios() { return horarios.findAll(); }
    public HorarioMedico guardarHorario(HorarioMedico h) {
        obtener(h.getIdMedico());
        h.setIdHorario(null);
        return horarios.save(h);
    }
}
