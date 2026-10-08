# Fido - Documentación Técnica (Español)

Este documento explica cómo funciona internamente `Fido.ps1` y qué cambios se aplicaron para portarlo a
PowerShell 7 (`pwsh`) en Linux y macOS.

* Versión en inglés: [TECHNICAL_DOC_EN.md](TECHNICAL_DOC_EN.md)
* Script: [`../Fido.ps1`](../Fido.ps1)
* Licencia: GPLv3 o posterior

---

## 1. Introducción

Fido es un script de PowerShell de un solo archivo que obtiene los enlaces oficiales de descarga de las
imágenes ISO de Windows (imágenes minoristas de Microsoft) y de imágenes UEFI Shell arrancables, utilizando
la API web pública de descargas de Microsoft, de modo que el usuario no tenga que pasar por el asistente de
descarga en el navegador.

Ofrece dos interfaces mutuamente excluyentes:

| Modo | Disparador | Interfaz | Plataformas |
|------|------------|----------|-------------|
| **GUI** | no se pasa ninguna opción de CLI | ventana WPF (XAML) | solo Windows |
| **CLI** | se pasa `-Win`, `-Rel`, `-Ed`, `-Lang`, `-Arch` o `-GetUrl` | consola | Windows, Linux, macOS |

## 2. Convenciones del archivo

* El archivo debe guardarse como **UTF-8 con BOM** y finales de línea **CRLF** (ver `.editorconfig` y
  `.gitattributes`). El BOM es lo que hace que Windows PowerShell use Unicode para las cadenas de la
  interfaz en lugar de ISO-8859-1.
* La indentación se hace con tabuladores.
* El script original incluye un bloque de firma Authenticode (`# SIG # Begin signature block`). En cuanto
  se modifica el script esa firma deja de ser válida, por lo que este port **eliminó el bloque de firma**.

## 3. Parámetros

Definidos en el bloque `param()` al principio del script:

| Parámetro | Tipo | Propósito |
|-----------|------|-----------|
| `AppTitle` | string | Título de la ventana GUI (por defecto `Fido - ISO Downloader`) |
| `LocData` | string | Cadenas de localización de la UI separadas por `\|`; el elemento 0 es la configuración regional (p. ej. `es-ES`) |
| `Locale` | string | Configuración regional forzada, por defecto `en-US`; también se usa para consultar la API de Microsoft |
| `Icon` | string | Ruta a un `.ico`/DLL usado como icono de la ventana (GUI) |
| `PipeName` | string | Nombre de un tubo con nombre (*named pipe*); si se indica, la URL de descarga se envía por él en lugar de abrir el navegador (lo usa Rufus) |
| `Win` | string | Versión de Windows, p. ej. `Windows 11` (`-Win List` las lista) - **activa el modo CLI** |
| `Rel` | string | Release de Windows, p. ej. `26H2` o `Latest` - **activa el modo CLI** |
| `Ed` | string | Edición de Windows, p. ej. `Pro` - **activa el modo CLI** |
| `Lang` | string | Idioma, p. ej. `English` - **activa el modo CLI** |
| `Arch` | string | Arquitectura, p. ej. `x64` - **activa el modo CLI** |
| `GetUrl` | switch | Solo imprime la URL de descarga, no descarga - **activa el modo CLI** |
| `PlatformArch` | string | Fuerza la arquitectura nativa de la CPU (omite la autodetección) |
| `Verbose` | switch | Pone la verbosidad en 2 (registra cada URL consultada) |
| `Debug` | switch | Pone la verbosidad en 5 (además vuelca las respuestas JSON en bruto) |

Niveles de verbosidad: `0` (silencioso, con `-GetUrl`), `1` (por defecto), `2` (`-Verbose`), `5` (`-Debug`).

## 4. Flujo del programa

### 4.1 Arranque

1. Se fuerza `[Console]::OutputEncoding` a UTF-8 (aunque mejor esfuerzo).
2. `$Cmd` pasa a `$true` en cuanto aparece cualquier opción de CLI.
3. `Get-Platform-Version()` devuelve una versión decimal de Windows (`10.0`, `6.1`, ...) en hosts Windows y
   **`0.0` en Linux/macOS**. Este único valor es el que usa todo el script para saber si está en Windows:
   * `$winver -lt 10.0` + `$winver -ne 0.0` → Windows 8.x, se fuerza TLS 1.0/1.1/1.2 (nunca se aplica en Linux).
   * `$winver -ne 0.0 -and $winver -le 6.1` → Windows 7 se rechaza (`exit 403`).
   * `$winver -eq 0.0` → host no Windows.
