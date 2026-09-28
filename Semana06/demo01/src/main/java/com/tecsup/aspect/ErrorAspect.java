package com.tecsup.aspect;

import com.tecsup.service.AuditoriaService;
import org.aspectj.lang.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class ErrorAspect {

    @Autowired
    private AuditoriaService auditoriaService;


    @AfterThrowing(
            pointcut = "execution(* com.tecsup.service.*.*(..))",
            throwing = "ex"
    )
    public void capturarError(Exception ex) {

        auditoriaService.registrar(
                "ERROR",
                "Servicio",
                "Error ocurrido: " + ex.getMessage(),
                "SISTEMA"
        );

        System.out.println(
                "ERROR registrado en auditoría: " + ex.getMessage()
        );
    }
}