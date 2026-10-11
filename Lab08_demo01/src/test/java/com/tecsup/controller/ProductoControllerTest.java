package com.tecsup.controller;

import com.fasterxml.jackson.databind.ObjectMapper;

import com.tecsup.dto.ProductoDTO;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;

@SpringBootTest
@AutoConfigureMockMvc
public class ProductoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    // TEST POST
    @Test
    void testGuardarProducto() throws Exception {

        ProductoDTO dto = new ProductoDTO();
        dto.setNombre("Mouse");
        dto.setPrecio(80);
        dto.setStock(20);

        mockMvc.perform(post("/api/productos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.nombre").value("Mouse"));
    }

    // TEST GET
    @Test
    void testListarProductos() throws Exception {

        mockMvc.perform(get("/api/productos"))
                .andExpect(status().isOk());
    }

    // TEST VALIDACIÓN
    @Test
    void testValidacionNombreVacio() throws Exception {

        ProductoDTO dto = new ProductoDTO();
        dto.setNombre("");
        dto.setPrecio(10);
        dto.setStock(2);

        mockMvc.perform(post("/api/productos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isBadRequest());
    }

    // TEST PUT /api/productos/{id}
    @Test
    void testActualizarProducto() throws Exception {
        ProductoDTO dto = new ProductoDTO();
        dto.setNombre("Mouse Inalámbrico");
        dto.setPrecio(120);
        dto.setStock(15);

        mockMvc.perform(put("/api/productos/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isOk());
    }

    // TEST DELETE /api/productos/{id}
    @Test
    void testEliminarProducto() throws Exception {
        mockMvc.perform(delete("/api/productos/1"))
                .andExpect(status().isOk());
    }
}
