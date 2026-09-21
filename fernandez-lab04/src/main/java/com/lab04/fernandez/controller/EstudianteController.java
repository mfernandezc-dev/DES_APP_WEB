package com.lab04.fernandez.controller;

import com.lab04.fernandez.model.Curso;
import com.lab04.fernandez.model.Estudiante;
import com.lab04.fernandez.service.EstudianteService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/estudiantes")
public class EstudianteController {


    private final EstudianteService estudianteService;


    public EstudianteController(EstudianteService estudianteService) {
        this.estudianteService = estudianteService;
    }


    // 1. Crear estudiante con cursos
    @PostMapping
    public Estudiante crear(@RequestBody Estudiante estudiante) {

        return estudianteService.guardar(estudiante);
    }


    // 2. Listar estudiantes con sus cursos
    @GetMapping
    public List<Estudiante> listar() {

        return estudianteService.listar();
    }


    // 3. Obtener estudiante por ID
    @GetMapping("/{id}")
    public ResponseEntity<Estudiante> obtenerPorId(
            @PathVariable Long id) {


        Estudiante estudiante = estudianteService.buscarPorId(id);


        if (estudiante == null) {
            return ResponseEntity.notFound().build();
        }


        return ResponseEntity.ok(estudiante);
    }



    // 4. Agregar curso a estudiante existente
    @PostMapping("/{estudianteId}/cursos/{cursoId}")
    public ResponseEntity<Estudiante> agregarCurso(
            @PathVariable Long estudianteId,
            @PathVariable Long cursoId) {


        Estudiante estudiante =
                estudianteService.agregarCurso(estudianteId, cursoId);


        if (estudiante == null) {
            return ResponseEntity.notFound().build();
        }


        return ResponseEntity.ok(estudiante);
    }



    // 5. Quitar curso de estudiante
    @DeleteMapping("/{estudianteId}/cursos/{cursoId}")
    public ResponseEntity<Estudiante> quitarCurso(
            @PathVariable Long estudianteId,
            @PathVariable Long cursoId) {


        Estudiante estudiante =
                estudianteService.quitarCurso(estudianteId, cursoId);


        if (estudiante == null) {
            return ResponseEntity.notFound().build();
        }


        return ResponseEntity.ok(estudiante);
    }



    // 6. Listar cursos de un estudiante
    @GetMapping("/{id}/cursos")
    public ResponseEntity<List<Curso>> listarCursos(
            @PathVariable Long id) {


        List<Curso> cursos =
                estudianteService.listarCursos(id);


        if (cursos == null) {
            return ResponseEntity.notFound().build();
        }


        return ResponseEntity.ok(cursos);
    }



    // Eliminar estudiante
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(
            @PathVariable Long id) {


        estudianteService.eliminar(id);

        return ResponseEntity.noContent().build();
    }

}