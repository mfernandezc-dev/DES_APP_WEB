# Retry

Guardar respuesta, duración y líneas de consola de una sola solicitud. Deben existir tres entradas de intento HTTP con aproximadamente 2 segundos de espera entre fallos. Un fallback aislado no prueba Retry.

Resultados ejecutados: `categoria-no-disponible.json` (3 intentos, 4340 ms) y `../actividad-final/cliente-retry.json` (3 intentos por timeout, 10079 ms). `informe-resultados.png` captura el informe HTML de esos datos guardados; no es una pantalla de Postman ni una captura en vivo del backend.