4. `Get-Arch()` detecta la arquitectura nativa de la CPU:
   * Windows: `Get-CimInstance Win32_Processor | Architecture` (0 = x86, 9 = x64, 12 = ARM64).
   * Linux/macOS (o cuando `Get-CimInstance` no existe, como ocurre en algunas compilaciones de
     PowerShell 7): `[System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture` →
     `x86` / `x64` / `arm` / `arm64`.

### 4.2 Selección de modo

* **No Windows + sin opción de CLI** → el script imprime un mensaje de uso y sale con `403`, porque WPF
  (`PresentationFramework`) no existe fuera de Windows.
* **Windows + sin opción de CLI** → se cargan el ensamblado WPF y el helper C# `WinAPI.Utils` (que hace
  P/Invoke a `shell32.dll!ExtractIconEx` y `user32.dll!ShowWindow`) y se muestra la ventana del asistente.
* **Cualquier plataforma + opción de CLI** → se ejecuta la ruta de línea de comandos (sección 4.4) y el
  script termina antes de evaluar el código XAML.

### 4.3 Modo GUI (solo Windows)

La ventana está declarada como XAML en línea (`[xml]$XAML`, un `Grid` con el par de botones
`Continue`/`Back`, un `TextBlock` de título, un `ComboBox` y un `CheckBox` oculto). El asistente es una
máquina de estados guiada por `$Stage` (`0`..`5`):

| `$Stage` | Acción al pulsar *Continue* |
|----------|------------------------------|
| 0 | Elegir la versión de Windows (`$WindowsVersions`) |
| 1 | `Check-Locale()` + `Get-Windows-Releases()` |
| 2 | `Get-Windows-Editions()` |
| 3 | `Get-Windows-Languages()` (red) |
| 4 | `Get-Windows-Download-Links()` (red) |
| 5 | `Process-Download-Link()` y cerrar la ventana |

`Add-Entry()` inserta un nuevo par etiqueta/`ComboBox` en la cuadrícula y desplaza los botones hacia abajo
`$dh` (58 px) por fila; `Back` vuelve a eliminar el último par (`RemoveAt`) y decrementa `$Stage`.

### 4.4 Modo línea de comandos

Una cascada estricta, donde cada paso valida el anterior y sale con `1` si el valor no se encuentra (o si se
pidió `List`, que es un comportamiento deliberado de "imprimir y salir"):

```
-Win  → $WindowsVersions          → releases (Get-Windows-Releases)
      → ediciones (Get-Windows-Editions)
      → idiomas (Get-Windows-Languages)                 [red]
      → enlaces de descarga (Get-Windows-Download-Links) [red]
      → -GetUrl: imprime la URL | en otro caso: descarga
```

* Los valores ausentes se rellenan con la primera entrada/selección automática (la configuración regional
  del sistema se usa para elegir idioma mediante `Select-Language()` y la arquitectura nativa de la CPU
  para elegir el enlace de descarga).
* Si falla la obtención de idiomas o de enlaces, se sale con `3`.
* `Error()` sale con `2` en modo CLI (solo manipula el título de la ventana/el cuadro de diálogo en GUI).

### 4.5 Modelo de datos

`$WindowsVersions` es un array anidado. El elemento `[0]` de cada entrada es `@(nombre visible, id de
página)`; el resto son releases, y cada release es
`@(nombre del release, @(nombre de edición, productEditionId)...)`:

```powershell
@(
  @("Windows 11", "windows11"),
  @(
    "26H2 (Build 26300.9457 - 2026.09)",
    @("Windows 11 Home/Pro/Edu", @(3813, 3816)),   # 2 IDs porque los SKU ARM64 son distintos
    @("Windows 11 Home China ", @(3814, 3817))
  )
),
@("UEFI Shell 2.2", "UEFI_SHELL 2.2"), ...
```

Existen dos identificadores de página especiales: `UEFI_SHELL 2.2` y `UEFI_SHELL 2.0`, que no hablan con
Microsoft en absoluto.

## 5. El "apretón de manos" con la API de Microsoft

Por cada *productEditionId* de la edición seleccionada, `Get-Windows-Languages()` crea un GUID de
`$SessionId` nuevo (Microsoft solo respeta una sesión activa por arquitectura, de ahí el array de 2
elementos de `$SessionId`) y ejecuta, en orden:

1. **Blanqueo de la sesión**
   `https://vlscppe.microsoft.com/tags?org_id=y6jn8c31&session_id=<guid>`
