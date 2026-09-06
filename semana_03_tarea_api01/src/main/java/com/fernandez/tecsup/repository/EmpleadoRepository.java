package com.fernandez.tecsup.repository;
import com.fernandez.tecsup.model.Empleado;
import org.springframework.data.jpa.repository.JpaRepository;
public interface EmpleadoRepository extends JpaRepository<Empleado, Long> {}