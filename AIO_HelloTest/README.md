# AIO HelloTest

Script de prueba para verificar que **AIO v1.75** funciona correctamente con **mod-ale** en AzerothCore WotLK 3.3.5a.

---

## ¿Para qué sirve?

Confirma que la comunicación servidor → cliente y cliente → servidor está operativa después de instalar AIO. Muestra una ventana en el cliente con un botón **Ping Server** que responde con el timestamp del servidor.

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)
- [AIO v1.75](https://github.com/Rochet2/AIO) — servidor en `lua_scripts/AIO_Server/`, cliente en `WoW/Interface/AddOns/AIO_Client/`

---

## Instalación

```
AIO_HelloTest.lua  →  <server>/lua_scripts/
```

```
.reload ale
```

---

## Uso

En el chat del juego:
```
.aiotest
```

Aparecerá una ventana con el texto **"¡AIO funciona con mod-ale!"** y un botón **Ping Server**. Al hacer clic, el servidor responde con su timestamp — si aparece la respuesta, AIO está funcionando correctamente.
