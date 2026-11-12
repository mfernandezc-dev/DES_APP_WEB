package com.tecsup.paciente.dto;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
public record PacienteDTO(
    @Size(max=8) @Pattern(regexp="[0-9]{8}", message="DNI debe contener 8 dígitos") String dni,
    @NotBlank @Size(max=100) String nombres,
    @NotBlank @Size(max=100) String apellidos,
    LocalDate fechaNacimiento,
    @Pattern(regexp="[MF]", message="Sexo debe ser M o F") String sexo,
    @Size(max=15) String telefono,
    @Size(max=200) String direccion,
    @Email @Size(max=100) String correo,
    @Pattern(regexp="[AI]", message="Estado debe ser A o I") String estado
) {}
