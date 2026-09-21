package com.lab04.fernandez.repository;

import com.lab04.fernandez.model.Curso;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CursoRepository
        extends JpaRepository<Curso, Long> {

}