package com.lab04.fernandez.controller;

import com.lab04.fernandez.model.Usuario;
import com.lab04.fernandez.service.UsuarioService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;

    public UsuarioController(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    // Registrar usuario con perfil
    @PostMapping
    public Usuario registrar(@RequestBody Usuario usuario) {

        if (usuario.getPerfil() != null) {
            usuario.getPerfil().setUsuario(usuario);
        }

        return usuarioService.guardar(usuario);
    }

    // Listar usuarios con su perfil
    @GetMapping
    public List<Usuario> listar() {
        return usuarioService.listar();
    }

    // Obtener usuario por ID
    @GetMapping("/{id}")
    public ResponseEntity<Usuario> obtenerPorId(@PathVariable Long id) {

        Usuario usuario = usuarioService.buscarPorId(id);

        if (usuario == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(usuario);
    }

    // Eliminar usuario y su perfil
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {

        Usuario usuario = usuarioService.buscarPorId(id);

        if (usuario == null) {
            return ResponseEntity.notFound().build();
        }

        usuarioService.eliminar(id);

        return ResponseEntity.noContent().build();
    }
}