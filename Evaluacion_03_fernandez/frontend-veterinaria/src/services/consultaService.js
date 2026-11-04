import { createCrudService, request } from './api.js';

export const consultaService = {
  ...createCrudService('/api/consultas'),
  listarPorMascota: (id) => request(`/api/consultas/mascota/${encodeURIComponent(id)}`),
};
