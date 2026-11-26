
package com.tecsup.service;

import com.tecsup.model.Cliente;
import com.tecsup.repository.ClienteRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ClienteService {

    private final ClienteRepository repository;

    public ClienteService(ClienteRepository repository) {
        this.repository = repository;
    }

    public Cliente guardar(Cliente cliente) {
        return repository.save(cliente);
    }

    public List<Cliente> listar() {
        return repository.findAll();
    }

    public Cliente obtener(Long id) {
        return repository.findById(id)
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Cliente no encontrado"
                        )
                );
    }

    public Cliente actualizar(Long id, Cliente datos) {
        Cliente cliente = obtener(id);

        cliente.setNombre(datos.getNombre());
        cliente.setApellido(datos.getApellido());
        cliente.setDireccion(datos.getDireccion());
        cliente.setEstado(datos.getEstado());
        cliente.setNroDni(datos.getNroDni());

        return repository.save(cliente);
    }

    public void eliminar(Long id) {
        Cliente cliente = obtener(id);
        repository.delete(cliente);
    }
}
