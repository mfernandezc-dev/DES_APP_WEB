package com.tecsup.exception;

import feign.FeignException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;

class FeignExceptionHandlerTests {
    private final FeignExceptionHandler handler = new FeignExceptionHandler();

    @Test
    void referenciaAusenteDevuelve404() {
        assertEquals(HttpStatus.NOT_FOUND,
                handler.manejarReferenciaRemota(mock(FeignException.NotFound.class)).getStatusCode());
    }

    @Test
    void falloRemotoDevuelve503() {
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE,
                handler.manejarReferenciaRemota(mock(FeignException.ServiceUnavailable.class)).getStatusCode());
    }
}
