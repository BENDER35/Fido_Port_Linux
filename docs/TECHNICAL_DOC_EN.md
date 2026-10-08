# Fido - Technical Documentation (English)

This document describes how `Fido.ps1` works internally and which changes were applied in order to port it
to PowerShell 7 (`pwsh`) on Linux and macOS.

* Spanish version: [TECHNICAL_DOC_ES.md](TECHNICAL_DOC_ES.md)
* README: [../README.md](../README.md) (English) - [../README.es.md](../README.es.md) (Español)
* Script: [`../Fido.ps1`](../Fido.ps1) - build/signing script: [`../sign.sh`](../sign.sh)
* License: GPLv3 or later
* Port credit: Linux port by AI by BENDER (under opencode)

---

## 1. Overview

Fido is a single-file PowerShell script that retrieves the official Microsoft Windows retail ISO download
links (and bootable UEFI Shell images) by driving Microsoft's public download web API, so that the user does
not have to go through the download wizard in a browser.

It offers two mutually exclusive interfaces:

| Mode | Trigger | UI | Platforms |
|------|---------|----|-----------|
| **GUI** | none of the CLI options are supplied | WPF window (XAML) | Windows only |
| **CLI** | `-Win`, `-Rel`, `-Ed`, `-Lang`, `-Arch` or `-GetUrl` is supplied | console | Windows, Linux, macOS |

## 2. File conventions

* The file must be saved as **UTF-8 with BOM** and **CRLF** line endings (see `.editorconfig` and
  `.gitattributes`). The BOM is what makes Windows PowerShell pick Unicode for the UI strings instead of
  ISO-8859-1.
* Indentation is done with tabs.
* The upstream script carries an Authenticode signature block (`# SIG # Begin signature block`). As soon as
  the script is modified that signature becomes invalid, so this port **removed the signature block**.

## 3. Parameters

Defined in the `param()` block at the top of the script:

| Parameter | Type | Purpose |
|-----------|------|---------|
| `AppTitle` | string | Title shown on the GUI window (default `Fido - ISO Downloader`) |
| `LocData` | string | `\|`-separated UI localization strings; element 0 is the locale (e.g. `es-ES`) |
| `Locale` | string | Forced locale, default `en-US`; also used to query the Microsoft API |
| `Icon` | string | Path to a `.ico`/DLL used as the window icon (GUI) |
| `PipeName` | string | Name of a named pipe; when set, the download URL is sent to it instead of opening a browser (used by Rufus) |
| `Win` | string | Windows version, e.g. `Windows 11` (`-Win List` lists them) - **enables CLI mode** |
| `Rel` | string | Windows release, e.g. `26H2` or `Latest` - **enables CLI mode** |
| `Ed` | string | Windows edition, e.g. `Pro` - **enables CLI mode** |
| `Lang` | string | Language, e.g. `English` - **enables CLI mode** |
| `Arch` | string | Architecture, e.g. `x64` - **enables CLI mode** |
| `GetUrl` | switch | Only print the download URL, do not download - **enables CLI mode** |
| `PlatformArch` | string | Force the native CPU architecture (skips autodetection) |
| `Verbose` | switch | Sets verbosity to 2 (log every queried URL) |
| `Debug` | switch | Sets verbosity to 5 (also dumps the raw JSON API answers) |

Verbosity levels: `0` (silent, used with `-GetUrl`), `1` (default), `2` (`-Verbose`), `5` (`-Debug`).

## 4. Program flow

### 4.1 Startup

1. `[Console]::OutputEncoding` is forced to UTF-8 (best effort).
2. `$Cmd` becomes `$true` as soon as any CLI option is present.
3. `Get-Platform-Version()` returns a decimal Windows version (`10.0`, `6.1`, ...) on Windows hosts and
   **`0.0` on Linux/macOS**. This single value is what the whole script uses to decide whether it is running
   on Windows:
   * `$winver -lt 10.0` + `$winver -ne 0.0` → Windows 8.x, force TLS 1.0/1.1/1.2 (never applied on Linux).
   * `$winver -ne 0.0 -and $winver -le 6.1` → Windows 7 is rejected (`exit 403`).
   * `$winver -eq 0.0` → non-Windows host.
