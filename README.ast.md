Fido: un script de PowerShell pa descargar ISOs de Windows y d'UEFI Shell
=========================================================================

[![Licence](https://img.shields.io/badge/license-GPLv3-blue.svg?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![Github stats](https://img.shields.io/github/downloads/pbatard/Fido/total.svg?style=flat-square)](https://github.com/pbatard/Fido/releases)

**Asturianu** | [Español](README.es.md) | [English](README.md)

Adautación a Linux fecha con AI por BENDER (baxo opencode)

Descripción
-----------

Fido ye un script de PowerShell concebíu principalmente pa usase en [Rufus](https://github.com/pbatard/rufus), anque tamién pue usase de forma independiente, y que tien como oxetivu automatizar l'accesu a los enllaces oficiales de descarga d'ISOs minoristes de Microsoft, amás d'ufrecer un accesu cómodu a [imáxenes arrancables d'UEFI Shell](https://github.com/pbatard/UEFI-Shell).

Esti script esiste porque, anque Microsoft ufierta los enllaces de descarga d'ISOs minoristes de forma llibre y pública (a lo menos dende Windows 8 hasta Windows 11), hasta versiones recientes, la mayoría d'esos enllaces namás taben disponibles dempués de facer pasar a los usuarios por munchos requisitos innecesarios que creaben una esperiencia de veceru bien contraproducente, si non abiertamente contraria, y que quitaba enforma valor a lo que la xente de verdá quier (accesu direutu a les descargues d'ISOs).

En cuanto al motivu pol que pue querese descargar ISOs __minoristes__ de Windows, en llugar de les ISOs xeneraes pola ferramienta propia de Microsoft (MCT), ye que anguaño usar ISOs minoristes oficiales ye la única manera d'asegurar con total certeza que'l conteníu del sistema operativu nun foi alteráu. Efectivamente, como cada una tien un solu maestru, les ISOs minoristes de Microsoft son les úniques de les que pues llograr un SHA-1 oficial (de MSDN, si tienes accesu, o de sitios [como esti](https://msdn.rg-adguard.net/public.php)), lo que te dexa tar 100% seguru de que la imaxe que uses nun ta estropeada y ye segura.

Esto, de la mesma, da garantía de que'l conteníu que __TU__ uses pa instalar el to sistema operativu, que ye críticu validar enantes si tienes la más mínima esmolición pola seguridá, coincide, bit a bit, col que publicó Microsoft.

Per otra parte, seya como seya la forma en que la ferramienta de creación de medios de Microsoft (MCT) xenera'l so conteníu, como nunca hai dos ISOs d'MCT iguales (porque MCT siempres regenera'l conteníu de la ISO sobre la marcha), anguaño ye imposible validar con certeza absoluta si una ISO xenerada por MCT ye segura d'usar. Especialmente, a diferencia de lo que pasa coles ISOs minoristes, ye imposible saber si una ISO d'MCT pudo estropiase dempués de xenerase.

Por eso fai falta ufiertar a los usuarios una forma muncho más fácil y menos restrictiva d'accesu a les ISOs minoristes oficiales...

Llicencia
---------

[GNU General Public License version 3.0](https://www.gnu.org/licenses/gpl-3.0) o posterior.

Cómo funciona
-------------

El script fai, fundamentalmente, la mesma operación que fadríes al visitar la siguiente URL (esto ye, nel casu de Windows 10, si amás camudasti la cadena `User-Agent` del navegador, yá que los servidores web de Microsoft detecten que uses una versión de Windows igual a la que quies descargar y puen redirixite __fora__ de la páxina que dexa llograr un enllaz direutu de descarga de la ISO):

https://www.microsoft.com/en-us/software-download

Dempués de comprobar l'accesu básicu al sitiu de descargues de software de Microsoft, el script consulta primero l'API web de los servidores de Microsoft pa pedir la seleición de llingües disponible pa la versión de Windows escoyida, y depués pide los enllaces de descarga reales, pa toles arquitectures disponibles pa esa llingua + versión.

Requisitos
----------

* **Windows**: Windows 8 o posterior con Windows PowerShell 5.1 o posterior. Windows 7 **nun** ta soportáu. Tán disponibles tantu la interfaz gráfica como'l mou de llinia de comandos.
* **Linux / macOS**: PowerShell 7 o posterior (`pwsh`) - mira [Instalar PowerShell en Linux](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux) o [en macOS](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-macos). Namás ta disponible'l mou de llinia de comandos, porque la interfaz gráfica depende de WPF, que ye esclusivu de Windows.

Documentación téunica (inglés/español): [docs/TECHNICAL_DOC_EN.md](docs/TECHNICAL_DOC_EN.md) - [docs/TECHNICAL_DOC_ES.md](docs/TECHNICAL_DOC_ES.md).

Mou de llinia de comandos
-------------------------

Fido soporta'l mou de llinia de comandos; cuando se da una de les opciones siguientes, nun se crea la GUI y pues xenerar la descarga de la ISO dende una consola o un script de PowerShell.

Hai que tener en cuenta, sicasí, que dende 2023.05 Microsoft retiró l'accesu a les versiones antigües d'ISOs de Windows y, por eso, la llista de versiones que se puen descargar con Fido tuvo que reducese a la más reciente de cada versión.

Les opciones son:
- `Win`: Especifica la versión de Windows (ex. _"Windows 10"_). Tamién debería funcionar una versión abreviada (ex. `-Win 10`) siempre que seya abondo única. Si nun s'especifica esta opción, escuéyese automáticamente la versión más reciente de Windows. Pues llograr una llista de versiones soportaes con `-Win List`.
- `Rel`: Especifica la versión de llanzamientu de Windows (ex. _"21H1"_). Si nun s'especifica, escuéyese automáticamente la más reciente pa la versión de Windows escoyida. Tamién pues usar `-Rel Latest` pa forzar la más reciente. Pues llograr una llista de versiones soportaes con `-Rel List`.
- `Ed`: Especifica la edición de Windows (ex. _"Pro/Home"_). Tamién deberíen funcionar ediciones abreviaes (ex. `-Ed Pro`) siempre que seyan abondo úniques. Si nun s'especifica, escuéyese automáticamente la versión más reciente de Windows. Pues llograr una llista de versiones soportaes con `-Ed List`.
- `Lang`: Especifica la llingua de Windows (ex. _"Arabic"_). Deberíen funcionar les abreviaciones o partes d'una llingua (ex. `-Lang Int` pa `English International`) siempre que seyan abondo úniques. Si nun s'especifica, el script intenta escoyer la mesma llingua que la configuración llocal del sistema. Pues llograr una llista de llingües soportaes con `-Lang List`.
- `Arch`: Especifica l'arquiteutura de Windows (ex. _"x64"_). Si nun s'especifica, el script intenta usar la mesma arquiteutura que la del sistema actual.
- `GetUrl`: Por defecto, el script intenta llanzar la descarga automáticamente. Pero col cambiu `-GetUrl`, el script namás amuesa l'URL de descarga, que depués pues unviar a otra orden o a un ficheru.

Exemplos de descarga per llinia de comandos:

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

Executando en Linux y macOS
---------------------------

El script funciona baxo PowerShell 7+ (`pwsh`), pero namás en **mou de llinia de comandos**, porque la interfaz gráfica depende de WPF (`PresentationFramework`), que Microsoft nun ufierta fuera de Windows. Por eso, al invocar el script ensin nenguna de les opciones de llinia de comandos en Linux/macOS, amuésase un mensaxe curtiu d'usu y sálse col códigu `403`.

Úsu habitual:

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

# List the available Windows versions
pwsh ./Fido.ps1 -Win List

# Only print the direct download URL (no download)
pwsh ./Fido.ps1 -Win 11 -Rel Latest -Ed Pro -Lang English -Arch x64 -GetUrl

# Download the ISO into the current directory
pwsh ./Fido.ps1 -Win 11 -Rel Latest -Ed Pro -Lang English -Arch x64
```

Notes sobre l'adautación a Linux/macOS:

* **Detección d'arquiteutura**: WMI/CIM (`Get-CimInstance Win32_Processor`) nun esiste fuera de Windows, asina que s'llee l'arquiteutura nativa de la CPU de `[System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture`. Pues forzala igualmente con `-PlatformArch x64|x86|ARM64` si quies saltate la detección.
* **Descargues**: `Start-BitsTransfer` (BITS) ye una teunoloxía esclusiva de Windows. Cuando nun ta disponible, el script recurre a `Invoke-WebRequest -OutFile`, que ye lo que pasa en Linux/macOS.
* **TLS**: el parche forzáu de TLS 1.0/1.1/1.2 pa Windows 8.x namás s'aplica nos anfitriones Windows; PowerShell 7 yá usa TLS 1.2 o superior por defecto en toos los demás sitios.
* **Firma Authenticode**: el script orixinal ta firmáu con Authenticode pa Windows. Esta adautación quitó'l bloque de la firma, yá que, si non, se denunciaría como inválida en cuanto se modificara'l script.
* **Bloqueos d'IP de Microsoft**: Microsoft pue refugar temporalmente l'usu d'enllaces d'ISO dende la to direición IP (errores como `Sentinel marked this request as rejected.` o'l códigu `715-123130`). Ye una restricción per IP del llau de Microsoft que tamién afecta a los navegadores y a otres ferramientes de descarga: espera un tiempu, cambia de rede o descarga la ISO manualmente dende https://www.microsoft.com/software-download

Firma de les versiones (sign.sh)
--------------------------------

`sign.sh` xenera la carga LZMA que Rufus llee (`Fido.ps1.lzma`) xunto cola so firma RSA (`Fido.ps1.lzma.sig`). Funciona en Linux y en MSYS2/Git Bash:

```bash
# The default key paths are Windows ones, so point the script at the keys when on Linux
PRIVATE_KEY=/path/to/private.pem PUBLIC_KEY=/path/to/public.pem ./sign.sh
```

Lo que fai, por orde:

1. **Firma Authenticode** de `Fido.ps1`, usando'l `signtool` del SDK de Windows y el certificáu EV d'Akeo. Esti pasu rique Windows y sálta con un avisu cuando `signtool` nun ta disponible (en Linux nunca s'usa un `signtool` al azar de `$PATH`).
2. Pide la contraseña de la clave privada y la valida enantes de tocar cualquier ficheru.
3. Comprime `Fido.ps1` con `lzma` ya insiere el tamañu ensin comprimir de 64 bits little endian nel desplazamientu 5, que ye lo que espera'l decodificador LZMA de Rufus; depués vuelve a lleer esi valor pa comprobalo.
4. Crea - o anueva, si la esistente falta o ta desactualizada - la firma RSA-SHA256 `Fido.ps1.lzma.sig` y la verifica cola clave pública.

Tanto `*.sig` como `*.lzma` son artefautos de compilación y git los ignora. Los caminos de les claves, la ubicación de `signtool` y la buelga del certificáu puen sustituyise poles variables d'ente `PRIVATE_KEY`, `PUBLIC_KEY`, `SIGNTOOL` y `SHA1_THUMBPRINT`.

Notes adicionales
-----------------

Pola so finalidá d'usu con Rufus, esti script nun ta fechu pa cubrir toles descarges d'ISOs minoristes posibles. En llugar d'eso, escoyimos sobre too les que ye probable que pida'l públicu xeneral. Por exemplu, anguaño nun tenemos nengún plan d'añadir soporte pa descargues d'ISOs de Windows LTSB/LTSC.

Si te interesen estes descargues, t'invitamos a visitar les páxines de descarga correspondientes de Microsoft, como [esta](https://www.microsoft.com/evalcenter/evaluate-windows-10-enterprise) pa les versiones LTSC.

ATENCIÓN, AVISU (12 d'ochobre de 2026): Microsoft va cortar a partir del 19 de xunu de 2027 l'accesu a Windows Update pa toos los equipos que tengan Windows 10 ensin ESU o inferior (el bloqueu anterior foi hasta Windows Vista/Server 2008 ensin R2); esto afecta lógicamente a les versiones de servidor (de Server 2008 R2 a Server 2019; a partir de Server 2022, el zarru de Windows Update nun los afecta). Ye por mor de la caducidá de los certificaos raíz del serviciu d'actualizaciones, que caduquen a partir d'esta data. Si quies echar una güeyada al enllaz oficial de la noticia de Microsoft, equí lo tienes (usa la traducción del navegador, ta n'inglés):

https://techcommunity.microsoft.com/blog/windows-itpro-blog/prepare-for-windows-update-certificate-rotation-in-2027/4562463

Recuerda que los certificaos raíz formen parte de la navegación per Internet; una de les carauterístiques del protocolu https ye que agora too lo que se tresfier al router ta cifráu (enantes nun yera asina). Sicasí, pa que programes como Wireshark, que s'usen pa analizar too lo que se tresfier nuna rede doméstica, nun tengan efeutu (nun se vea ningún datu sensible), los certificaos raíz tienen de funcionar y tar al día. Si nun funcionen, da un error de certificáu nel navegador y los programes que conecten a Internet dexarán de funcionar. Tienes que tener esto en cuenta cuando uses un Windows antiguu instaláu nel ordenador (per ciertu, el zarru de Windows Update tamién afecta a les máquines virtuales, esto ye, a los PCs arrancaos dentro d'un equipu físicu).

Cuando llegue la data de caducidá del certificáu raíz, ye posible que los Office instalaos en Windows ensin soporte den errores al comprobar actualizaciones (hasta 10 y Server 2019, que son veceru y servidor respeutivamente, puedes instalar el 2021-365, 7 y 8, hasta Office 2016); esto se resuelve desactivando les actualizaciones d'Office (cuando llegue la data de caducidá d'esos certificaos raíz).

Na ventana anterior (les actualizaciones automátiques impunxéronse a partir de Windows 2000) nun dio nengún tipu de fallu al arrancar el sistema operativu, namás al abrir la páxina de Microsoft Update o al iniciar Windows Update. (Yo pasé pela ventana anterior de zarru del update).

Nel casu de que seya Windows 10 con ESU, Windows 11 24H2, servidores LTSC de 2019 y 2016 y Server 2022, Microsoft punxo como métodu oficial pa resolver el problema la actualización: vas tener que actualizar el segundu martes de cada mes hasta la data del 19 de xunu de 2027, en qu'a yá... piano, piano (vas entender lo que te digo).

Nel casu de que te topes con esti tipu d'equipos, estes son les opciones que tienes:

-  mercar l'ESU (Windows 10) (nel casu de países de la Xunión Europea, nun tien ningún costu)
-  parchear el update pa acceder al ESU, l'únicu parche (y recomendable pa Windows 10) ye'l MAS (Microsoft Activation Script)
-  instalar un parche non oficial pa actualizar los certificaos raíz, que ye Legacy Update
-  nel casu de versiones compatibles (por agora nun ye obligatoriu dende 11 24H2; pa Windows 10 ensin ESU ye imprescindible a medies) aceptar les actualizaciones a versiones mayores de Windows per mediu d'actualización o faciendo una actualización dende los medios d'instalación de Windows.
-  caltener la instalación de Windows y facer un dual boot con Linux (nun ye aconseyable).
-  desinstalar Windows ya instalar Linux xunto con una máquina virtual de Windows (ellí se permite too, dende orixinales hasta modificaos)

Nel casu de que escojas la opción sensata (la postrera), recuerda que tienes de montar VMware o VirtualBox en Linux (instala Linux nel ordenador, lóxicamente) y la máquina virtual col Windows que escojas (ellí sí que puedes instalar Windows antiguos) de manera oficial hasta xunu de 2027; dempués nun va funcionar y namás vas poder instalar y actualizar esti tipu de PCs per métodos non oficiales.

Nel casu de que hayas perdíu l'empleu o'l cursu por haber dichu esta molestia, muncha suerte na busca d'empleu o na busca de cursu (esperu que lo atopes); con toles pistes que te digo yá verás cómo, seguro, al final atopes l'empleu o'l cursu soñáu.