2. **Reto de detección de fraude**
   `https://ov-df.microsoft.com/mdt.js?instanceId=560dc9f3-1aa5-4a2f-b63c-9e18f8d0e175&PageId=si&session_id=<guid>`
   → la respuesta JavaScript se recorta con dos regex para obtener `w` y `rticks`.
3. **Respuesta al reto de fraude**
   `https://ov-df.microsoft.com/?session_id=<guid>&CustomerId=<instanceId>&PageId=si&w=<w>&mdt=<época ms>&rticks=<rticks>`
4. **Listado de idiomas/SKU**
   `https://www.microsoft.com/software-download-connector/api/getskuinformationbyproductedition`
   `?profile=606624d44113&productEditionId=<id>&SKU=undefined&friendlyFileName=undefined&Locale=<locale>&sessionID=<guid>`
   → devuelve `Skus[]` con `Id`, `Language` y `LocalizedLanguage`. Se reintenta dos veces (con 2 s de
   separación) porque el endpoint es inestable.

Después, en `Get-Windows-Download-Links()`, por cada SKU del idioma seleccionado:

5. **Enlaces de descarga**
   `https://www.microsoft.com/software-download-connector/api/GetProductDownloadLinksBySku`
   `?profile=606624d44113&productEditionId=undefined&SKU=<skuId>&friendlyFileName=undefined&Locale=<locale>&sessionID=<guid>`
   * hay que enviarlo con la cabecera `Referer: https://www.microsoft.com/software-download/windows11`;
   * devuelve `ProductDownloadOptions[]`, donde `DownloadType` se traduce a una arquitectura mediante
     `Get-Arch-From-Type()` (`0 → x86`, `1 → x64`, `2 → ARM64`) y `Uri` es la URL directa del ISO.

Llamadas de apoyo:

* `Check-Locale()` (GUI) sondea `https://www.microsoft.com/<locale>/software-download/windows11` y vuelve a
  `en-US` si esa configuración regional no está servida.
* `Get-Code-715-123130-Message()` vuelve a leer esa misma página y extrae el mensaje localizado del
  bloqueo desde el elemento oculto `<input id="msg-01">`.

Manejo de errores del paso 5:

| Respuesta del servidor | Reacción del script |
|------------------------|---------------------|
| `Type: 9` (código `715-123130`) | mensaje localizado de "su IP ha sido baneada" + ID de sesión |
| `Key: ErrorSettings.SentinelReject` | **añadido en este port**: mensaje explícito de "Microsoft ha rechazado esta dirección IP" con recomendaciones |
| cualquier otro | se reporta el `Errors[0].Value` en bruto |

### 5.1 Imágenes UEFI Shell

Cuando el id de página seleccionado empieza por `UEFI_SHELL`, el script se salta Microsoft y consulta
`https://github.com/pbatard/UEFI-Shell/releases/download/<tag>/Version.xml` para conocer las arquitecturas
soportadas, construyendo una URL de la forma
`UEFI-Shell-<versión>-<tag>-RELEASE.iso` (o `-DEBUG.iso`).

## 6. Localización

* `$EnglishMessages` es una lista de cadenas de la UI separadas por `|`; `Get-Translation()` busca el índice
  de la cadena en inglés y devuelve la entrada `$Localized` correspondiente (proporcionada mediante
  `-LocData`), rellenando o recortando el array para que una localización parcial nunca rompa la interfaz.
* `Select-Language()` asocia `CurrentUICulture` del sistema con el nombre de idioma de Microsoft para que el
  idioma correcto venga preseleccionado en el asistente / como valor por defecto en CLI.

## 7. Descarga (`Process-Download-Link`)

Orden de preferencia:

1. **Se indicó `-PipeName`** → la URL se escribe en un tubo con nombre (`Send-Message`) para que una
   aplicación padre (Rufus) la descargue. Un `CheckBox` añadido en la etapa 4 permite al usuario anularlo y
   abrir el navegador.
2. **Modo CLI** → se sondea el tamaño con una petición `HEAD` (`Content-Length`, solo informativo y ahora no
   fatal), y después:
   * `Start-BitsTransfer` si el cmdlet BITS existe (**Windows**);
   * `Invoke-WebRequest -OutFile` en caso contrario (**Linux/macOS** y PowerShell 7 sin BITS).
3. **Modo GUI** → `Start-Process <url>` abre el navegador predeterminado.

## 8. Códigos de salida

