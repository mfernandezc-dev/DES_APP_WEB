
package com.lab05.fernandez;

import com.lab05.fernandez.empleados.model.Empleado;
import com.lab05.fernandez.empleados.repository.EmpleadoRepository;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@EntityScan(basePackageClasses = Empleado.class)
@EnableJpaRepositories(basePackageClasses = EmpleadoRepository.class)
public class FernandezApplication {

	public static void main(String[] args) {
		SpringApplication.run(FernandezApplication.class, args);
	}
}
