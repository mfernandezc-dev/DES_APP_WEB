package com.lab04.fernandez.service;

import com.lab04.fernandez.model.Curso;
import com.lab04.fernandez.model.Estudiante;
import com.lab04.fernandez.repository.CursoRepository;
import com.lab04.fernandez.repository.EstudianteRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class EstudianteService {

    private final EstudianteRepository estudianteRepository;
    private final CursoRepository cursoRepository;

    public EstudianteService(
            EstudianteRepository estudianteRepository,
            CursoRepository cursoRepository
    ) {
        this.estudianteRepository = estudianteRepository;
        this.cursoRepository = cursoRepository;
    }

    // Crear estudiante con cursos
    public Estudiante guardar(Estudiante estudiante) {
        return estudianteRepository.save(estudiante);
    }

    // Listar estudiantes
    public List<Estudiante> listar() {
        return estudianteRepository.findAll();
    }

    // Buscar estudiante por ID
    public Estudiante buscarPorId(Long id) {
        return estudianteRepository.findById(id)
                .orElse(null);
    }
    // Agregar curso a estudiante
    public Estudiante agregarCurso(Long estudianteId, Long cursoId) {

        Estudiante estudiante = estudianteRepository.findById(estudianteId)
                .orElse(null);

        Curso curso = cursoRepository.findById(cursoId)
                .orElse(null);

        if(estudiante != null && curso != null){

            // Evita duplicados porque usamos Set
            estudiante.getCursos().add(curso);
            return estudianteRepository.save(estudiante);
        }
        return null;
    }

    // Quitar curso de estudiante
    public Estudiante quitarCurso(Long estudianteId, Long cursoId) {

        Estudiante estudiante = estudianteRepository.findById(estudianteId)
                .orElse(null);
        if(estudiante != null){
            estudiante.getCursos()
                    .removeIf(curso -> curso.getId().equals(cursoId));
            return estudianteRepository.save(estudiante);
        }
        return null;
    }
    // Listar cursos de un estudiante
    public List<Curso> listarCursos(Long estudianteId){

        Estudiante estudiante = estudianteRepository.findById(estudianteId)
                .orElse(null);
        if(estudiante != null){
            return estudiante.getCursos()
                    .stream()
                    .toList();
        }
        return null;
    }

    // Eliminar estudiante
    public void eliminar(Long id){
        estudianteRepository.deleteById(id);
    }
}