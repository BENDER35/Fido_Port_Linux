Fido: Un script de PowerShell para descargar ISOs de Windows y UEFI Shell
==========================================================================

[![Licencia](https://img.shields.io/badge/license-GPLv3-blue.svg?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![Estadísticas de GitHub](https://img.shields.io/github/downloads/pbatard/Fido/total.svg?style=flat-square)](https://github.com/pbatard/Fido/releases)

[English](README.md) | **Español**

port a linux por IA by BENDER (bajo opencode)

Descripción
-----------

Fido es un script de PowerShell que está pensado principalmente para usarse en [Rufus](https://github.com/pbatard/rufus),
pero que también puede usarse de forma independiente, y cuyo propósito es automatizar el acceso a los enlaces oficiales
de descarga de las imágenes ISO minoristas de Microsoft Windows, así como facilitar el acceso a
[imágenes UEFI Shell arrancables](https://github.com/pbatard/UEFI-Shell).

Este script existe porque, aunque Microsoft pone los enlaces de descarga de ISOs minoristas de forma libre y pública
(al menos desde Windows 8 hasta Windows 11), hasta las versiones recientes la mayoría de estos enlaces solo estaban
disponibles tras hacer saltar a los usuarios por una cantidad de trabas injustificadas que creaban una experiencia
de consumidor excesivamente contraproducente, si no directamente antipática, y que restaba mucho de lo que la gente
realmente quiere (acceso directo a las descargas de ISOs).

En cuanto a por qué se podría querer descargar las ISOs de Windows __minoristas__, en lugar de las ISOs que genera la
herramienta Media Creation Tool (MCT) de Microsoft, es porque usar las ISOs oficiales minoristas es actualmente la
única forma de afirmar con absoluta certeza que el contenido del sistema operativo no ha sido alterado. Efectivamente,
como solo existe un máster para cada una de ellas, las ISOs minoristas de Microsoft son las únicas de las que puedes
obtener un SHA-1 oficial (desde MSDN, si tienes acceso, o desde sitios [como este](https://msdn.rg-adguard.net/public.php))
que te permite estar 100% seguro de que la imagen que estás usando no está corrompida y es segura de usar.

Esto, a su vez, te da la garantía de que el contenido que __TÚ__ estás usando para instalar tu sistema operativo —lo
cual es realmente crítico validar de antemano si tienes la más mínima preocupación por la seguridad— coincide, bit a
bit, con el que publicó Microsoft.

Por otro lado, independientemente de la manera en que la Media Creation Tool de Microsoft produce su contenido, como
nunca dos ISOs del MCT son iguales (debido a que el MCT siempre regenera el contenido del ISO sobre la marcha), es
actualmente imposible validar con absoluta certeza si una ISO generada por el MCT es segura de usar. Especialmente,
a diferencia de lo que ocurre con las ISOs minoristas, es imposible saber si una ISO del MCT pudo haberse corrompido
después de su generación.

De ahí la necesidad de proporcionar a los usuarios una forma mucho más fácil y menos restrictiva de acceder a las ISOs
minoristas oficiales...

Licencia
--------

[GNU General Public License versión 3.0](https://www.gnu.org/licenses/gpl-3.0) o posterior.

Cómo funciona
-------------

El script realiza básicamente la misma operación que uno haría al visitar la siguiente URL (eso sí, en el caso de
Windows 10, siempre que hayas cambiado también la cadena `User-Agent` de tu navegador, ya que los servidores web de
Microsoft detectan que estás usando una versión de Windows igual a la que intentas descargar y pueden redirigirte
__fuera__ de la página que te permite obtener un enlace de descarga directa del ISO):

https://www.microsoft.com/en-us/software-download

Tras comprobar el acceso básico al sitio web de descargas de Microsoft, el script consulta primero la API web de los
servidores de Microsoft para pedir la selección de idiomas disponibles para la versión de Windows elegida, y después
solicita los propios enlaces de descarga, para todas las arquitecturas disponibles para ese idioma + versión.

Requisitos
----------

* **Windows**: Windows 8 o posterior con Windows PowerShell 5.1 o posterior. Windows 7 __no__ está soportado.
  Tanto la interfaz gráfica como el modo de línea de comandos están disponibles.
* **Linux / macOS**: PowerShell 7 o posterior (`pwsh`) - consulta [Instalar PowerShell en Linux](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux)
  o [en macOS](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-macos).
  Solo está disponible el modo de línea de comandos, ya que la interfaz gráfica se basa en WPF, que es exclusivo de Windows.

Documentación técnica (inglés/español): [docs/TECHNICAL_DOC_EN.md](docs/TECHNICAL_DOC_EN.md) -
[docs/TECHNICAL_DOC_ES.md](docs/TECHNICAL_DOC_ES.md).

Modo de línea de comandos
-------------------------

Fido admite modo de línea de comandos: cuando se proporciona alguna de las siguientes opciones, no se crea ninguna
interfaz gráfica y puedes generar la descarga del ISO desde una consola o un script de PowerShell.

Ten en cuenta, no obstante, que desde 2023.05 Microsoft ha eliminado el acceso a versiones anteriores de las ISOs de
Windows y, como resultado, la lista de releases que se pueden descargar con Fido se ha tenido que reducir a solo la
más reciente de cada versión.

Las opciones son:
- `Win`: Especifica la versión de Windows (p. ej. _"Windows 10"_). También deberían funcionar versiones abreviadas
   (p. ej. `-Win 10`) siempre que sean lo suficientemente únicas. Si no se especifica esta opción, se selecciona
   automáticamente la versión más reciente de Windows.
   Puedes obtener una lista de las versiones soportadas con `-Win List`.
- `Rel`: Especifica el release de Windows (p. ej. _"21H1"_). Si no se especifica esta opción, se selecciona
   automáticamente el release más reciente para la versión de Windows elegida. También puedes usar `-Rel Latest` para
   forzar el uso del más reciente.
   Puedes obtener una lista de las versiones soportadas con `-Rel List`.
- `Ed`: Especifica la edición de Windows (p. ej. _"Pro/Home"_). También deberían funcionar ediciones abreviadas
   (p. ej. `-Ed Pro`) siempre que sean lo suficientemente únicas. Si no se especifica esta opción, se selecciona
   automáticamente la versión más reciente de Windows.
   Puedes obtener una lista de las versiones soportadas con `-Ed List`.
- `Lang`: Especifica el idioma de Windows (p. ej. _"Arabic"_). Deberían funcionar idiomas abreviados o parciales
   (p. ej. `-Lang Int` por `English International`) siempre que sean lo suficientemente únicos. Si no se especifica
   esta opción, el script intenta seleccionar el mismo idioma que la configuración regional del sistema.
   Puedes obtener una lista de los idiomas soportados con `-Lang List`.
- `Arch`: Especifica la arquitectura de Windows (p. ej. _"x64"_). Si no se especifica esta opción, el script intenta
   usar la misma arquitectura que la del sistema actual.
- `GetUrl`: Por defecto, el script intenta lanzar la descarga automáticamente. Pero al usar el interruptor `-GetUrl`,
   el script solo muestra la URL de descarga, que luego se puede redirigir a otro comando o a un archivo.

Ejemplos de descarga por línea de comandos:

```
PS C:\Projects\Fido> .\Fido.ps1 -Win 10
No release specified (-Rel). Defaulting to '21H1 (Build 19043.985 - 2021.05)'.
No edition specified (-Ed). Defaulting to 'Windows 10 Home/Pro'.
No language specified (-Lang). Defaulting to 'English International'.
No architecture specified (-Arch). Defaulting to 'x64'.
Selected: Windows 10 21H1 (Build 19043.985 - 2021.05), Home/Pro, English International, x64
Downloading 'Win10_21H1_EnglishInternational_x64.iso' (5.0 GB)...
PS C:\Projects\Fido> .\Fido.ps1 -Win 10 -Rel List
Please select a Windows Release (-Rel) for Windows 10 (or use 'Latest' for most recent):
 - 21H1 (Build 19043.985 - 2021.05)
 - 20H2 (Build 19042.631 - 2020.12)
 - 20H2 (Build 19042.508 - 2020.10)
 - 20H1 (Build 19041.264 - 2020.05)
 - 19H2 (Build 18363.418 - 2019.11)
 - 19H1 (Build 18362.356 - 2019.09)
 - 19H1 (Build 18362.30 - 2019.05)
 - 1809 R2 (Build 17763.107 - 2018.10)
 - 1809 R1 (Build 17763.1 - 2018.09)
 - 1803 (Build 17134.1 - 2018.04)
 - 1709 (Build 16299.15 - 2017.09)
 - 1703 [Redstone 2] (Build 15063.0 - 2017.03)
 - 1607 [Redstone 1] (Build 14393.0 - 2016.07)
 - 1511 R3 [Threshold 2] (Build 10586.164 - 2016.04)
 - 1511 R2 [Threshold 2] (Build 10586.104 - 2016.02)
 - 1511 R1 [Threshold 2] (Build 10586.0 - 2015.11)
 - 1507 [Threshold 1] (Build 10240.16384 - 2015.07)
PS C:\Projects\Fido> .\Fido.ps1 -Win 10 -Rel 20H2 -Ed Edu -Lang Fre -Arch x86 -GetUrl
https://software-download.microsoft.com/db/Win10_Edu_20H2_v2_French_x32.iso?t=c48b32d3-4cf3-46f3-a8ad-6dd9568ff4eb&e=1629113408&h=659cdd60399584c5dc1d267957924fbd
```

Uso en Linux y macOS
---------------------

El script se ejecuta bajo PowerShell 7+ (`pwsh`), pero solo en **modo de línea de comandos**, porque la interfaz
gráfica depende de WPF (`PresentationFramework`), que Microsoft no proporciona fuera de Windows. Invocar el script sin
ninguna de las opciones de línea de comandos en Linux/macOS mostrará por tanto un breve mensaje de uso y terminará con
el código `403`.

Uso típico:

```bash
# Debian/Ubuntu
sudo apt-get install -y wget gpg
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get install -y powershell

# Fedora
sudo dnf install -y powershell

# Arch
yay -S powershell-bin

# macOS
brew install --cask powershell

# Listar las versiones de Windows disponibles
pwsh ./Fido.ps1 -Win List

# Solo mostrar la URL de descarga directa (sin descargar)
pwsh ./Fido.ps1 -Win 11 -Rel Latest -Ed Pro -Lang English -Arch x64 -GetUrl

# Descargar el ISO en el directorio actual
pwsh ./Fido.ps1 -Win 11 -Rel Latest -Ed Pro -Lang English -Arch x64
```

Notas sobre el port a Linux/macOS:

* **Detección de arquitectura**: WMI/CIM (`Get-CimInstance Win32_Processor`) no existe fuera de Windows, por lo que la
  arquitectura nativa de la CPU se lee desde
  `[System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture`. Aun así puedes forzarla con
  `-PlatformArch x64|x86|ARM64` si quieres omitir la detección.
* **Descargas**: `Start-BitsTransfer` (BITS) es una tecnología exclusiva de Windows. Cuando no está disponible, el
  script usa como alternativa `Invoke-WebRequest -OutFile`, que es lo que ocurre en Linux/macOS.
* **TLS**: el solución temporal de forzar TLS 1.0/1.1/1.2 para Windows 8.x solo se aplica en hosts Windows;
  PowerShell 7 ya usa TLS 1.2 o posterior en el resto de plataformas.
* **Firma Authenticode**: el script original está firmado con Authenticode para Windows. El port ha eliminado el bloque
  de firma, ya que de lo contrario se reportaría como inválido en cuanto se modifica el script.
* **Bloqueos de IP de Microsoft**: Microsoft puede rechazar temporalmente entregar enlaces de ISO desde tu dirección
  IP (errores como `Sentinel marked this request as rejected.` o el código `715-123130`). Se trata de una restricción
  por IP aplicada del lado de Microsoft que también afecta a navegadores y otras herramientas de descarga: espera un
  tiempo, cambia de red, o descarga el ISO manualmente desde
  https://www.microsoft.com/software-download

Firma de releases (sign.sh)
---------------------------

`sign.sh` genera el contenido LZMA que descarga Rufus (`Fido.ps1.lzma`) junto con su firma RSA
(`Fido.ps1.lzma.sig`). Funciona en Linux y en MSYS2/Git Bash:

```bash
# Las rutas de las claves por defecto son de Windows, así que indícale las claves al ejecutarlo en Linux
PRIVATE_KEY=/path/to/private.pem PUBLIC_KEY=/path/to/public.pem ./sign.sh
```

Qué hace, en orden:

1. Firma **Authenticode** de `Fido.ps1`, usando el `signtool` de Windows SDK y el certificado EV de Akeo.
   Este paso requiere Windows y se omite con un aviso cuando `signtool` no está disponible (nunca se usa un
   `signtool` cualquiera del `$PATH` de Linux).
2. Pide la frase de paso de la clave privada y la valida antes de tocar ningún archivo.
3. Comprime `Fido.ps1` con `lzma` e inserta el tamaño sin comprimir de 64 bits en little endian en el offset 5,
   que es lo que espera el decodificador LZMA de Rufus, y después vuelve a leer ese valor para comprobarlo.
4. Crea - o actualiza, cuando la existente falta o está obsoleta - la firma RSA-SHA256 `Fido.ps1.lzma.sig` y la
   verifica con la clave pública.

Tanto `*.sig` como `*.lzma` son artefactos de compilación y git los ignora. Las rutas de las claves, la ubicación de
`signtool` y la huella digital del certificado se pueden sobreescribir con las variables de entorno `PRIVATE_KEY`,
`PUBLIC_KEY`, `SIGNTOOL` y `SHA1_THUMBPRINT`.

Notas adicionales
-----------------

Debido a su uso previsto con Rufus, este script no está diseñado para cubrir todas las descargas posibles de ISOs
minoristas. En su lugar, hemos elegido principalmente las que el público general probablemente solicite. Por ejemplo,
actualmente no tenemos planes de añadir soporte para descargas de ISOs Windows LTSB/LTSC.

Si estás interesado en ese tipo de descargas, se te invita amablemente a visitar las páginas de descarga relevantes de
Microsoft, como [esta](https://www.microsoft.com/evalcenter/evaluate-windows-10-enterprise) para las versiones LTSC.

ATENCION, AVISO (12 de octubre de 2026): microsoft cortara el acceso a partir
del 19 de junio del 2027 el acceso a windows update a todos los equipos que
tengan windows 10 sin ESU hacia abajo (el bloqueo anterior fue hasta windows
vista-server 2008 sin R2), esto logicamente afecta a las versiones de servidor
(server 2008 R2 hasta server 2019, a partir de server 2022, no afecta el cierre
de windows update), esto es debido a la caducidad de los certificados raiz
del servicio de actualizaciones que caduca a partir de esta fecha, si quieres
echar un vistazo al link oficial de la noticia de microsoft, aqui te lo paso (usa la traduccion del navegador, esta en ingles):

https://techcommunity.microsoft.com/blog/windows-itpro-blog/prepare-for-windows-update-certificate-rotation-in-2027/4562463

recuerda que los certificados raiz forman parte de la navegacion por internet, una de las caracteristicas del protocolo https
es que ahora todo lo que se transfiere al router esta cifrado (anteriormente no era asi), pero para que programas que se uti
lizan para analizar todo lo que se transfiere en una red domestica como wireshark no surta ningun efecto (no se vea ningun
dato sensible), los certificados raiz deben de funcionar y estar al dia, si no funciona, da error de certificado en el navegador
y los programas que conectan a internet dejaran de funcionar, esto lo tienes que tener en cuenta a la hora de utilizar un windows
antiguo instalado en el ordenador (por cierto, el cierre de windows update tambien afecta a las maquinas virtuales, o sea, a los PCs
arrancados dentro de un equipo fisico).

cuando llegue la fecha de caducidad del certificado raiz es posible que en los offices instalados en windows sin soporte den errores
de comprobacion de actualizaciones (hasta 10 y server 2019 que son cliente y servidor respectivamente se puede instalar el 2021-365
7 y 8, hasta office 2016), solucionandose esto desactivando las actualizaciones de office (cuando llegue la fecha de caducidad de
dichos certificados raiz).

en la ventana anterior (las actualizaciones automaticas se impusieron a partir de windows 2000) no dio ningun tipo de fallo a la
hora de arrancar el sistema operativo, unicamente a la hora de abrir la pagina de microsoft update o iniciar el windows update.
(pase la experiencia de la ventana anterior de cierre del update).

en el caso de que sea windows 10 con ESU, windows 11 24H2, servers LTSC de 2019 y 2016 y server 2022, microsoft ha puesto como
metodo oficial para solucionar el problema, la actualizacion, o sea, que tendras que actualizar el segundo martes de cada mes
hasta la fecha del 19 de junio de 2027 en el cual ya...piano, piano (entenderas lo que te digo).

en el caso de que te encuentres con este tipo de equipos, estos son los caminos que tienes:

-  comprar el ESU (windows 10) (en el caso de paises de la union europea, no tiene ningun coste) 
-  parchear el update para acceder al ESU, que el unico parche (y recomendable para windows 10) es el MAS (microsoft activation script)
-  instalar un parche no oficial para actualizar los certificados raiz, que es el legacy update
-  en el caso de versiones compatibles (no es obligatorio por el momento a partir de 11 24H2, windows 10 sin ESU es imprescindible
a medias) aceptar las actualizaciones a versiones mayores de windows via update o haciendo una actualizacion desde los medios de
instalacion de windows.
-  mantener la instalacion de windows y hacer un dual boot con linux (no aconsejable).
-  desinstalar windows e instalar linux junto con una maquina virtual de windows (ahi se permite todo, desde originales hasta modificados)

en el caso de que elijas la opcion sensata (la ultima), recuerda que debes de montar vmware o virtualbox en linux (instala linux en el ordenador
logicamente) y la maquina virtual con el windows a elegir (que ahi si puedes instalar windows antiguos) de manera oficial hasta junio de 2027, posteriormente
no va a funcionar y solo vas a poder instalar y actualizar este tipo de PCs por metodos no oficiales.

en el caso de que hayas perdido tu empleo o el curso al haberle dicho este inconveniente, mucha suerte en tu busqueda de empleo o en la busqueda de curso
(que espero que lo encuentres), con todas estas pistas que te digo ya veras como seguro al final encuentras el empleo o curso soñado.