| Código | Significado |
|--------|-------------|
| `0` | Éxito (descarga terminada, o `-GetUrl` imprimió la URL) |
| `1` | Valor de parámetro inválido/desconocido, o se pidió `List` |
| `2` | Se activó `Error()` en modo CLI |
| `3` | No se pudieron obtener los idiomas o los enlaces de descarga de Microsoft |
| `100` | Valor inicial: se cerró la ventana sin descargar (GUI) |
| `403` | Plataforma no soportada (Windows 7), o modo GUI solicitado en Linux/macOS |
| `404` | La propia descarga falló |

Nota: `pwsh -File` reporta los códigos de salida módulo 256, así que `403` aparece como `147` en
`$?`/`$LASTEXITCODE`.

## 9. El port a Linux/macOS

El script se portó *in situ* (sin crear una copia) para que un único archivo siga funcionando en todas las
plataformas.

### 9.1 Cambios

| # | Ubicación | Comportamiento en Windows | Comportamiento en Linux/macOS |
|---|-----------|---------------------------|-------------------------------|
| 1 | Comentario de cabecera | — | Documenta que el script también corre bajo `pwsh` |
| 2 | Bloque TLS | Fuerza TLS 1.0/1.1/1.2 en Windows < 10 | Se omite (`$winver -ne 0.0`) y se envuelve en `try/catch`; PowerShell 7 ya usa TLS 1.2+ |
| 3 | Arranque de la GUI | Carga `PresentationFramework` + `WinAPI.Utils` | Imprime un mensaje de uso y sale con `403` antes de cargar nada específico de Windows |
| 4 | `Get-Arch()` | `Get-CimInstance Win32_Processor` | Usa `RuntimeInformation.OSArchitecture` como respaldo; también protege a los hosts Windows sin cmdlets CIM |
| 5 | Comprobaciones de plataforma (`$winver -le 6.1`) | Rechaza Windows 7 | Solo se evalúa en Windows, de modo que `0.0` (no Windows) ya no dispara el rechazo |
| 6 | `Process-Download-Link()` | `Start-BitsTransfer` | Detecta el cmdlet en tiempo de ejecución y usa `Invoke-WebRequest -OutFile`; la petición `HEAD` del tamaño ya no es fatal |
| 7 | Manejo de `SentinelReject` | cadena de error en bruto | mensaje amigable y accionable (bloqueo por IP + qué hacer) |
| 8 | Bloque de firma | firmado con Authenticode | eliminado (queda inválido tras cualquier modificación) |

El resto (parámetros, modelo de datos, apretón de manos con la API, localización, lógica del asistente) no
cambia.

### 9.2 Limitaciones conocidas en Linux/macOS

* No hay interfaz gráfica: hay que usar las opciones de línea de comandos (`-Win`, `-Rel`, `-Ed`, `-Lang`,
  `-Arch`, `-GetUrl`).
* Las descargas corren dentro del proceso de PowerShell, así que no hay reanudación de BITS; si se cae la
  conexión hay que empezar la descarga de nuevo.
* `-Icon` y `-PipeName` son funcionalidades centradas en Windows (GUI / integración con Rufus) y allí no se
  pueden usar.
* Microsoft puede rechazar las peticiones de enlace de ISO desde una dirección IP dada
  (`Sentinel marked this request as rejected.` / `715-123130`). Es un bloqueo del lado del servidor y por
  IP: también afecta a navegadores y otras herramientas, y el script solo puede reportarlo y sugerir
  esperar, cambiar de red o descargar manualmente desde
  <https://www.microsoft.com/software-download>.

### 9.3 Verificación realizada

Todo lo siguiente se ejecutó con PowerShell 7.6.4 en Linux x86_64:

```text
pwsh -NoProfile -File ./Fido.ps1                     → mensaje de uso, exit 403 (protección de GUI)
pwsh -NoProfile -File ./Fido.ps1 -Win List           → 4 versiones listadas
pwsh -NoProfile -File ./Fido.ps1 -Win 11 -Rel List   → release 26H2 listada
pwsh -NoProfile -File ./Fido.ps1 -Win 11 -Rel Latest -Ed List        → ediciones listadas
pwsh -NoProfile -File ./Fido.ps1 -Win 11 -Rel Latest -Ed Pro -Lang List  → 40+ idiomas (apretón de manos de API OK)
pwsh -NoProfile -File ./Fido.ps1 ... -GetUrl         → bloqueado por el filtro de IP de Microsoft (esperado aquí), mensaje amigable
pwsh -NoProfile -File ./Fido.ps1 -Win "UEFI Shell 2.2" -Rel Latest -Ed Release -Lang en -Arch x64
                                                      → ISO de 21 MB descargado y verificado (exit 0)
[System.Management.Automation.Language.Parser]::ParseFile(...) → sin errores de sintaxis
```
