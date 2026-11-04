
package com.veterinaria.mascota.services;

import com.veterinaria.mascota.dto.MascotaDTO;
import com.veterinaria.mascota.exception.RecursoNoEncontradoException;
import com.veterinaria.mascota.model.Mascota;
import com.veterinaria.mascota.repository.MascotaRepository;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.util.List;

@Service
public class MascotaService {

    private final MascotaRepository mascotaRepository;
    private final RestClient restClient;

    public MascotaService(
            MascotaRepository mascotaRepository,
            RestClient.Builder restClientBuilder,
            @Value("${services.propietario.url}") String propietarioUrl) {

        this.mascotaRepository = mascotaRepository;
        this.restClient = restClientBuilder
                .baseUrl(propietarioUrl)
                .build();
    }

    // VERIFICAR SI EL PROPIETARIO EXISTE
    private void verificarPropietario(Long idPropietario) {

        restClient.get()
                .uri("/{id}", idPropietario)
                .retrieve()
                .onStatus(
                        status -> status.value() == 404,
                        (request, response) -> {
                            throw new RecursoNoEncontradoException(
                                    "No existe el propietario con ID: "
                                            + idPropietario
                            );
                        }
                )
                .toBodilessEntity();
    }

    // LISTAR TODAS LAS MASCOTAS
    @Transactional(readOnly = true)
    public List<Mascota> listar() {
        return mascotaRepository.findAll();
    }

    // BUSCAR MASCOTA POR ID
    @Transactional(readOnly = true)
    public Mascota buscarPorId(Long id) {
        return mascotaRepository.findById(id)
                .orElseThrow(() ->
                        new RecursoNoEncontradoException(
                                "No existe la mascota con ID: " + id
                        )
                );
    }

    // LISTAR MASCOTAS POR PROPIETARIO
    @Transactional(readOnly = true)
    public List<Mascota> listarPorPropietario(Long idPropietario) {
        return mascotaRepository.findByIdPropietario(idPropietario);
    }

    // REGISTRAR MASCOTA
    @Transactional
    public Mascota registrar(MascotaDTO dto) {

        verificarPropietario(dto.getIdPropietario());

        Mascota mascota = new Mascota();

        mascota.setNombre(dto.getNombre());
        mascota.setEspecie(dto.getEspecie());
        mascota.setFechaNacimiento(dto.getFechaNacimiento());
        mascota.setIdPropietario(dto.getIdPropietario());

        return mascotaRepository.save(mascota);
    }

    // ACTUALIZAR MASCOTA
    @Transactional
    public Mascota actualizar(Long id, MascotaDTO dto) {

        Mascota mascota = buscarPorId(id);

        verificarPropietario(dto.getIdPropietario());

        mascota.setNombre(dto.getNombre());
        mascota.setEspecie(dto.getEspecie());
        mascota.setFechaNacimiento(dto.getFechaNacimiento());
        mascota.setIdPropietario(dto.getIdPropietario());

        return mascotaRepository.save(mascota);
    }

    // ELIMINAR MASCOTA
    @Transactional
    public void eliminar(Long id) {

        Mascota mascota = buscarPorId(id);

        mascotaRepository.delete(mascota);
    }
}
