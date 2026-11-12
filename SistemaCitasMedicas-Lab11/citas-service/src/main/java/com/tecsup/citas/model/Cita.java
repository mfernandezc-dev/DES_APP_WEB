package com.tecsup.citas.model;

import jakarta.persistence.*;
import java.time.*;

@Entity
@Table(name = "cita")
public class Cita {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cita")
    private Integer idCita;

    @Column(name = "fecha", nullable = false)
    private LocalDate fecha;

    @Column(name = "hora", nullable = false)
    private LocalTime hora;

    @Column(name = "id_paciente", nullable = false)
    private Integer idPaciente;

    @Column(name = "id_medico", nullable = false)
    private Integer idMedico;

    @Column(name = "motivo", length = 300)
    private String motivo;

    @Column(name = "estado", length = 20)
    private String estado = "PROGRAMADA";

    public Cita() {}

    public Integer getIdCita() { return idCita; }
    public void setIdCita(Integer idCita) { this.idCita = idCita; }

    public LocalDate getFecha() { return fecha; }
    public void setFecha(LocalDate fecha) { this.fecha = fecha; }

    public LocalTime getHora() { return hora; }
    public void setHora(LocalTime hora) { this.hora = hora; }

    public Integer getIdPaciente() { return idPaciente; }
    public void setIdPaciente(Integer idPaciente) { this.idPaciente = idPaciente; }

    public Integer getIdMedico() { return idMedico; }
    public void setIdMedico(Integer idMedico) { this.idMedico = idMedico; }

    public String getMotivo() { return motivo; }
    public void setMotivo(String motivo) { this.motivo = motivo; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

}
