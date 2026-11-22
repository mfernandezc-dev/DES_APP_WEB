package com.tecsup.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;

@Component
@Profile("lab")
public class LabDelayFilter extends OncePerRequestFilter {
    private final AtomicInteger active = new AtomicInteger();

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                  FilterChain chain) throws ServletException, IOException {
        String value = request.getHeader("X-Lab-Cliente-Delay-Ms");
        if (value == null || !"GET".equals(request.getMethod()) || !request.getRequestURI().matches("/api/clientes/\\d+")) {
            chain.doFilter(request, response);
            return;
        }
        long delay;
        try { delay = Long.parseLong(value); }
        catch (NumberFormatException ex) { response.sendError(400, "Demora invalida"); return; }
        if (delay < 0 || delay > 10000) { response.sendError(400, "Demora fuera de rango"); return; }
        logger.info("LAB demora=" + delay + "ms activas=" + active.incrementAndGet());
        try {
            Thread.sleep(delay);
            chain.doFilter(request, response);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            response.sendError(503, "Simulacion interrumpida");
        } finally { logger.info("LAB fin activas=" + active.decrementAndGet()); }
    }
}
