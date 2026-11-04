import { createCrudService, request } from './api.js';

export const mascotaService = {
  ...createCrudService('/api/mascotas'),
  listarPorPropietario: (id) => request(`/api/mascotas/propietario/${encodeURIComponent(id)}`),
};
