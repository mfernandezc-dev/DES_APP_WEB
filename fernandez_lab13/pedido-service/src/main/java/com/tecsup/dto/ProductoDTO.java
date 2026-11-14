package com.tecsup.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ProductoDTO(Long id, String nombre, Double precio) {
}
