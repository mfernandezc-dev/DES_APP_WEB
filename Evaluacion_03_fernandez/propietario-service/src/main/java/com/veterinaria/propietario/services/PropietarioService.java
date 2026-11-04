
package com.veterinaria.propietario.services;

import com.veterinaria.propietario.dto.PropietarioDTO;
import com.veterinaria.propietario.exception.RecursoNoEncontradoException;
import com.veterinaria.propietario.model.Propietario;
import com.veterinaria.propietario.repository.PropietarioRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PropietarioService {

    private final PropietarioRepository propietarioRepository;

    public PropietarioService(
            PropietarioRepository propietarioRepository) {
        this.propietarioRepository = propietarioRepository;
    }

    // LISTAR TODOS LOS PROPIETARIOS
    @Transactional(readOnly = true)
    public List<Propietario> listar() {
        return propietarioRepository.findAll();
    }

    // BUSCAR PROPIETARIO POR ID
    @Transactional(readOnly = true)
    public Propietario buscarPorId(Long id) {
        return propietarioRepository.findById(id)
                .orElseThrow(() ->
                        new RecursoNoEncontradoException(
                                "No existe el propietario con ID: " + id
                        )
                );
    }

    // REGISTRAR PROPIETARIO
    @Transactional
    public Propietario registrar(PropietarioDTO dto) {

        Propietario propietario = new Propietario();

        propietario.setNombre(dto.getNombre());
        propietario.setApellido(dto.getApellido());
        propietario.setTelefono(dto.getTelefono());
        propietario.setCorreo(dto.getCorreo());

        return propietarioRepository.save(propietario);
    }

    // ACTUALIZAR PROPIETARIO
    @Transactional
    public Propietario actualizar(Long id, PropietarioDTO dto) {

        Propietario propietario = buscarPorId(id);

        propietario.setNombre(dto.getNombre());
        propietario.setApellido(dto.getApellido());
        propietario.setTelefono(dto.getTelefono());
        propietario.setCorreo(dto.getCorreo());

        return propietarioRepository.save(propietario);
    }

    // ELIMINAR PROPIETARIO
    @Transactional
    public void eliminar(Long id) {

        Propietario propietario = buscarPorId(id);

        propietarioRepository.delete(propietario);
    }
}
