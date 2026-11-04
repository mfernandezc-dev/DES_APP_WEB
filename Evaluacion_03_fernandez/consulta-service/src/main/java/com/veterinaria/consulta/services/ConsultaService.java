
package com.veterinaria.consulta.services;

import com.veterinaria.consulta.dto.ConsultaDTO;
import com.veterinaria.consulta.exception.RecursoNoEncontradoException;
import com.veterinaria.consulta.model.Consulta;
import com.veterinaria.consulta.repository.ConsultaRepository;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.util.List;

@Service
public class ConsultaService {

    private final ConsultaRepository consultaRepository;
    private final RestClient restClient;

    public ConsultaService(
            ConsultaRepository consultaRepository,
            @Value("${services.mascota.url}") String mascotaUrl) {

        this.consultaRepository = consultaRepository;
        this.restClient = RestClient.create(mascotaUrl);
    }

    // VERIFICAR QUE LA MASCOTA EXISTA
    private void verificarMascota(Long idMascota) {

        restClient.get()
                .uri("/{id}", idMascota)
                .retrieve()
                .onStatus(
                        status -> status.value() == 404,
                        (request, response) -> {
                            throw new RecursoNoEncontradoException(
                                    "No existe la mascota con ID: "
                                            + idMascota
                            );
                        }
                )
                .toBodilessEntity();
    }

    // LISTAR TODAS LAS CONSULTAS
    @Transactional(readOnly = true)
    public List<Consulta> listar() {
        return consultaRepository.findAll();
    }

    // BUSCAR CONSULTA POR ID
    @Transactional(readOnly = true)
    public Consulta buscarPorId(Long id) {
        return consultaRepository.findById(id)
                .orElseThrow(() ->
                        new RecursoNoEncontradoException(
                                "No existe la consulta con ID: " + id
                        )
                );
    }

    // LISTAR CONSULTAS POR MASCOTA
    @Transactional(readOnly = true)
    public List<Consulta> listarPorMascota(Long idMascota) {
        return consultaRepository.findByIdMascota(idMascota);
    }

    // REGISTRAR CONSULTA
    @Transactional
    public Consulta registrar(ConsultaDTO dto) {

        verificarMascota(dto.getIdMascota());

        Consulta consulta = new Consulta();

        consulta.setIdMascota(dto.getIdMascota());
        consulta.setFecha(dto.getFecha());
        consulta.setMotivo(dto.getMotivo());
        consulta.setDiagnostico(dto.getDiagnostico());
        consulta.setCosto(dto.getCosto());

        return consultaRepository.save(consulta);
    }

    // ACTUALIZAR CONSULTA
    @Transactional
    public Consulta actualizar(Long id, ConsultaDTO dto) {

        Consulta consulta = buscarPorId(id);

        verificarMascota(dto.getIdMascota());

        consulta.setIdMascota(dto.getIdMascota());
        consulta.setFecha(dto.getFecha());
        consulta.setMotivo(dto.getMotivo());
        consulta.setDiagnostico(dto.getDiagnostico());
        consulta.setCosto(dto.getCosto());

        return consultaRepository.save(consulta);
    }

    // ELIMINAR CONSULTA
    @Transactional
    public void eliminar(Long id) {

        Consulta consulta = buscarPorId(id);

        consultaRepository.delete(consulta);
    }
}
