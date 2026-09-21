package com.lab04.fernandez.controller;

import com.lab04.fernandez.model.Curso;
import com.lab04.fernandez.service.CursoService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/cursos")
public class CursoController {


    private final CursoService cursoService;


    public CursoController(CursoService cursoService){
        this.cursoService = cursoService;
    }


    @PostMapping
    public Curso guardar(@RequestBody Curso curso){
        return cursoService.guardar(curso);
    }


    @GetMapping
    public List<Curso> listar(){
        return cursoService.listar();
    }
}