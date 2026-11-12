package com.tecsup.citas.dto;
import jakarta.validation.constraints.*;
import java.time.*;
public record CitaDTO(
    @NotNull LocalDate fecha,
    @NotNull LocalTime hora,
    @NotNull Integer idPaciente,
    @NotNull Integer idMedico,
    @Size(max=300) String motivo
) {}