4. `Get-Arch()` detects the native CPU architecture:
   * Windows: `Get-CimInstance Win32_Processor | Architecture` (0 = x86, 9 = x64, 12 = ARM64).
   * Linux/macOS (or when `Get-CimInstance` is unavailable, as happens with some PowerShell 7 builds):
     `[System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture` → `x86` / `x64` / `arm` / `arm64`.

### 4.2 Mode selection

* **Non-Windows + no CLI option** → the script prints a usage message and exits with `403`, because WPF
  (`PresentationFramework`) does not exist outside of Windows.
* **Windows + no CLI option** → the WPF assembly and the `WinAPI.Utils` C# helper (which P/Invokes
  `shell32.dll!ExtractIconEx` and `user32.dll!ShowWindow`) are loaded and the wizard window is shown.
* **Any platform + CLI option** → the command line path (section 4.4) runs and the script exits before the
  XAML code is ever evaluated.

### 4.3 GUI mode (Windows only)

The window is declared as inline XAML (`[xml]$XAML`, one `Grid` with a `Continue`/`Back` button pair, a title
`TextBlock`, a `ComboBox` and a hidden `CheckBox`). The wizard is a small state machine driven by `$Stage`
(`0`..`5`):

| `$Stage` | Action on *Continue* |
|----------|----------------------|
| 0 | Pick the Windows version (`$WindowsVersions`) |
| 1 | `Check-Locale()` + `Get-Windows-Releases()` |
| 2 | `Get-Windows-Editions()` |
| 3 | `Get-Windows-Languages()` (network) |
| 4 | `Get-Windows-Download-Links()` (network) |
| 5 | `Process-Download-Link()` and close the window |

`Add-Entry()` inserts a new label/`ComboBox` pair into the grid and shifts the buttons down by `$dh` (58 px)
per row; `Back` removes the last pair again (`RemoveAt`) and decrements `$Stage`.

### 4.4 Command line mode

A strict cascade, where every step validates the previous one and exits with `1` when the value is not
found (or when `List` was requested, which is a deliberate "print and exit" behaviour):

```
-Win  → $WindowsVersions          → releases (Get-Windows-Releases)
      → editions (Get-Windows-Editions)
      → languages (Get-Windows-Languages)      [network]
      → download links (Get-Windows-Download-Links)  [network]
      → -GetUrl: print URL | otherwise: download
```

* Missing values are defaulted to the first/automatically selected entry (the system locale is used to pick
  a language via `Select-Language()`, and the native CPU arch is used to pick a download link).
* Failure to fetch languages or links exits with `3`.
* `Error()` exits with `2` in CLI mode (it only manipulates the window title/message box in GUI mode).

### 4.5 Data model

`$WindowsVersions` is a nested array. Element `[0]` of every entry is `@(display name, page id)`, all
following elements are releases, and each release is `@(release name, @(edition name, productEditionId)...)`:

```powershell
@(
  @("Windows 11", "windows11"),
  @(
    "26H2 (Build 26300.9457 - 2026.09)",
    @("Windows 11 Home/Pro/Edu", @(3813, 3816)),   # 2 IDs because ARM64 SKUs differ
    @("Windows 11 Home China ", @(3814, 3817))
  )
),
@("UEFI Shell 2.2", "UEFI_SHELL 2.2"), ...
```

Two special page IDs exist: `UEFI_SHELL 2.2` / `UEFI_SHELL 2.0`, which do not talk to Microsoft at all.

## 5. The Microsoft download handshake

For every *productEditionId* of the selected edition, `Get-Windows-Languages()` creates a fresh
`$SessionId` GUID (Microsoft only honours one active session per architecture, hence the 2-element
`$SessionId` array) and performs, in order:

1. **Session whitelisting**
   `https://vlscppe.microsoft.com/tags?org_id=y6jn8c31&session_id=<guid>`
