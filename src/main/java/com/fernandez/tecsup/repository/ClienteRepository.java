package com.fernandez.tecsup.repository;
import com.fernandez.tecsup.model.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;
public interface ClienteRepository extends JpaRepository<Cliente, Long> {}