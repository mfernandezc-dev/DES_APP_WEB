package com.tecsup.citas.model;

import jakarta.persistence.*;
import java.time.*;

@Entity
@Table(name = "atencion")
public class Atencion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_atencion")
    private Integer idAtencion;

    @Column(name = "id_cita", unique = true)
    private Integer idCita;

    @Column(name = "diagnostico", columnDefinition = "TEXT")
    private String diagnostico;

    @Column(name = "tratamiento", columnDefinition = "TEXT")
    private String tratamiento;

    @Column(name = "observaciones", columnDefinition = "TEXT")
    private String observaciones;

    @Column(name = "fecha_registro")
    private LocalDateTime fechaRegistro;

    public Atencion() {}

    public Integer getIdAtencion() { return idAtencion; }
    public void setIdAtencion(Integer idAtencion) { this.idAtencion = idAtencion; }

    public Integer getIdCita() { return idCita; }
    public void setIdCita(Integer idCita) { this.idCita = idCita; }

    public String getDiagnostico() { return diagnostico; }
    public void setDiagnostico(String diagnostico) { this.diagnostico = diagnostico; }

    public String getTratamiento() { return tratamiento; }
    public void setTratamiento(String tratamiento) { this.tratamiento = tratamiento; }

    public String getObservaciones() { return observaciones; }
    public void setObservaciones(String observaciones) { this.observaciones = observaciones; }

    public LocalDateTime getFechaRegistro() { return fechaRegistro; }
    public void setFechaRegistro(LocalDateTime fechaRegistro) { this.fechaRegistro = fechaRegistro; }

}
