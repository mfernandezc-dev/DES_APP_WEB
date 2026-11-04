import assert from 'node:assert/strict';
import { existsSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// Smoke test opcional: usa Edge instalado y Playwright de la caché local de npm.
// No descarga navegadores ni añade dependencias a la aplicación.
const root = fileURLToPath(new URL('../', import.meta.url));
const cache = path.join(root, '.npm-cache', '_npx');
const cachedModule = existsSync(cache) && readdirSync(cache)
  .map((entry) => path.join(cache, entry, 'node_modules', 'playwright', 'index.mjs'))
  .find((entry) => existsSync(entry));
if (!cachedModule) throw new Error('Ejecuta primero: npm exec --yes --package=playwright -- playwright --version');
const { chromium } = await import(pathToFileURL(cachedModule).href);
const artifacts = path.join(root, 'tests', 'artifacts');
mkdirSync(path.join(artifacts, 'tmp'), { recursive: true });
process.env.TEMP = path.join(artifacts, 'tmp');
process.env.TMP = process.env.TEMP;
const base = process.argv[2] || 'http://localhost:5173';
const context = await chromium.launchPersistentContext(path.join(artifacts, 'browser-profile'), {
  channel: 'msedge', headless: true, viewport: { width: 1440, height: 1000 }, locale: 'es-PE',
});
const page = await context.newPage();
const errors = [];
const blockedWrites = [];
const apiResponses = [];
page.on('pageerror', (error) => errors.push(error.message));
page.on('response', (response) => {
  if (response.url().includes('/api/')) apiResponses.push({ url: response.url(), status: response.status() });
});
// Protección: aunque un fallo de validación intentara guardar, no se toca MySQL.
// No hay fulfill() ni respuestas simuladas: los GET van al proxy y servicios reales.
await page.route('**/api/**', async (route) => {
  if (!['GET', 'HEAD', 'OPTIONS'].includes(route.request().method())) {
    blockedWrites.push(route.request().method());
    await route.abort();
  } else await route.continue();
});
const checks = [];
function ok(name) { checks.push(name); console.log(`OK ${name}`); }

try {
  await page.goto(base);
  await page.getByRole('heading', { name: 'Todo listo para cuidar mejor.' }).waitFor();
  await page.waitForFunction(() => [...document.querySelectorAll('.stat-value')].length === 3 && [...document.querySelectorAll('.stat-value')].every((element) => element.textContent !== '…'));
  assert.equal(await page.locator('.stat-card').count(), 3);
  assert.equal(await page.locator('.shortcut-card').count(), 3);
  const unavailable = new Set(apiResponses.filter((response) => response.status === 503).map((response) => new URL(response.url).pathname));
  if (unavailable.size === 3) {
    assert.deepEqual(await page.locator('.stat-value').allTextContents(), ['—', '—', '—']);
    assert.equal(await page.locator('.stat-error').count(), 3);
  }
  ok('Inicio: tres totales con datos reales o indisponibilidad explícita y tres accesos');
  await page.screenshot({ path: path.join(artifacts, 'inicio-desktop.png'), fullPage: true });

  await page.getByRole('navigation').getByRole('link', { name: 'Propietarios' }).click();
  await page.getByRole('heading', { name: 'Propietarios', exact: true }).waitFor();
  await page.getByRole('button', { name: 'Nuevo propietario' }).click();
  await page.getByRole('button', { name: 'Guardar registro' }).click();
  assert.equal(await page.locator('.field-error').count(), 2);
  ok('Propietario: envío vacío muestra errores debajo de nombre y apellido');
  await page.getByLabel('Nombre', { exact: false }).fill('Validación local');
  await page.getByLabel('Apellido', { exact: false }).fill('No enviar');
  await page.getByLabel('Correo electrónico', { exact: false }).fill('correo-invalido');
  await page.getByRole('button', { name: 'Guardar registro' }).click();
  assert.match(await page.locator('#error-correo').innerText(), /válido/);
  ok('Propietario: correo inválido bloqueado antes de Fetch');
  await page.screenshot({ path: path.join(artifacts, 'propietario-validacion.png'), fullPage: true });
  await page.getByRole('button', { name: 'Cancelar', exact: true }).click();
  await page.waitForFunction(() => !document.querySelector('[aria-busy="true"]'));
  await page.getByLabel('Buscar por ID').fill('0');
  await page.getByRole('button', { name: 'Buscar', exact: true }).click();
  assert.match(await page.locator('#search-error').innerText(), /entero positivo/);
  ok('Búsqueda: ID cero rechazado localmente');

  await page.getByRole('navigation').getByRole('link', { name: 'Mascotas' }).click();
  await page.getByRole('heading', { name: 'Mascotas', exact: true }).waitFor();
  await page.getByRole('button', { name: 'Nueva mascota' }).click();
  assert.equal(await page.locator('#field-idPropietario').getAttribute('required'), '');
  assert.match(await page.locator('#field-fechaNacimiento').getAttribute('max'), /^\d{4}-\d{2}-\d{2}$/);
  ok('Mascotas: selector obligatorio y límite de nacimiento al día actual');
  await page.getByRole('button', { name: 'Cancelar', exact: true }).click();

  await page.getByRole('navigation').getByRole('link', { name: 'Consultas' }).click();
  await page.getByRole('heading', { name: 'Consultas', exact: true }).waitFor();
  await page.getByRole('button', { name: 'Nueva consulta' }).click();
  assert.equal(await page.locator('#field-idMascota').getAttribute('required'), '');
  assert.equal(await page.locator('#field-costo').getAttribute('min'), '0');
  assert.equal(await page.locator('#field-costo').getAttribute('step'), '0.01');
  assert.equal(await page.locator('#field-costo').getAttribute('max'), '99999999.99');
  ok('Consultas: selector obligatorio y costo decimal con límites del DTO');
  await page.getByRole('button', { name: 'Cancelar', exact: true }).click();

  for (const width of [390, 320]) {
    await page.setViewportSize({ width, height: 844 });
    for (const section of ['Inicio', 'Propietarios', 'Mascotas', 'Consultas']) {
      await page.getByRole('navigation').getByRole('link', { name: section, exact: true }).click();
      await page.getByRole('heading', { name: section === 'Inicio' ? 'Todo listo para cuidar mejor.' : section, exact: true }).waitFor();
      await page.waitForFunction(() => !document.querySelector('[aria-busy="true"]'));
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth), `${section}: desbordamiento horizontal a ${width}px`);
    }
    ok(`Navegación de los cuatro módulos a ${width}px sin desbordamiento de la página`);
  }
  await page.setViewportSize({ width: 390, height: 844 });
  await page.getByRole('navigation').getByRole('link', { name: 'Inicio', exact: true }).click();
  await page.waitForFunction(() => !document.querySelector('[aria-busy="true"]'));
  await page.screenshot({ path: path.join(artifacts, 'inicio-mobile.png'), fullPage: true });
  assert.deepEqual(errors, []);
  assert.deepEqual(blockedWrites, []);
  ok('Sin errores JavaScript y sin intentos de POST, PUT o DELETE');
} finally {
  writeFileSync(path.join(artifacts, 'browser-result.json'), JSON.stringify({ base, checks, errors, blockedWrites, apiResponses }, null, 2));
  await context.close();
}
console.log(`${checks.length} comprobaciones de navegador correctas. No se escribió en MySQL.`);
