package com.tecsup.citas.dto;
import jakarta.validation.constraints.*;
public record AtencionDTO(
    @NotNull Integer idCita,
    String diagnostico,
    String tratamiento,
    String observaciones
) {}
