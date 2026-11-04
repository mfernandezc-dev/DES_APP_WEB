export function today() {
  const date = new Date();
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function isPositiveId(value) {
  return /^\d+$/.test(String(value)) && Number.isSafeInteger(Number(value)) && Number(value) > 0;
}

export function isValidDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || value.startsWith('0000')) return false;
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
}

function requiredText(errors, values, field, label, max) {
  const value = String(values[field] ?? '').trim();
  if (!value) errors[field] = `${label} es ${label.startsWith('La ') ? 'obligatoria' : 'obligatorio'}.`;
  else if (value.length > max) errors[field] = `No debe superar ${max} caracteres.`;
}

export function validatePropietario(values) {
  const errors = {};
  requiredText(errors, values, 'nombre', 'El nombre', 100);
  requiredText(errors, values, 'apellido', 'El apellido', 100);
  if (values.telefono?.trim().length > 20) errors.telefono = 'No debe superar 20 caracteres.';
  const correo = values.correo?.trim() || '';
  if (correo.length > 100) errors.correo = 'No debe superar 100 caracteres.';
  else if (correo && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)) errors.correo = 'Ingresa un correo electrónico válido.';
  return errors;
}

export function validateMascota(values) {
  const errors = {};
  requiredText(errors, values, 'nombre', 'El nombre', 100);
  requiredText(errors, values, 'especie', 'La especie', 50);
  if (!isValidDate(values.fechaNacimiento || '')) errors.fechaNacimiento = 'Ingresa una fecha de nacimiento válida.';
  else if (values.fechaNacimiento > today()) errors.fechaNacimiento = 'La fecha de nacimiento no puede ser futura.';
  if (!isPositiveId(values.idPropietario)) errors.idPropietario = 'Selecciona un propietario válido.';
  return errors;
}

export function validateConsulta(values) {
  const errors = {};
  if (!isPositiveId(values.idMascota)) errors.idMascota = 'Selecciona una mascota válida.';
  if (!isValidDate(values.fecha || '')) errors.fecha = 'Ingresa una fecha válida.';
  requiredText(errors, values, 'motivo', 'El motivo', 255);
  requiredText(errors, values, 'diagnostico', 'El diagnóstico', 500);
  const costo = String(values.costo ?? '').trim();
  if (!costo) errors.costo = 'El costo es obligatorio.';
  else if (!Number.isFinite(Number(costo))) errors.costo = 'Ingresa un costo numérico válido.';
  else if (Number(costo) < 0) errors.costo = 'El costo no puede ser negativo.';
  else if (!/^\d{1,8}(\.\d{1,2})?$/.test(costo)) errors.costo = 'Usa como máximo 8 enteros y 2 decimales (ejemplo: 45.50).';
  return errors;
}

export function toPayload(values, numericFields = []) {
  return Object.fromEntries(Object.entries(values).map(([key, value]) => [
    key, numericFields.includes(key) ? Number(value) : String(value ?? '').trim(),
  ]));
}
