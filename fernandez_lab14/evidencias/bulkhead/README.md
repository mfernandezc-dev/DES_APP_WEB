# Bulkhead

Ejecutar cuatro solicitudes HTTP simultáneas, con demora de 10 segundos solo en la dependencia. Guardar dos respuestas reales, dos fallbacks y el máximo de llamadas admitidas igual a 2. No usar pestañas del navegador como única prueba: pueden serializar solicitudes iguales.

La ejecución real está en `categoria-concurrente.json`; la de Producto en `../actividad-final/producto-bulkhead.json`. Ambas registran cuatro HTTP 200, dos respuestas reales de aproximadamente 10 s y dos fallbacks de aproximadamente 1 s. Los logs muestran dos llamadas activas como máximo. El informe visual y su captura están en `../informe.html` y `../retry/informe-resultados.png`.
