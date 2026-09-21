package com.lab04.fernandez.repository;

import com.lab04.fernandez.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

}