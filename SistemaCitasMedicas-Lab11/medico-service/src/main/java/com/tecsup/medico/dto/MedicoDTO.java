package com.tecsup.medico.dto;
import jakarta.validation.constraints.*;
public record MedicoDTO(
    @Size(max=20) String cmp,
    @NotBlank @Size(max=100) String nombres,
    @NotBlank @Size(max=100) String apellidos,
    @Size(max=15) String telefono,
    @Email @Size(max=100) String correo,
    @NotNull Integer idEspecialidad,
    @Pattern(regexp="[AI]", message="Estado debe ser A o I") String estado
) {}
