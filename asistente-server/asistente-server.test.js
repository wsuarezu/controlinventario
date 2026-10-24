// Pruebas del servidor del asistente (sin red ni clave real):
//   node --test asistente-server/asistente-server.test.js

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { atender, responderConReglas, validarSalida } = require('./asistente-server');

const productos = [
  { id: 1, nombre: 'Clavos', cantidad: 8, cantidad_minima: 10 },
  { id: 2, nombre: 'Tornillos', cantidad: 45, cantidad_minima: 10 },
  { id: 3, nombre: 'Brocha', cantidad: 6, cantidad_minima: 6 },
];

const cuerpo = (objeto) => Buffer.from(JSON.stringify(objeto));

/** Backend falso: acepta solo «Bearer bueno» y devuelve `productos`. */
async function conBackend(fn) {
  const backend = http.createServer((req, res) => {
    const ok = req.headers.authorization === 'Bearer bueno';
    res.writeHead(ok ? 200 : 401, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(ok ? productos : { detail: 'Credenciales inválidas' }));
  });
  await new Promise((r) => backend.listen(0, '127.0.0.1', r));
  try {
    await fn(`http://127.0.0.1:${backend.address().port}`);
  } finally {
    backend.close();
  }
}

test('modo reglas: lo que hay que reponer incluye el caso igual al mínimo', () => {
  const { respuesta } = responderConReglas('¿Qué debo reponer?', productos);
  assert.match(respuesta, /2 producto/);
  assert.match(respuesta, /Clavos/);
  assert.match(respuesta, /Brocha/);
  assert.doesNotMatch(respuesta, /Tornillos/);
});

test('modo reglas: inventario vacío y pregunta no reconocida', () => {
  assert.match(responderConReglas('hola', []).respuesta, /vacío/);
  assert.match(responderConReglas('¿quién ganó el partido?', productos).respuesta, /No entendí/);
});

test('validarSalida rechaza respuestas vacías del modelo', () => {
  assert.throws(() => validarSalida({ respuesta: '  ' }), { codigo: 502 });
  assert.deepEqual(validarSalida({ respuesta: ' Repón clavos. ' }), { respuesta: 'Repón clavos.' });
});

test('sin token responde 401', async () => {
  const r = await atender({ autorizacion: undefined, bruto: cuerpo({ consulta: 'hola' }) });
  assert.equal(r.codigo, 401);
});

test('JSON inválido responde 400; consulta vacía o larga, 422', async () => {
  const a = 'Bearer x';
  assert.equal((await atender({ autorizacion: a, bruto: Buffer.from('{no') })).codigo, 400);
  assert.equal((await atender({ autorizacion: a, bruto: cuerpo({ consulta: ' ' }) })).codigo, 422);
  assert.equal((await atender({ autorizacion: a, bruto: cuerpo({ consulta: 'a'.repeat(501) }) })).codigo, 422);
});

test('token rechazado por el backend responde 401', async () => {
  await conBackend(async (backendUrl) => {
    const r = await atender({ autorizacion: 'Bearer malo', bruto: cuerpo({ consulta: 'hola' }), clave: '', backendUrl });
    assert.equal(r.codigo, 401);
  });
});

test('token válido y sin clave: responde con el inventario real en modo reglas', async () => {
  await conBackend(async (backendUrl) => {
    const r = await atender({
      autorizacion: 'Bearer bueno',
      bruto: cuerpo({ consulta: '¿qué debo comprar?' }),
      clave: '',
      backendUrl,
    });
    assert.equal(r.codigo, 200);
    assert.equal(r.cuerpo.modo, 'reglas');
    assert.match(r.cuerpo.respuesta, /Clavos/);
  });
});

test('backend apagado responde 502 con un mensaje claro', async () => {
  const r = await atender({
    autorizacion: 'Bearer bueno',
    bruto: cuerpo({ consulta: 'hola' }),
    clave: '',
    backendUrl: 'http://127.0.0.1:1',
  });
  assert.equal(r.codigo, 502);
  assert.match(r.cuerpo.detail, /backend/);
});
