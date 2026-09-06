package com.fernandez.tecsup.service;

import com.fernandez.tecsup.model.Ventas;
import com.fernandez.tecsup.repository.VentasRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class VentasService {
    @Autowired
    private VentasRepository repo;

    public List<Ventas> listar() { return repo.findAll(); }
    public Ventas guardar(Ventas v) { return repo.save(v); }
    public Ventas obtener(Long id) { return repo.findById(id).orElse(null); }
    public void eliminar(Long id) { repo.deleteById(id); }
}