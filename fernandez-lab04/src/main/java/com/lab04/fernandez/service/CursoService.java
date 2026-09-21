package com.lab04.fernandez.service;

import com.lab04.fernandez.model.Curso;
import com.lab04.fernandez.repository.CursoRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CursoService {
    private final CursoRepository cursoRepository;
    public CursoService(CursoRepository cursoRepository){
        this.cursoRepository = cursoRepository;
    }
    // Guardar curso
    public Curso guardar(Curso curso){
        return cursoRepository.save(curso);
    }
    // Listar cursos
    public List<Curso> listar(){
        return cursoRepository.findAll();
    }
    // Buscar curso
    public Curso buscarPorId(Long id){
        return cursoRepository.findById(id)
                .orElse(null);
    }
    // Eliminar curso
    public void eliminar(Long id){
        cursoRepository.deleteById(id);
    }

}