export class ApiError extends Error {
  constructor(message, status = 0, details = {}) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.details = details;
  }
}

const statusMessages = {
  400: 'Los datos enviados no son válidos. Revisa el formulario.',
  404: 'El registro solicitado no existe.',
  409: 'No se pudo completar la operación por un conflicto con los datos.',
  500: 'El microservicio no pudo completar la solicitud.',
  502: 'No se pudo completar la comunicación entre microservicios.',
  503: 'El microservicio no está disponible. Comprueba que esté ejecutándose.',
};

export function responseError(status, data) {
  const details = data?.detalles && typeof data.detalles === 'object' ? data.detalles : {};
  const message = data?.mensaje || data?.message || data?.error || statusMessages[status]
    || `No se pudo completar la solicitud (HTTP ${status}).`;
  return new ApiError(String(message), status, details);
}

export async function request(path, { method = 'GET', body, signal } = {}) {
  let response;
  try {
    response = await fetch(path, {
      method,
      headers: { Accept: 'application/json', ...(body !== undefined && { 'Content-Type': 'application/json' }) },
      ...(body !== undefined && { body: JSON.stringify(body) }),
      signal: signal || AbortSignal.timeout(15000),
    });
  } catch (error) {
    if (error.name === 'AbortError') throw error;
    throw new ApiError(error.name === 'TimeoutError'
      ? 'El servicio tardó demasiado en responder. No se pudo confirmar la operación; consulta la tabla antes de repetirla.'
      : 'No se pudo conectar con el servidor. Comprueba Vite y los microservicios.');
  }

  // DELETE devuelve 204: no hay cuerpo JSON que interpretar.
  if (response.status === 204) return null;
  const text = await response.text();
  let data = null;
  if (text) {
    try { data = JSON.parse(text); }
    catch {
      if (response.ok) throw new ApiError('El servidor devolvió una respuesta que no es JSON.', response.status);
    }
  }
  if (!response.ok) throw responseError(response.status, data);
  return data;
}

// Los tres controladores comparten las mismas operaciones CRUD.
export function createCrudService(basePath) {
  return {
    listar: () => request(basePath),
    buscarPorId: (id) => request(`${basePath}/${encodeURIComponent(id)}`),
    registrar: (body) => request(basePath, { method: 'POST', body }),
    actualizar: (id, body) => request(`${basePath}/${encodeURIComponent(id)}`, { method: 'PUT', body }),
    eliminar: (id) => request(`${basePath}/${encodeURIComponent(id)}`, { method: 'DELETE' }),
  };
}
