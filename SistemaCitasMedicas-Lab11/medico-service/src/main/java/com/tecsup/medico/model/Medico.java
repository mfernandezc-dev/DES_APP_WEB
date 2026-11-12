package com.tecsup.medico.model;

import jakarta.persistence.*;
import java.time.*;

@Entity
@Table(name = "medico")
public class Medico {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_medico")
    private Integer idMedico;

    @Column(name = "cmp", unique = true, length = 20)
    private String cmp;

    @Column(name = "nombres", nullable = false, length = 100)
    private String nombres;

    @Column(name = "apellidos", nullable = false, length = 100)
    private String apellidos;

    @Column(name = "telefono", length = 15)
    private String telefono;

    @Column(name = "correo", length = 100)
    private String correo;

    @Column(name = "id_especialidad", nullable = false)
    private Integer idEspecialidad;

    @Column(name = "estado", length = 1)
    private String estado = "A";

    public Medico() {}

    public Integer getIdMedico() { return idMedico; }
    public void setIdMedico(Integer idMedico) { this.idMedico = idMedico; }

    public String getCmp() { return cmp; }
    public void setCmp(String cmp) { this.cmp = cmp; }

    public String getNombres() { return nombres; }
    public void setNombres(String nombres) { this.nombres = nombres; }

    public String getApellidos() { return apellidos; }
    public void setApellidos(String apellidos) { this.apellidos = apellidos; }

    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }

    public String getCorreo() { return correo; }
    public void setCorreo(String correo) { this.correo = correo; }

    public Integer getIdEspecialidad() { return idEspecialidad; }
    public void setIdEspecialidad(Integer idEspecialidad) { this.idEspecialidad = idEspecialidad; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

}
