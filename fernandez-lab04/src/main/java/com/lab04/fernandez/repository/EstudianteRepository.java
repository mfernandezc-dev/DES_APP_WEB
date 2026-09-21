package com.lab04.fernandez.repository;

import com.lab04.fernandez.model.Estudiante;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EstudianteRepository
        extends JpaRepository<Estudiante, Long> {

}