2. **Fraud-detection challenge**
   `https://ov-df.microsoft.com/mdt.js?instanceId=560dc9f3-1aa5-4a2f-b63c-9e18f8d0e175&PageId=si&session_id=<guid>`
   → the JavaScript response is scraped with two regexes to obtain `w` and `rticks`.
3. **Fraud-detection reply**
   `https://ov-df.microsoft.com/?session_id=<guid>&CustomerId=<instanceId>&PageId=si&w=<w>&mdt=<epoch millis>&rticks=<rticks>`
4. **Language/SKU listing**
   `https://www.microsoft.com/software-download-connector/api/getskuinformationbyproductedition`
   `?profile=606624d44113&productEditionId=<id>&SKU=undefined&friendlyFileName=undefined&Locale=<locale>&sessionID=<guid>`
   → returns `Skus[]` with `Id`, `Language` and `LocalizedLanguage`. Requests are retried twice (2 s apart)
   because the endpoint is flaky.

Then, in `Get-Windows-Download-Links()`, for each SKU of the selected language:

5. **Download links**
   `https://www.microsoft.com/software-download-connector/api/GetProductDownloadLinksBySku`
   `?profile=606624d44113&productEditionId=undefined&SKU=<skuId>&friendlyFileName=undefined&Locale=<locale>&sessionID=<guid>`
   * must be sent with the `Referer: https://www.microsoft.com/software-download/windows11` header;
   * returns `ProductDownloadOptions[]`, where `DownloadType` maps to an architecture through
     `Get-Arch-From-Type()` (`0 → x86`, `1 → x64`, `2 → ARM64`) and `Uri` is the direct ISO URL.

Supporting calls:

* `Check-Locale()` (GUI) probes `https://www.microsoft.com/<locale>/software-download/windows11` and falls
  back to `en-US` when the locale is not served.
* `Get-Code-715-123130-Message()` re-reads the same page and extracts the localized ban message from the
  hidden `<input id="msg-01">` element.

Error handling of step 5:

| Server answer | Script reaction |
|---------------|-----------------|
| `Type: 9` (code `715-123130`) | localized "your IP has been banned" message + session ID |
| `Key: ErrorSettings.SentinelReject` | **added by this port**: explicit "Microsoft rejected this IP address" message with remediation advice |
| anything else | the raw `Errors[0].Value` is reported |

### 5.1 UEFI Shell images

When the selected page id starts with `UEFI_SHELL`, the script skips Microsoft entirely and queries
`https://github.com/pbatard/UEFI-Shell/releases/download/<tag>/Version.xml` for the supported architectures,
building an URL of the form
`UEFI-Shell-<version>-<tag>-RELEASE.iso` (or `-DEBUG.iso`).

## 6. Localization

* `$EnglishMessages` is a `|`-separated list of the UI strings; `Get-Translation()` looks up the index of
  the English string and returns the matching `$Localized` entry (supplied through `-LocData`), padding or
  truncating the array so that a partial localization can never break the UI.
* `Select-Language()` maps the system `CurrentUICulture` onto the Microsoft language name so that the
  correct language is pre-selected in the wizard / CLI default.

## 7. Downloading (`Process-Download-Link`)

Order of preference:

1. **`-PipeName` given** → the URL is written to a named pipe (`Send-Message`) so that a parent application
   (Rufus) can download it. A `CheckBox` added at stage 4 lets the user override this and open a browser
   instead.
2. **CLI mode** → probe the size with a `HEAD` request (`Content-Length`, purely informational and now
   non-fatal), then:
   * `Start-BitsTransfer` when the BITS cmdlet exists (**Windows**);
   * `Invoke-WebRequest -OutFile` otherwise (**Linux/macOS** and PowerShell 7 without BITS).
3. **GUI mode** → `Start-Process <url>` opens the default browser.

