package com.fernandez.tecsup.service;

import com.fernandez.tecsup.model.Categoria;
import com.fernandez.tecsup.repository.CategoriaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class CategoriaService {
    @Autowired
    private CategoriaRepository repo;

    public List<Categoria> listar() { return repo.findAll(); }
    public Categoria guardar(Categoria c) { return repo.save(c); }
    public Categoria obtener(Long id) { return repo.findById(id).orElse(null); }
    public void eliminar(Long id) { repo.deleteById(id); }
}