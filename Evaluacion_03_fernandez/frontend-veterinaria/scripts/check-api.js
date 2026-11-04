import assert from 'node:assert/strict';

// Solo GET: este script nunca registra, actualiza ni elimina datos.
// Sin argumento consulta los puertos directos; con URL consulta el proxy Vite.
const proxy = process.argv[2]?.replace(/\/$/, '');
const modules = [
  { resource: 'propietarios', port: 8081, fields: ['id', 'nombre', 'apellido', 'telefono', 'correo'] },
  { resource: 'mascotas', port: 8082, fields: ['id', 'nombre', 'especie', 'fechaNacimiento', 'idPropietario'], filter: 'propietario', relatedField: 'idPropietario' },
  { resource: 'consultas', port: 8083, fields: ['id', 'idMascota', 'fecha', 'motivo', 'diagnostico', 'costo'], filter: 'mascota', relatedField: 'idMascota' },
];

let failures = 0;
let passed = 0;
await Promise.all(modules.map(async (module) => {
  const base = `${proxy || `http://localhost:${module.port}`}/api/${module.resource}`;
  async function get(suffix = '', status = 200) {
    const response = await fetch(`${base}${suffix}`, { signal: AbortSignal.timeout(8000) });
    assert.equal(response.status, status, `GET ${base}${suffix}: HTTP ${response.status}, esperado ${status}`);
    return response.json();
  }
  try {
    const list = await get();
    assert.ok(Array.isArray(list), 'El listado debe ser un arreglo JSON');
    for (const record of list) for (const field of module.fields) assert.ok(Object.hasOwn(record, field), `Falta el atributo ${field}`);
    passed++;
    console.log(`OK ${module.resource}: HTTP 200, ${list.length} registros y atributos compatibles.`);
    if (list.length) {
      const first = await get(`/${list[0].id}`);
      assert.equal(first.id, list[0].id);
      passed++;
      console.log(`OK ${module.resource}: búsqueda por ID de un registro existente.`);
      if (module.filter) {
        const data = await get(`/${module.filter}/${first[module.relatedField]}`);
        assert.ok(Array.isArray(data));
        assert.ok(data.some((record) => record.id === first.id));
        assert.ok(data.every((record) => record[module.relatedField] === first[module.relatedField]));
        passed++;
        console.log(`OK ${module.resource}: filtro por ${module.filter}.`);
      }
    } else console.log(`PENDIENTE ${module.resource}: no hay registros existentes para probar búsqueda y filtro.`);
    const notFound = await get('/0', 404);
    assert.ok(typeof notFound.mensaje === 'string');
    passed++;
    console.log(`OK ${module.resource}: HTTP 404 con mensaje de Spring Boot.`);
  } catch (error) {
    failures++;
    console.error(`NO VERIFICADO ${module.resource}: ${error.message}${error.cause?.code ? ` (${error.cause.code})` : ''}`);
  }
}));
console.log(`Comprobaciones GET: ${passed} correctas; ${failures} módulos no verificados. No se realizaron escrituras.`);
process.exitCode = failures ? 1 : 0;
