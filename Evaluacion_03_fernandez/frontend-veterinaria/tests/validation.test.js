import test from 'node:test';
import assert from 'node:assert/strict';
import { isPositiveId, isValidDate, today, toPayload, validateConsulta, validateMascota, validatePropietario } from '../src/utils/validation.js';
import { formatCurrency, formatDate, fullName } from '../src/utils/format.js';

// Entradas de funciones puras: no hay peticiones, respuestas simuladas ni escrituras en MySQL.
const owner = { nombre: 'Ana', apellido: 'Pérez', telefono: '', correo: '' };
const pet = { nombre: 'Luna', especie: 'Gato', fechaNacimiento: '2020-06-15', idPropietario: '1' };
const consultation = { idMascota: '1', fecha: '2024-06-15', motivo: 'Revisión', diagnostico: 'Control', costo: '35.50' };

test('Propietario: nombre y apellido son obligatorios, incluso con espacios', () => {
  for (const value of ['', '   ']) {
    const errors = validatePropietario({ ...owner, nombre: value, apellido: value });
    assert.ok(errors.nombre);
    assert.ok(errors.apellido);
  }
});

test('Propietario: teléfono y correo son opcionales', () => {
  assert.deepEqual(validatePropietario(owner), {});
  assert.deepEqual(validatePropietario({ ...owner, telefono: null, correo: null }), {});
});

test('Propietario: valida correo electrónico', () => {
  for (const correo of ['sin-arroba', 'a@', '@dominio.com', 'a b@dominio.com', 'a@@dominio.com']) assert.ok(validatePropietario({ ...owner, correo }).correo);
  for (const correo of ['ana@dominio.com', 'ana.perez+vet@dominio.com.pe']) assert.equal(validatePropietario({ ...owner, correo }).correo, undefined);
});

test('Propietario: respeta los límites de los cuatro atributos del DTO', () => {
  for (const [field, limit] of [['nombre', 100], ['apellido', 100], ['telefono', 20]]) {
    assert.ok(validatePropietario({ ...owner, [field]: 'x'.repeat(limit + 1) })[field]);
    assert.equal(validatePropietario({ ...owner, [field]: 'x'.repeat(limit) })[field], undefined);
  }
  assert.ok(validatePropietario({ ...owner, correo: `${'a'.repeat(95)}@d.com` }).correo);
});

test('Mascota: todos sus atributos son obligatorios', () => {
  const errors = validateMascota({});
  assert.deepEqual(Object.keys(errors).sort(), ['especie', 'fechaNacimiento', 'idPropietario', 'nombre']);
});

test('Mascota: nombre de hasta 100 y especie de hasta 50 caracteres', () => {
  assert.deepEqual(validateMascota(pet), {});
  assert.ok(validateMascota({ ...pet, nombre: 'x'.repeat(101) }).nombre);
  assert.ok(validateMascota({ ...pet, especie: 'x'.repeat(51) }).especie);
  assert.equal(validateMascota({ ...pet, especie: 'x'.repeat(50) }).especie, undefined);
});

test('Mascota: admite nacimiento hoy, pero no fechas futuras', () => {
  assert.equal(validateMascota({ ...pet, fechaNacimiento: today() }).fechaNacimiento, undefined);
  assert.ok(validateMascota({ ...pet, fechaNacimiento: '9999-12-31' }).fechaNacimiento);
});

test('Fechas: valida calendario y años bisiestos sin desfase de zona horaria', () => {
  for (const date of ['', '2024-02-30', '2023-02-29', '2024-13-01', '01/01/2024', '0000-01-01']) assert.equal(isValidDate(date), false, date);
  assert.equal(isValidDate('2024-02-29'), true);
  assert.match(today(), /^\d{4}-\d{2}-\d{2}$/);
  assert.equal(formatDate('2024-06-15'), '15/06/2024');
});

test('IDs: rechaza cero, negativos, decimales, texto y enteros inseguros', () => {
  for (const id of ['', '0', '-1', '1.5', 'abc', '1e2', 'Infinity', '9007199254740992', null]) {
    assert.equal(isPositiveId(id), false, String(id));
    assert.ok(validateMascota({ ...pet, idPropietario: id }).idPropietario);
    assert.ok(validateConsulta({ ...consultation, idMascota: id }).idMascota);
  }
  assert.equal(isPositiveId('42'), true);
});

test('Consulta: mascota, fecha, motivo, diagnóstico y costo obligatorios', () => {
  assert.deepEqual(Object.keys(validateConsulta({})).sort(), ['costo', 'diagnostico', 'fecha', 'idMascota', 'motivo']);
  assert.ok(validateConsulta({ ...consultation, motivo: ' ', diagnostico: '\t' }).motivo);
  assert.ok(validateConsulta({ ...consultation, diagnostico: ' ' }).diagnostico);
});

test('Consulta: no añade una restricción de fecha futura que el DTO no tiene', () => {
  assert.equal(validateConsulta({ ...consultation, fecha: '2099-12-31' }).fecha, undefined);
});

test('Consulta: motivo de hasta 255 y diagnóstico de hasta 500 caracteres', () => {
  assert.ok(validateConsulta({ ...consultation, motivo: 'x'.repeat(256) }).motivo);
  assert.ok(validateConsulta({ ...consultation, diagnostico: 'x'.repeat(501) }).diagnostico);
  assert.deepEqual(validateConsulta({ ...consultation, motivo: 'x'.repeat(255), diagnostico: 'x'.repeat(500) }), {});
});

test('Consulta: costo cero y decimales válidos', () => {
  for (const costo of ['0', '0.00', '12.5', '35.50', '99999999.99', 0]) assert.deepEqual(validateConsulta({ ...consultation, costo }), {}, String(costo));
});

test('Consulta: rechaza negativos, no numéricos, más de 8 enteros o 2 decimales', () => {
  for (const costo of ['', ' ', '-0.01', '-30', 'NaN', 'Infinity', 'abc', '100000000', '1.234', '5,50', '1e2']) assert.ok(validateConsulta({ ...consultation, costo }).costo, costo);
});

test('Payload: IDs y costo numéricos, atributos exactos y texto sin espacios externos', () => {
  assert.deepEqual(toPayload({ ...pet, nombre: ' Luna ' }, ['idPropietario']), { ...pet, nombre: 'Luna', idPropietario: 1 });
  const payload = toPayload(consultation, ['idMascota', 'costo']);
  assert.equal(payload.idMascota, 1);
  assert.equal(payload.costo, 35.5);
  assert.equal(Object.hasOwn(toPayload(owner), 'email'), false);
  assert.equal(Object.hasOwn(toPayload(owner), 'correo'), true);
});

test('Presentación: nombre completo y moneda peruana, incluso costo cero', () => {
  assert.equal(fullName(owner), 'Ana Pérez');
  assert.match(formatCurrency(35.5), /S\/.*35[.,]50/);
  assert.match(formatCurrency(0), /S\/.*0[.,]00/);
});