## 8. Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success (download finished, or `-GetUrl` printed the URL) |
| `1` | Invalid/unknown parameter value, or `List` was requested |
| `2` | `Error()` was raised in CLI mode |
| `3` | Could not retrieve languages or download links from Microsoft |
| `100` | Initial value: window closed without downloading (GUI) |
| `403` | Unsupported platform (Windows 7), or GUI mode requested on Linux/macOS |
| `404` | The download itself failed |

Note: `pwsh -File` reports exit codes modulo 256, so `403` appears as `147` in `$?`/`$LASTEXITCODE`.

## 9. The Linux/macOS port

The script was ported *in place* (no separate copy) so that a single file keeps working on every platform.

### 9.1 Changes

| # | Location | Windows behaviour | Linux/macOS behaviour |
|---|----------|-------------------|-----------------------|
| 1 | Header comment | — | Documents that the script also runs under `pwsh` |
| 2 | TLS block | Forces TLS 1.0/1.1/1.2 on Windows < 10 | Skipped (`$winver -ne 0.0`) and wrapped in `try/catch`; PowerShell 7 already uses TLS 1.2+ |
| 3 | GUI bootstrap | Loads `PresentationFramework` + `WinAPI.Utils` | Prints a usage message and exits `403` before anything Windows-specific is loaded |
| 4 | `Get-Arch()` | `Get-CimInstance Win32_Processor` | Falls back to `RuntimeInformation.OSArchitecture`; also protects Windows hosts where the CIM cmdlets are missing |
| 5 | Platform checks (`$winver -le 6.1`) | Rejects Windows 7 | Only evaluated on Windows, so `0.0` (non-Windows) no longer triggers the rejection |
| 6 | `Process-Download-Link()` | `Start-BitsTransfer` | Detects the cmdlet at runtime and falls back to `Invoke-WebRequest -OutFile`; the `HEAD` size probe is now non-fatal |
| 7 | `SentinelReject` handling | raw error string | friendly, actionable message (IP block + what to do) |
| 8 | Signature block | Authenticode signed | removed (invalid after any modification) |

Everything else (parameters, data model, API handshake, localization, wizard logic) is unchanged.

### 9.2 Known limitations on Linux/macOS

* No graphical UI: use the command line options (`-Win`, `-Rel`, `-Ed`, `-Lang`, `-Arch`, `-GetUrl`).
* Downloads run in the PowerShell process, so there is no BITS resumability; a dropped connection means
  restarting the download.
* `-Icon` and `-PipeName` are Windows-centric features (GUI / Rufus integration) and are not usable there.
* Microsoft may reject ISO link requests from a given IP address (`Sentinel marked this request as
  rejected.` / `715-123130`). This is server-side and IP-based - it affects browsers and other tools too,
  and the script can only report it and suggest waiting, changing network, or downloading manually from
  <https://www.microsoft.com/software-download>.

### 9.3 Verification performed

All of the following was run with PowerShell 7.6.4 on Linux x86_64:

```text
pwsh -NoProfile -File ./Fido.ps1                     → usage message, exit 403 (GUI guard)
pwsh -NoProfile -File ./Fido.ps1 -Win List           → 4 versions listed
pwsh -NoProfile -File ./Fido.ps1 -Win 11 -Rel List   → 26H2 release listed
pwsh -NoProfile -File ./Fido.ps1 -Win 11 -Rel Latest -Ed List        → editions listed
pwsh -NoProfile -File ./Fido.ps1 -Win 11 -Rel Latest -Ed Pro -Lang List  → 40+ languages (full API handshake OK)
pwsh -NoProfile -File ./Fido.ps1 ... -GetUrl         → blocked by Microsoft IP filter (expected here), friendly message
pwsh -NoProfile -File ./Fido.ps1 -Win "UEFI Shell 2.2" -Rel Latest -Ed Release -Lang en -Arch x64
                                                      → 21 MB ISO downloaded and verified (exit 0)
[System.Management.Automation.Language.Parser]::ParseFile(...) → no syntax errors
```

---

## 10. Release signing (`sign.sh`)

Rufus does not fetch `Fido.ps1` directly, but a compressed copy of it: `Fido.ps1.lzma`, shipped together with an
RSA signature `Fido.ps1.lzma.sig` that lets it detect a tampered script. `sign.sh` is the build script that
produces both artefacts.

