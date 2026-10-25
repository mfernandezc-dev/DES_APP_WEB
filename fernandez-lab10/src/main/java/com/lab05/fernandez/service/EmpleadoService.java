
package com.lab05.fernandez.service;

import com.lab05.fernandez.empleados.model.Empleado;
import com.lab05.fernandez.empleados.repository.EmpleadoRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class EmpleadoService {

    private final EmpleadoRepository empleadoRepository;

    public EmpleadoService(EmpleadoRepository empleadoRepository) {
        this.empleadoRepository = empleadoRepository;
    }

    // Listar todos los empleados
    public List<Empleado> listar() {
        return empleadoRepository.findAll();
    }

    // Buscar empleado por ID
    public Optional<Empleado> buscarPorId(Long id) {
        return empleadoRepository.findById(id);
    }

    // Registrar empleado
    public Empleado registrar(Empleado empleado) {
        empleado.setId(null);
        return empleadoRepository.save(empleado);
    }

    // Actualizar empleado
    public Optional<Empleado> actualizar(Long id, Empleado datos) {
        return empleadoRepository.findById(id)
                .map(empleado -> {
                    empleado.setNombres(datos.getNombres());
                    empleado.setApellidos(datos.getApellidos());
                    empleado.setEmail(datos.getEmail());
                    empleado.setSueldo(datos.getSueldo());
                    return empleadoRepository.save(empleado);
                });
    }

    // Eliminar empleado
    public boolean eliminar(Long id) {
        if (!empleadoRepository.existsById(id)) {
            return false;
        }

        empleadoRepository.deleteById(id);
        return true;
    }
}
