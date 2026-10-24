# AGENTS.md — reglas del proyecto Control de Inventario

Este archivo lo leen los agentes de código (Claude Code, Codex, Antigravity…) al abrir esta carpeta. Es el **archivo de contexto** del proyecto: lo que un agente nuevo necesita saber para trabajar bien aquí. Se mantiene corto y concreto.

## Qué es el proyecto

Control de Inventario es una app Flutter (Android) para llevar el stock de productos de un pequeño negocio: registrar productos, ajustar existencias, ver cuáles están bajo el mínimo y preguntarle a un asistente de IA qué conviene reponer.

- Estado con GetX; datos remotos con `dio` contra un backend FastAPI con JWT
  (repositorio aparte: <https://github.com/wsuarezu/proyecto-integrador-speckit>).
- Token en `flutter_secure_storage`; caché offline y favoritos en Hive.
- Asistente de IA a través de un servidor propio en `asistente-server/` (Node), que es el único que conoce la clave del proveedor de modelos.

## Dónde está cada cosa

- `lib/controllers/` — estado compartido (controladores GetX).
- `lib/repositories/` — orquestan servicios remotos y almacenamiento local.
- `lib/services/` — acceso al backend (`ApiClient`), al asistente y a Hive / almacenamiento seguro.
- `lib/screens/` y `lib/widgets/` — pantallas y piezas de interfaz.
- `lib/models/`, `lib/config/`, `lib/theme/`, `lib/utils/` — modelos, configuración, tema y utilidades.
- `asistente-server/` — proxy de IA (Node 18+, sin dependencias).
- `test/` — pruebas de widgets y de servicios.
- `docs/` — enunciado del Proyecto Final y documentación técnica.

## Cómo verificar (siempre, antes de dar un cambio por terminado)

```bash
flutter analyze
flutter test
```

Los dos deben terminar sin errores. Si fallan, corrige el código; no desactives el análisis ni borres pruebas para que pasen.

## Convenciones

- Capas: pantalla → controlador GetX → repositorio → servicio → fuente de datos. Ninguna pantalla llama directamente a HTTP ni a Hive.
- El estado compartido vive en un `GetxController`; `setState` solo para estado local de un formulario.
- Todos los errores HTTP se traducen a `ApiException` con mensajes distintos para 400, 401, 403, 404, 422, 5xx, tiempo de espera y sin conexión.
- Cada pantalla con datos cubre los tres estados: cargando, vacío y error.
- Las URL se pasan con `--dart-define` (`API_BASE_URL`, `LLM_BACKEND_URL`); la app no contiene claves.
- Todo texto visible para la persona va en español neutro. Los nombres de clases, funciones y variables van en español.

## Prohibido

- Escribir claves, tokens o contraseñas en el código, en los registros o en este archivo. No leer ni modificar `.env` ni `asistente-server/.env`.
- Registrar el encabezado `Authorization` o el token en cualquier log.
- Agregar dependencias nuevas sin avisar antes y explicar por qué hacen falta.
- Ejecutar `git commit`, `git push` o crear etiquetas: eso lo hace la persona después de revisar el cambio.
