package com.lab05.fernandez.service;

import com.lab05.fernandez.model.Producto;
import com.lab05.fernandez.repository.ProductoRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProductoService {

    private final ProductoRepository repo;


    public ProductoService(ProductoRepository repo) {
        this.repo = repo;
    }


    public List<Producto> listar(){
        return repo.findAll();
    }


    public Producto guardar(Producto producto){
        return repo.save(producto);
    }


    public Producto obtener(Long id){
        return repo.findById(id).orElse(null);
    }


    public void eliminar(Long id){
        repo.deleteById(id);
    }

    public List<Producto> buscarPorNombre(String nombre){
        return repo.findByNombreContainingIgnoreCase(nombre);
    }
}