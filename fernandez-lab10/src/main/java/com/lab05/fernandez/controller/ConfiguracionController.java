
package com.lab05.fernandez.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class ConfiguracionController {

    @Value("${empresa.ambiente}")
    private String ambiente;

    private final Environment environment;

    public ConfiguracionController(Environment environment) {
        this.environment = environment;
    }

    @GetMapping("/configuracion")
    public Map<String, String> obtenerConfiguracion() {

        Map<String, String> datos = new LinkedHashMap<>();

        String[] perfiles = environment.getActiveProfiles();
        String perfil = perfiles.length > 0 ? perfiles[0] : "default";

        String puerto = environment.getProperty("server.port", "8080");
        String url = environment.getProperty("spring.datasource.url", "");

        String baseDatos = url.contains("/")
                ? url.substring(url.lastIndexOf("/") + 1).split("[?]")[0]
                : "";

        datos.put("ambiente", ambiente);
        datos.put("perfil", perfil);
        datos.put("puerto", puerto);
        datos.put("baseDatos", baseDatos);

        return datos;
    }
}
