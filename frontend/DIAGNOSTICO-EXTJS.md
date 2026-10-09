# Diagnóstico Ext JS
Se ejecutó npm install con Node 24.21.0/npm 11.19.0 y una caché local aislada.
Resultado reproducido: instalación fallida, @sencha/ext 8.0.0, tier pro, activate.js:56, spawn EINVAL al lanzar el activador @sencha/ext-activator. También hubo EBUSY al intentar limpiar un directorio. El fallo ocurre antes de completar la activación; no demuestra por sí solo falta de licencia. No se alteró activate.js ni se omitieron scripts de licencia.
La documentación oficial: https://docs.sencha.com/extjs/8.0.0/guides/using_systems/using_npm/using_npm.html
Para retomar: revisar con Sencha compatibilidad de su activador Windows con Node/npm actuales y validar acceso/licencia de la cuenta. No bajar a una versión Node obsoleta como solución improvisada. El proyecto encontrado contiene package.json/webpack.config.js, pero no index.js ni los archivos completos de una app generada; resolver activación no basta para tener una app lista.
Alternativa temporal: backend/src/main/resources/static/login.html e index.html. Se ejecuta con Spring Boot, sesión y CSRF reales, sin npm. El proyecto Ext JS permanece conservado. Log local: hotel-manager-app/ext-install.log (excluido de Git).
