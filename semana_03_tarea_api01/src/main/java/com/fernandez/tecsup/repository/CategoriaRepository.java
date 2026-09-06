package com.fernandez.tecsup.repository;
import com.fernandez.tecsup.model.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
public interface CategoriaRepository extends JpaRepository<Categoria, Long> {}