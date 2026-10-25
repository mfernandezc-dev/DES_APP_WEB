
package com.lab05.fernandez.empleados.repository;

import com.lab05.fernandez.empleados.model.Empleado;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmpleadoRepository extends JpaRepository<Empleado, Long> {

}