### 10.1 What it does, in order

1. **Authenticode** signature of `Fido.ps1` with the Windows SDK `signtool` (default path
   `C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool`), the certificate identified by the
   SHA-1 thumbprint `fc4686753937a93fdcd48c2bb4375e239af92dcb`, and a DigiCert RFC 3161 timestamp. Windows only.
2. Reads the pass phrase of the private key (`read -s`) and validates it with
   `openssl pkey -in <key> -passin pass:<phrase> -noout` *before* any file is modified.
3. Compresses the script with `lzma -kf Fido.ps1` and inserts the **uncompressed size as a 64-bit little endian
   value at offset 5** of `Fido.ps1.lzma` - the standard `.lzma` header is 5 parameter bytes followed by an
   8-byte size field, which `lzma` does not know how to fill - using the `printf | xxd | tac | xxd | dd seek=5`
   pipeline, and then reads the field back with `od -An -tu8 -j5 -N8` to make sure the value Rufus will read is
   the right one.
4. `openssl dgst -sha256 -sign` produces `Fido.ps1.lzma.sig`, which is then checked with
   `openssl dgst -sha256 -verify` and the public key. An existing signature that still verifies is left
   untouched (idempotent); a missing or stale one is refreshed.

Environment variables: `PRIVATE_KEY`, `PUBLIC_KEY` (key paths, Windows defaults), `SIGNTOOL` (signtool location)
and `SHA1_THUMBPRINT` (certificate). `*.sig` and `*.lzma` are build artefacts ignored by git.

### 10.2 Linux port of `sign.sh`

| Problem in the original script | Fix |
|--------------------------------|-----|
| Keys hardcoded to MSYS paths (`/d/Secured/Akeo/Rufus/*.pem`) with no way to override | `PRIVATE_KEY` / `PUBLIC_KEY` environment variables, plus an existence check that reports an explicit error |
| `signtool` invoked unconditionally → `command not found` on Linux | the step only runs when the configured path exists or, on MSYS/Cygwin, when `signtool` is on `$PATH`; otherwise it is skipped with a notice. The unrelated `signtool` found in `/usr/bin` on Linux is never picked up |
| `realpath` of a non-existent key printed an error before failing anyway | keys are validated first and only then resolved with `realpath` |
| No error handling at all (no `set -e`), an unused `$SIZE` variable and unquoted expansions | `set -euo pipefail`, quoted variables, dead code removed |
| GNU-only `stat -c%s` / `stat -c "%s"` | `file_size()` helper with GNU and BSD (`stat -f %z`) fallbacks |
| Overwriting the password with random data through a pipe could abort the script under `pipefail` (SIGPIPE) | the password is cleared with `unset PASSWORD` |
| Neither the size patch nor the signature were ever verified | read-back check of the size field (script aborts on mismatch) and `openssl dgst -verify` after every signing |
| The pass phrase was requested *after* a `signtool` call that could already have failed | new order: key checks → Authenticode (if available) → pass phrase → compress → patch size → sign → verify |

### 10.3 Verification performed

```text
bash -n sign.sh                                           → sintaxis OK
./sign.sh (default keys missing)                          → "private key ... not found", exit 1
./sign.sh PRIVATE_KEY=... PUBLIC_KEY=... (pass phrase OK) → signtool skipped, signature created and verified, exit 0
./sign.sh (second run)                                    → "already up to date", exit 0
./sign.sh (wrong pass phrase)                             → "Invalid pass phrase", exit 1
./sign.sh (signature corrupted - 8 bytes zeroed)          → "Updating signature" + "Verified OK"
lzma -dc Fido.ps1.lzma | cmp - Fido.ps1                   → identical (41431 bytes)
size field at offset 5 == stat -c%s Fido.ps1              → 41431 == 41431
```

The Authenticode step could only be verified as *skipped* here, since it needs Windows, the Windows SDK and the
Akeo EV certificate.
