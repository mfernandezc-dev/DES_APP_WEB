package com.tecsup.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ClienteDTO(Long id, String nombre, String apellido) {
}
