package com.tecsup.service;

import com.tecsup.exception.ResourceNotFoundException;
import com.tecsup.model.Categoria;
import com.tecsup.repository.CategoriaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CategoriaService {

    @Autowired
    private CategoriaRepository repo;

    public List<Categoria> listar() {
        return repo.findAll();
    }

    public Categoria guardar(Categoria categoria) {
        return repo.save(categoria);
    }

    public Categoria obtener(Long id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Categoría no encontrada con ID: " + id));
    }

    public Categoria actualizar(Categoria categoria) {
        obtener(categoria.getId());
        return repo.save(categoria);
    }

    public void eliminar(Long id) {
        obtener(id);
        repo.deleteById(id);
    }
}