// Cliente del backend de inventario para el servidor del asistente.
//
// Qué hace: con el MISMO token de la persona, pide su inventario al backend
// (GET /productos/). Así la IA trabaja con los datos reales del usuario, no con
// lo que mande la app, y el backend decide si el token es válido.
//
// Sin dependencias externas: Node.js 18 o superior (usa fetch).
//
// Regla de seguridad: el token (cabecera Authorization) se reenvía, pero NUNCA se registra.

const BACKEND_URL = (process.env.BACKEND_URL || 'http://127.0.0.1:8000').trim().replace(/\/$/, '');
const ESPERA_MAX_MS = 10000;

class ErrorInventario extends Error {
  constructor(codigo, mensaje) {
    super(mensaje);
    this.codigo = codigo;
  }
}

/** Devuelve la lista de productos del usuario dueño del token, o lanza ErrorInventario. */
async function obtenerInventario(autorizacion, backendUrl = BACKEND_URL) {
  let r;
  try {
    r = await fetch(`${backendUrl}/productos/?limit=100`, {
      headers: { Authorization: autorizacion },
      signal: AbortSignal.timeout(ESPERA_MAX_MS),
    });
  } catch (_) {
    throw new ErrorInventario(502, 'El asistente no pudo contactar al backend de inventario. Revisa que esté encendido.');
  }
  if (r.status === 401) {
    throw new ErrorInventario(401, 'Tu sesión caducó. Inicia sesión de nuevo.');
  }
  if (!r.ok) {
    throw new ErrorInventario(502, `El backend de inventario respondió con un error (código ${r.status}).`);
  }
  const productos = await r.json();
  if (!Array.isArray(productos)) {
    throw new ErrorInventario(502, 'El backend de inventario devolvió un formato inesperado.');
  }
  return productos;
}

module.exports = { obtenerInventario, ErrorInventario, BACKEND_URL };
