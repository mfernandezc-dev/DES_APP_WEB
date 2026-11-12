package com.tecsup.paciente.services;
import com.tecsup.paciente.model.Paciente;
import com.tecsup.paciente.dto.PacienteDTO;
import com.tecsup.paciente.repository.PacienteRepository;
import com.tecsup.paciente.exception.RecursoNoEncontradoException;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class PacienteService {
    private final PacienteRepository repo;
    public PacienteService(PacienteRepository repo) { this.repo = repo; }
    public List<Paciente> listar() { return repo.findAll(); }
    public Paciente obtener(Integer id) {
        return repo.findById(id).orElseThrow(() -> new RecursoNoEncontradoException("Paciente no encontrado: " + id));
    }
    public Paciente registrar(PacienteDTO dto) { return repo.save(aplicar(new Paciente(), dto)); }
    public Paciente actualizar(Integer id, PacienteDTO dto) { return repo.save(aplicar(obtener(id), dto)); }
    public void eliminar(Integer id) { repo.delete(obtener(id)); }
    private Paciente aplicar(Paciente p, PacienteDTO d) {
        p.setDni(d.dni()); p.setNombres(d.nombres()); p.setApellidos(d.apellidos());
        p.setFechaNacimiento(d.fechaNacimiento()); p.setSexo(d.sexo());
        p.setTelefono(d.telefono()); p.setDireccion(d.direccion()); p.setCorreo(d.correo());
        p.setEstado(d.estado() == null ? "A" : d.estado());
        return p;
    }
}
