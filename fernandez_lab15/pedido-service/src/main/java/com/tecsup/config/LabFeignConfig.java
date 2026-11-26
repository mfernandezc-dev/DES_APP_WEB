package com.tecsup.config;

import feign.RequestInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Configuration
@Profile("lab")
public class LabFeignConfig {
    @Bean
    public RequestInterceptor labDelayHeaders() {
        return template -> {
            if (RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes attrs) {
                for (String name : new String[]{"X-Lab-Categoria-Delay-Ms", "X-Lab-Cliente-Delay-Ms", "X-Lab-Producto-Delay-Ms"}) {
                    String value = attrs.getRequest().getHeader(name);
                    if (value != null) template.header(name, value);
                }
            }
        };
    }
}
