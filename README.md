# Dusklight iOS bundle (privado)

Compila Dusklight v2.0.3 para iOS con mods nativos incluidos dentro de la app, porque en iOS
los mods con código no se pueden instalar sueltos.

- `mods.txt`: lista de mods (id + versión). Se descargan de twilitrealm.dev y se usa su
  binario de iOS (`lib/ios-arm64/mod.so`). Para usar un archivo propio, poné `mods/<id>.dusk`.
- TP Compass se compila desde el código de `Zeuqram-R/tp-compass-mod`.
- Cada push a `main` (o "Run workflow" en Actions) genera un IPA en *Releases*.

Para agregar o actualizar un mod: editá su línea en `mods.txt` y hacé commit.
Repo privado: los mods de terceros no tienen licencia para redistribuirse públicamente.
