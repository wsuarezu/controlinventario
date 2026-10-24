# Servidor del asistente de inventario

Servidor local del asistente de IA. **No forma parte de la app Flutter.** Es el único lugar donde vive la clave del proveedor de IA: la app solo conoce la dirección de este servidor (`LLM_BACKEND_URL`).

Tiene dos modos, según exista o no la variable de entorno `GEMINI_API_KEY` al encenderlo:

| Modo | Cuándo | Qué hace |
|---|---|---|
| **GEMINI** | Con `GEMINI_API_KEY` definida | Llama al modelo de Google con tu clave gratuita |
| **REGLAS** | Sin clave | Responde con reglas simples, sin internet; sirve si se agota la cuota del día |

En los dos modos, el servidor pide el inventario **al backend** con el token de la persona (`inventario-cliente.js`): la IA trabaja con los datos reales del usuario y el backend decide si el token es válido.

## Obtener la clave gratuita

1. Entra a <https://aistudio.google.com/apikey> con una cuenta de Google.
2. Pulsa **Create API key** y copia la clave.
3. **No la escribas en ningún archivo del proyecto ni la subas a git.** Se define solo en la terminal del servidor.

## Cómo se usa

Requiere Node.js 18 o superior y el backend de inventario encendido.

Windows (PowerShell):

```powershell
cd asistente-server
$env:GEMINI_API_KEY="pega-aquí-tu-clave"
node asistente-server.js
```

Linux y Mac:

```bash
cd asistente-server
export GEMINI_API_KEY="pega-aquí-tu-clave"
node asistente-server.js
```

El mensaje inicial indica el modo (`modo GEMINI` o `modo REGLAS`). Para pasar al modo reglas, cierra el servidor (`Ctrl + C`), borra la variable (`Remove-Item Env:GEMINI_API_KEY` en PowerShell, `unset GEMINI_API_KEY` en Bash) y vuelve a encenderlo.

Variables opcionales:

| Variable | Por defecto | Para qué |
|---|---|---|
| `GEMINI_MODEL` | `gemini-3.5-flash-lite` | Cambiar de modelo (por ejemplo, si Google lo retira) |
| `BACKEND_URL` | `http://127.0.0.1:8000` | Dirección del backend de inventario vista desde este servidor |
| `PORT` | `3000` | Puerto del servidor |

## Contrato

`POST /asistente`, con la cabecera `Authorization: Bearer <token>` (el mismo token de la app). El servidor **nunca la registra**; solo la reenvía al backend.

Petición:

```json
{ "consulta": "¿Qué productos debo reponer?" }
```

Respuesta:

```json
{ "respuesta": "Conviene reponer 4 producto(s): …", "modo": "gemini" }
```

Errores (siempre `{ "detail": "mensaje legible" }`, que la app muestra tal cual):

| Código | Cuándo |
|---|---|
| 400 | El cuerpo no es un JSON válido |
| 401 | Falta el token o el backend lo rechaza (sesión caducada) |
| 422 | Falta la consulta o pasa de 500 caracteres |
| 429 | Se agotó la cuota gratuita de la IA |
| 502 | El backend no responde, la clave fue rechazada o la IA devolvió algo inesperado |
| 504 | La IA tardó más de 15 segundos |

En modo GEMINI el servidor pide una respuesta estructurada (JSON) y la valida antes de enviarla: la salida del modelo es un dato, no código.

## Probar

Pruebas automáticas (sin red ni clave; también corren en la CI):

```bash
node --test asistente-server/asistente-server.test.js
```

Prueba de extremo a extremo, con el backend y el asistente encendidos:

```bash
node asistente-server/probar-e2e.js demo@inventario.com demo1234
```

Comprueba cuatro cosas, con ✅ o ❌: el backend está encendido, el inicio de sesión da un token, el backend devuelve el inventario y el asistente responde con ese inventario.

## URL de la app

- Emulador Android: `http://10.0.2.2:3000` (valor por defecto de `LLM_BACKEND_URL`).
- Teléfono por USB: `adb reverse tcp:3000 tcp:3000` y `--dart-define=LLM_BACKEND_URL=http://127.0.0.1:3000`.

## Seguridad

- La clave solo se lee de la variable de entorno; el servidor nunca la imprime ni la guarda, y viaja en una cabecera (no en la URL) hacia Google.
- El registro muestra el tamaño y los **nombres** de los campos recibidos y cuántos productos llegaron del backend; nunca el contenido, el token ni la clave.
- A Gemini solo viajan nombre, cantidad y mínimo de cada producto (ni ids ni datos del usuario).
- Si una clave se filtra, se crea otra en AI Studio y se desactiva la anterior.
