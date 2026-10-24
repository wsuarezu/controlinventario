// Prueba de extremo a extremo del asistente, sin la app.
//
// Recorre la cadena completa:  tú → backend (login) → backend (inventario) → asistente → IA.
//
// Uso (con el backend y el asistente encendidos):
//   node probar-e2e.js <correo> <contraseña>
//   (por ejemplo: node probar-e2e.js demo@inventario.com demo1234)
//
// Direcciones por defecto (cámbialas solo si tus puertos son otros):
//   BACKEND_URL=http://127.0.0.1:8000   ASISTENTE_URL=http://127.0.0.1:3000
//
// Sin dependencias externas: Node.js 18 o superior.

const BACKEND_URL = (process.env.BACKEND_URL || 'http://127.0.0.1:8000').replace(/\/$/, '');
const ASISTENTE_URL = (process.env.ASISTENTE_URL || 'http://127.0.0.1:3000').replace(/\/$/, '');
const [correo, clave] = process.argv.slice(2);

let fallos = 0;
const ok = (texto) => console.log(`✅ ${texto}`);
const mal = (texto, ayuda) => {
  fallos += 1;
  console.log(`❌ ${texto}`);
  if (ayuda) console.log(`   → ${ayuda}`);
};

async function main() {
  if (!correo || !clave) {
    console.log('Uso: node probar-e2e.js <correo> <contraseña>');
    console.log('Usa el correo y la contraseña con los que inicias sesión en la app (por ejemplo, el usuario demo).');
    process.exit(2);
  }

  // 1) El backend responde (FastAPI publica su esquema en /openapi.json).
  try {
    const r = await fetch(`${BACKEND_URL}/openapi.json`, { signal: AbortSignal.timeout(5000) });
    if (r.ok) ok(`1/4 Backend encendido (${BACKEND_URL})`);
    else mal('1/4 El backend respondió con un error', 'Revisa la terminal del backend (uvicorn).');
  } catch (_) {
    mal('1/4 No se pudo conectar con el backend', 'Enciéndelo en WSL con «uv run uvicorn app.main:app --host 0.0.0.0 --port 8000».');
    return; // sin backend no tiene sentido seguir
  }

  // 2) Inicio de sesión: se obtiene el token (el mismo que usa la app).
  let autorizacion;
  try {
    const r = await fetch(`${BACKEND_URL}/usuarios/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ username: correo, password: clave }),
      signal: AbortSignal.timeout(10000),
    });
    const datos = await r.json();
    if (!r.ok || !datos.access_token) throw new Error('credenciales');
    autorizacion = `Bearer ${datos.access_token}`;
    ok('2/4 Inicio de sesión correcto (token obtenido; no se imprime)');
  } catch (_) {
    mal('2/4 No se pudo iniciar sesión', 'Revisa el correo y la contraseña. Para el usuario demo, ejecuta antes «uv run python -m app.seed».');
    return;
  }

  // 3) El inventario de ese usuario.
  try {
    const r = await fetch(`${BACKEND_URL}/productos/?limit=100`, {
      headers: { Authorization: autorizacion },
      signal: AbortSignal.timeout(10000),
    });
    const productos = await r.json();
    if (!r.ok || !Array.isArray(productos)) throw new Error(`código ${r.status}`);
    const bajos = productos.filter((p) => p.cantidad <= p.cantidad_minima).length;
    ok(`3/4 Inventario: ${productos.length} productos, ${bajos} por reponer`);
  } catch (e) {
    mal(`3/4 El backend no devolvió el inventario (${e.message})`);
    return;
  }

  // 4) El asistente: con el mismo token, pide el inventario al backend y responde.
  try {
    const r = await fetch(`${ASISTENTE_URL}/asistente`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: autorizacion },
      body: JSON.stringify({ consulta: '¿Qué productos debo reponer?' }),
      signal: AbortSignal.timeout(30000),
    });
    const datos = await r.json();
    if (!r.ok) {
      mal(`4/4 El asistente respondió ${r.status}: ${datos.detail || 'sin detalle'}`,
        r.status === 429 ? 'Se agotó la cuota gratuita: reinicia el asistente sin GEMINI_API_KEY (modo reglas) y repite.' : 'Revisa la terminal del asistente.');
      return;
    }
    ok(`4/4 El asistente respondió (modo ${datos.modo}):`);
    console.log(`   «${datos.respuesta}»`);
  } catch (_) {
    mal('4/4 No se pudo conectar con el asistente', 'Enciéndelo con «node asistente-server.js».');
  }
}

main().then(() => {
  console.log(fallos === 0 ? '\nTodo bien: la cadena completa funciona.' : `\n${fallos} paso(s) con problemas.`);
  process.exit(fallos === 0 ? 0 : 1);
});
