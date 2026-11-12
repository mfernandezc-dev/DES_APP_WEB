package com.tecsup.citas.services;
import com.tecsup.citas.dto.*;
import com.tecsup.citas.model.*;
import com.tecsup.citas.repository.*;
import com.tecsup.citas.exception.RecursoNoEncontradoException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

@Service
public class CitaService {
    private final CitaRepository citas;
    private final AtencionRepository atenciones;
    private final RestClient client;
    private final String pacientesUrl;
    private final String medicosUrl;

    public CitaService(CitaRepository citas, AtencionRepository atenciones,
                       @Value("${servicios.pacientes.url}") String pacientesUrl,
                       @Value("${servicios.medicos.url}") String medicosUrl) {
        this.citas = citas; this.atenciones = atenciones;
        this.pacientesUrl = pacientesUrl; this.medicosUrl = medicosUrl;
        this.client = RestClient.create();
    }
    public List<Cita> listar() { return citas.findAll(); }
    public Cita obtener(Integer id) { return citas.findById(id).orElseThrow(() -> new RecursoNoEncontradoException("Cita no encontrada: " + id)); }
    public Cita registrar(CitaDTO dto) {
        validarRemoto(pacientesUrl, dto.idPaciente(), "Paciente");
        validarRemoto(medicosUrl, dto.idMedico(), "Médico");
        Cita c = new Cita();
        c.setFecha(dto.fecha()); c.setHora(dto.hora());
        c.setIdPaciente(dto.idPaciente()); c.setIdMedico(dto.idMedico());
        c.setMotivo(dto.motivo()); c.setEstado("PROGRAMADA");
        return citas.save(c);
    }
    public Cita cambiarEstado(Integer id, EstadoCitaDTO dto) {
        String estado = dto.estado().trim().toUpperCase();
        if (!Set.of("PROGRAMADA", "CONFIRMADA", "ATENDIDA", "CANCELADA").contains(estado))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Estado inválido");
        Cita cita = obtener(id);
        cita.setEstado(estado);
        return citas.save(cita);
    }
    public Cita cancelar(Integer id) { return cambiarEstado(id, new EstadoCitaDTO("CANCELADA")); }
    private void validarRemoto(String baseUrl, Integer id, String tipo) {
        try {
            client.get().uri(baseUrl + "/" + id).retrieve().toBodilessEntity();
        } catch (RestClientResponseException ex) {
            if (ex.getStatusCode().value() == 404) throw new RecursoNoEncontradoException(tipo + " no encontrado: " + id);
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Error al consultar servicio de " + tipo);
        } catch (ResourceAccessException ex) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Servicio de " + tipo + " no disponible");
        }
    }
    public List<Atencion> listarAtenciones() { return atenciones.findAll(); }
    public Atencion registrarAtencion(AtencionDTO dto) {
        obtener(dto.idCita());
        Atencion a = new Atencion();
        a.setIdCita(dto.idCita()); a.setDiagnostico(dto.diagnostico());
        a.setTratamiento(dto.tratamiento()); a.setObservaciones(dto.observaciones());
        a.setFechaRegistro(LocalDateTime.now());
        return atenciones.save(a);
    }
}
