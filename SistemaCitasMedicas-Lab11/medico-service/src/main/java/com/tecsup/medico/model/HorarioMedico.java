package com.tecsup.medico.model;

import jakarta.persistence.*;
import java.time.*;

@Entity
@Table(name = "horario_medico")
public class HorarioMedico {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_horario")
    private Integer idHorario;

    @Column(name = "id_medico", nullable = false)
    private Integer idMedico;

    @Column(name = "dia_semana", length = 15)
    private String diaSemana;

    @Column(name = "hora_inicio")
    private LocalTime horaInicio;

    @Column(name = "hora_fin")
    private LocalTime horaFin;

    public HorarioMedico() {}

    public Integer getIdHorario() { return idHorario; }
    public void setIdHorario(Integer idHorario) { this.idHorario = idHorario; }

    public Integer getIdMedico() { return idMedico; }
    public void setIdMedico(Integer idMedico) { this.idMedico = idMedico; }

    public String getDiaSemana() { return diaSemana; }
    public void setDiaSemana(String diaSemana) { this.diaSemana = diaSemana; }

    public LocalTime getHoraInicio() { return horaInicio; }
    public void setHoraInicio(LocalTime horaInicio) { this.horaInicio = horaInicio; }

    public LocalTime getHoraFin() { return horaFin; }
    public void setHoraFin(LocalTime horaFin) { this.horaFin = horaFin; }

}
