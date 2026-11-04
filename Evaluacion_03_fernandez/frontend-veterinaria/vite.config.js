import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Las rutas se conservan: no se necesita cambiar CORS ni el backend.
function createProxy(target) {
  return {
    target,
    changeOrigin: true,
    configure(proxy) {
      proxy.on('error', (_error, _request, response) => {
        // Vite normalmente devuelve un 500 vacío cuando un servicio está apagado.
        if (response && !response.headersSent && typeof response.writeHead === 'function') {
          response.writeHead(503, { 'Content-Type': 'application/json; charset=utf-8' });
          response.end(JSON.stringify({
            error: 'Servicio no disponible',
            mensaje: `No se pudo conectar con ${target}. Verifica que el microservicio esté ejecutándose.`,
          }));
        }
      });
    },
  };
}

const proxy = {
  '/api/propietarios': createProxy('http://localhost:8081'),
  '/api/mascotas': createProxy('http://localhost:8082'),
  '/api/consultas': createProxy('http://localhost:8083'),
};

export default defineConfig({
  plugins: [react()],
  server: { host: 'localhost', port: 5173, strictPort: true, proxy },
  preview: { host: 'localhost', port: 4173, strictPort: true, proxy },
});
