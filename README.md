# Biblioteca Pro — Base QA Automatizada

Suite de pruebas end-to-end para la aplicacion web Biblioteca Pro, construida
con dos stacks complementarios y una GUI Windows para ejecutarlos.

- **Robot Framework 6** — keyword-driven, 43 casos, 5 archivos `.robot`.
- **Java 11 + Selenium 4 + TestNG** — Page Object Model, 36 casos, 5 clases.
- **GUI Tkinter** — ejecuta ambas suites desde Windows y muestra capturas en vivo.

Sitio bajo prueba: `https://biblioteca-front-end-1satou1s-projects.vercel.app`

Equipo:

| Integrante | GitHub |
|---|---|
| Jeffrey Guerrero | [jguerreromira](https://github.com/jguerreromira) |
| Jhoan Londono | [jhoan636](https://github.com/jhoan636) |
| Estiven Uribe | [EstivenUribe](https://github.com/EstivenUribe) |

Asignatura: **Pruebas y Gestion de la Configuracion**
Docente: David Mejia Tabares

> La suite ejecuta pruebas contra un ambiente remoto compartido. Los casos
> destructivos usan datos con prefijo `QA_AUTO_` y timestamp para no contaminar
> datos reales.

---

## Tabla de contenidos

1. [Estado actual](#estado-actual)
2. [Estructura del proyecto](#estructura-del-proyecto)
3. [Requisitos](#requisitos)
4. [Datos de prueba](#datos-de-prueba)
5. [Ejecucion Robot Framework](#ejecucion-robot-framework)
6. [Ejecucion Java Selenium](#ejecucion-java-selenium)
7. [GUI de ejecucion](#gui-de-ejecucion)
8. [Limpieza de artefactos](#limpieza-de-artefactos)
9. [Matriz de cobertura](#matriz-de-cobertura)
10. [Evidencias y reportes](#evidencias-y-reportes)
11. [Buenas practicas](#buenas-practicas)
12. [Mejoras pendientes](#mejoras-pendientes)

---

## Estado actual

- Robot Framework: **43 tests** en 5 archivos `.robot`, 7 etiquetados `smoke`.
- Java / TestNG: **36 tests** en 5 clases, modo headless funcional.
- Excel de datos: **7 hojas** generadas con timestamp por `generar_datos.py`.
- `testFailureIgnore=false` en `pom.xml`: Maven reporta BUILD FAILURE si hay tests fallidos.
- Scripts `run_tests.bat` / `run_tests.sh` presentes para Robot y Java.

Validaciones realizadas localmente:

```powershell
# Dry-run Robot: verifica sintaxis de los 43 tests sin abrir navegador
robot\venv\Scripts\robot.exe --dryrun --pythonpath robot\resources --outputdir robot\results\dryrun robot\tests
# Resultado: 43 tests parsean OK
```

```powershell
# Compilacion Java sin ejecutar
C:\maven\apache-maven-3.9.6\bin\mvn.cmd test-compile -Dfile.encoding=UTF-8
# Resultado: BUILD SUCCESS
```

Limitaciones actuales:

- `mvn` puede no estar en el PATH; los scripts buscan fallback en
  `C:\maven\apache-maven-3.9.6\bin\mvn.cmd`.
- Algunos tests dependen del estado del ambiente remoto (datos existentes, Redis activo).
- `TC-TGN-001` esta etiquetado `smoke` pero crea tipos/generos en el ambiente.

---

## Estructura del proyecto

```text
test-roboframework/
├── README.md
├── .gitignore
├── clean.bat                   ← borra artefactos generados (Windows)
├── clean.sh                    ← borra artefactos generados (Linux/macOS)
│
├── gui/
│   ├── launcher.bat            ← abre la GUI (Windows)
│   ├── launcher.py             ← interfaz tkinter
│   └── logo.png
│
├── robot/
│   ├── requirements.txt
│   ├── run_tests.bat           ← ejecuta suite Robot (Windows)
│   ├── run_tests.sh            ← ejecuta suite Robot (Linux/macOS)
│   ├── data/
│   │   ├── generar_datos.py    ← genera datos_prueba.xlsx con timestamp
│   │   └── datos_prueba.xlsx   ← generado, no versionado
│   ├── resources/
│   │   ├── variables.robot         ← URL, credenciales, localizadores
│   │   ├── keywords_comunes.robot  ← keywords reutilizables
│   │   └── ExcelReader.py          ← lector de hojas Excel
│   ├── tests/
│   │   ├── 01_autenticacion.robot  ← HU-001 HU-002 HU-003 (10 casos)
│   │   ├── 02_catalogo.robot       ← HU-006 HU-007 HU-008 HU-009 (12 casos)
│   │   ├── 03_tipos_generos.robot  ← HU-010 (5 casos)
│   │   ├── 04_dashboard.robot      ← HU-011 (6 casos)
│   │   └── 05_usuarios.robot       ← HU-004 HU-005 HU-013-016 (10 casos)
│   └── results/                ← generado, no versionado
│       ├── logs/               ← report.html, log.html, output.xml
│       ├── screenshots/
│       └── videos/
│
└── java/
    ├── pom.xml
    ├── testng.xml              ← suite completa, headless=false
    ├── testng-headless.xml     ← suite completa, headless=true
    ├── run_tests.bat           ← ejecuta suite Java (Windows)
    ├── run_tests.sh            ← ejecuta suite Java (Linux/macOS)
    └── src/
        ├── main/java/com/biblioteca/
        │   ├── config/Config.java          ← URL, credenciales, rutas
        │   └── pages/                      ← Page Objects: Login, Register,
        │                                      Panel, Catalog, Dashboard, Users
        └── test/java/com/biblioteca/
            ├── base/
            │   ├── BaseTest.java           ← setup/teardown, headless, capturas
            │   └── ExtentReportListener.java
            ├── tests/
            │   ├── AuthTests.java          ← 8 casos: HU-001 HU-002 HU-003
            │   ├── CatalogTests.java       ← 9 casos: HU-006 HU-007 HU-008 HU-009
            │   ├── DashboardTests.java     ← 5 casos: HU-011
            │   ├── TypesGenresTests.java   ← 5 casos: HU-010
            │   └── UsersTests.java         ← 9 casos: HU-004 HU-005 HU-013-016
            └── utils/
                ├── ExcelReader.java
                ├── ScreenshotUtils.java
                └── VideoRecorder.java
```

Directorios y archivos no versionados (cubiertos por `.gitignore`):

- `robot/venv/`, `robot/results/`, `java/target/`
- `robot/data/datos_prueba.xlsx`, `java/src/test/resources/datos_prueba.xlsx`
- `**/__pycache__/`, `*.pyc`, `*.class`

---

## Requisitos

| Herramienta | Version | Uso |
|---|---|---|
| Google Chrome | 120+ | Navegador bajo prueba |
| Python | 3.9+ | Robot Framework, Excel, GUI |
| Java JDK | 11+ | Suite Selenium / TestNG |
| Apache Maven | 3.8+ | Compilar y ejecutar Java |

Maven no necesita estar en el PATH si existe en
`C:\maven\apache-maven-3.9.6\bin\mvn.cmd`; los scripts lo detectan.

### Dependencias Python

```powershell
cd robot
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

Paquetes instalados: `robotframework`, `robotframework-seleniumlibrary`,
`robotframework-screencaplibrary`, `openpyxl`, `Pillow`, `webdriver-manager`,
`opencv-python`.

### Dependencias Java

Maven descarga todo desde `java/pom.xml` en la primera ejecucion.

| Libreria | Version |
|---|---|
| Selenium | 4.18.1 |
| TestNG | 7.9.0 |
| WebDriverManager | 5.7.0 |
| Apache POI | 5.2.5 |
| ExtentReports | 5.1.1 |

---

## Datos de prueba

El archivo `datos_prueba.xlsx` se genera con:

```powershell
robot\venv\Scripts\python.exe robot\data\generar_datos.py
```

Luego copiar a Java:

```powershell
Copy-Item robot\data\datos_prueba.xlsx java\src\test\resources\datos_prueba.xlsx -Force
```

Los scripts `run_tests.bat` hacen esto automaticamente si el archivo no existe.

### Hojas del Excel

| Hoja | Filas | Contenido |
|---|---:|---|
| `Login` | 5 | Admin exito, lector exito, credenciales erroneas, campos vacios |
| `Registro` | 6 | Exito con email unico, duplicado, cedula invalida, campos vacios |
| `Catalogo` | 7 | Crear/editar con titulos `QA_AUTO_CAT_<ts>_...` |
| `TiposGeneros` | 8 | Agregar/editar con nombres `QA_Tipo_<ts>` |
| `Dashboard` | 5 | Filtros tipo, genero, autor, year |
| `Usuarios` | 4 | Edicion de rol admin/lector |
| `Precondiciones` | 9 | Requisitos previos documentados por suite |

Cada fila incluye columnas `tipo_prueba` (smoke / regresion / destructivo /
validacion) y `precondicion` para trazabilidad.

### Credencial admin

| Rol | Email | Password |
|---|---|---|
| admin | `migueltroll789@gmail.com` | `123456` |

Configurada en `robot/resources/variables.robot` y
`java/src/main/java/com/biblioteca/config/Config.java`.

---

## Ejecucion Robot Framework

### Con el script (recomendado)

El script crea el `venv`, instala dependencias y genera el Excel si no existen.

```powershell
# Suite completa, modo visual
robot\run_tests.bat

# Headless (sin ventana)
set HEADLESS=true && robot\run_tests.bat

# Solo smoke
set TAGS=smoke && robot\run_tests.bat

# Headless + solo smoke
set HEADLESS=true && set TAGS=smoke && robot\run_tests.bat

# Una sola suite
set SUITE=tests\02_catalogo.robot && robot\run_tests.bat
```

Variables de entorno:

| Variable | Default | Descripcion |
|---|---|---|
| `HEADLESS` | `false` | `true` activa Chrome headless |
| `RECORD_VIDEO` | `false` | `true` graba GIF por test |
| `SUITE` | `tests` | ruta relativa a archivo `.robot` o directorio |
| `TAGS` | _(todos)_ | filtro por tag; ver tabla mas abajo |

### Con robot.exe directamente

```powershell
robot\venv\Scripts\robot.exe `
  --pythonpath robot\resources `
  --outputdir  robot\results\logs `
  --variable   HEADLESS:false `
  --variable   RECORD_VIDEO:false `
  robot\tests
```

### Dry-run (sintaxis sin navegador)

```powershell
robot\venv\Scripts\robot.exe `
  --dryrun `
  --pythonpath robot\resources `
  --outputdir  robot\results\dryrun `
  robot\tests
```

### Tags disponibles en Robot

| Tag | Descripcion |
|---|---|
| `smoke` | 7 casos de verificacion rapida (ver nota en matriz) |
| `data-driven` | Casos que leen multiples filas del Excel |
| `validacion` | Campos, mensajes de error, estados de UI |
| `ux` | Feedback visual: skeletons, botones disabled, estados de carga |
| `flujo-alternativo` | Caminos no exitosos |
| `login` `logout` `registro` | Autenticacion |
| `catalogo` `busqueda` `creacion` `edicion` `eliminacion` | Catalogo |
| `tipos-generos` | Tipos y generos |
| `dashboard` `sincronizacion` | Dashboard |
| `usuarios` `roles` `redis` | Usuarios |
| `HU-001` ... `HU-016` | Filtrar por historia de usuario |

Reportes en `robot/results/logs/`.

---

## Ejecucion Java Selenium

### Con el script (recomendado)

```powershell
# Suite completa
java\run_tests.bat

# Headless
set HEADLESS=true && java\run_tests.bat

# Una clase
set TEST=AuthTests && java\run_tests.bat

# Una clase en headless
set HEADLESS=true && set TEST=DashboardTests && java\run_tests.bat
```

Variables de entorno:

| Variable | Default | Descripcion |
|---|---|---|
| `HEADLESS` | `false` | `true` aplica `--headless=new` en ChromeOptions |
| `TEST` | _(suite completa)_ | nombre de clase Java, ej. `AuthTests` |

### Con Maven directamente

```powershell
cd java

# Suite completa
mvn test

# Headless (-Dheadless=true tiene prioridad sobre testng.xml)
mvn test -Dheadless=true

# Una clase
mvn test -Dtest=AuthTests

# Un metodo especifico
mvn test "-Dtest=AuthTests#tc_lgn_001_loginExitosoAdmin"

# Compilar sin ejecutar
mvn test-compile -Dfile.encoding=UTF-8
```

Si `mvn` no esta en el PATH:

```powershell
C:\maven\apache-maven-3.9.6\bin\mvn.cmd test -Dheadless=true
```

### Headless en Java

`BaseTest.java` resuelve el modo con un campo `static volatile boolean headlessMode`.

Prioridad: `-Dheadless=true` (argumento Maven) > parametro en `testng.xml` > default `false`.

Con `headless=true` aplica: `--headless=new`, `--window-size=1366,900`,
`--disable-gpu`, `--no-sandbox`, `--disable-dev-shm-usage`.

Reportes en `java/target/extent-reports/` y `java/target/surefire-reports/`.

---

## GUI de ejecucion

Solo Windows. Requiere Python con Pillow instalado (el script lo instala).

```powershell
gui\launcher.bat
```

La GUI ofrece:

- Panel izquierdo: botones Ejecutar Robot / Ejecutar Java, consola en tiempo real.
- Panel derecho: visor de capturas actualizadas durante la ejecucion.
- Busca Maven en PATH o en `C:\maven\apache-maven-3.9.6\bin\mvn.cmd`.
- Ejecuta en modo visual (no pasa HEADLESS ni TAGS).

---

## Limpieza de artefactos

```powershell
# Windows
clean.bat

# Linux / macOS
bash clean.sh
```

Borra: `robot/results/` (logs, screenshots, videos, dryrun), `java/target/`,
`__pycache__/`, `*.pyc`.

Conserva: `robot/venv/`, Excel generado, todo el codigo fuente.

### Regenerar el Excel

```powershell
robot\venv\Scripts\python.exe robot\data\generar_datos.py
Copy-Item robot\data\datos_prueba.xlsx java\src\test\resources\datos_prueba.xlsx -Force
```

### Recrear el entorno Python desde cero

```powershell
cd robot
Remove-Item venv -Recurse -Force
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

---

## Matriz de cobertura

Abreviaturas: **S**=smoke · **R**=regresion · **V**=validacion · **D**=destructivo
(el test crea, edita o elimina datos en el ambiente remoto).

### HU-001 · HU-002 · HU-003 — Autenticacion y Registro

| TC | Descripcion | Robot | Java | Tipo | D |
|---|---|:---:|:---:|:---:|:---:|
| TC-LGN-001 | Login exitoso admin → Panel Principal | ✓ | ✓ | S | |
| TC-LGN-002 | Badge de rol visible tras login | ✓ | ✓ | R | |
| TC-LGN-003 | Boton deshabilitado con campos vacios | ✓ | ✓ | V | |
| TC-LGN-004 | Toast de error con credenciales incorrectas | ✓ | ✓ | V | |
| TC-LGN-005 | Data-driven: admin, lector, erroneas, vacias | ✓ | ✓ | R | |
| TC-LGT-001 | Logout limpia localStorage, redirige a login | ✓ | ✓ | S | |
| TC-LGT-002 | Ruta protegida redirige sin sesion activa | ✓ | ✓ | R | |
| TC-REG-001 | Data-driven registro: exito + errores validacion | ✓ | ✓ | R | Si |
| TC-REG-002 | Cedula solo acepta caracteres numericos | ✓ | — | V | |
| TC-REG-003 | Contrasena minimo 6 caracteres | ✓ | — | V | |

### HU-006 · HU-007 · HU-008 · HU-009 — Catalogo de libros

| TC | Descripcion | Robot | Java | Tipo | D |
|---|---|:---:|:---:|:---:|:---:|
| TC-CAT-001 | Ver catalogo con skeletons de carga | ✓ | ✓ | S | |
| TC-CAT-002 | Busqueda tiempo real filtra titulo y autor | ✓ | ✓ | R | |
| TC-CAT-003 | Busqueda sin resultados muestra mensaje | ✓ | ✓ | V | |
| TC-CAT-004 | Data-driven crear libro (exito + duplicado) | ✓ | ✓ | R | Si |
| TC-CAT-005 | Campos obligatorios vacios muestran error rojo | ✓ | ✓ | V | |
| TC-CAT-006 | Ano no numerico muestra error de validacion | ✓ | — | V | |
| TC-CAT-007 | Boton Crear muestra estado "Creando..." (UX) | ✓ | — | V | |
| TC-CAT-008 | Data-driven editar libro | ✓ | ✓ | R | Si |
| TC-CAT-009 | Libro en edicion resaltado con borde verde (UX) | ✓ | —¹ | R | |
| TC-CAT-010 | Cancelar edicion vuelve a formulario creacion | ✓ | ✓¹ | R | |
| TC-CAT-011 | Eliminar libro: modal de confirmacion aparece | ✓ | ✓ | S | |
| TC-CAT-012 | Cancelar eliminacion no borra el libro | ✓ | ✓ | R | |

¹ Java `CatalogTests` usa el ID TC-CAT-009 para el caso "Cancelar edicion"
  (equivalente al Robot TC-CAT-010). El caso de resaltado visual no tiene
  equivalente en Java.

### HU-010 — Tipos y Generos

| TC | Descripcion | Robot | Java | Tipo | D |
|---|---|:---:|:---:|:---:|:---:|
| TC-TGN-001 | Data-driven agregar tipos y generos | ✓ | ✓ | S* | Si |
| TC-TGN-002 | Campo vacio muestra error obligatorio | ✓ | ✓ | V | |
| TC-TGN-003 | Nombre duplicado case-insensitive muestra error | ✓ | ✓ | V | Si |
| TC-TGN-004 | Editar tipo existente y actualizar | ✓ | ✓ | R | Si |
| TC-TGN-005 | Eliminar tipo requiere confirmacion modal | ✓ | ✓ | R | Si |

\* TC-TGN-001 esta etiquetado `smoke` pero crea datos en el ambiente.

### HU-011 — Dashboard y Estadisticas

| TC | Descripcion | Robot | Java | Tipo | D |
|---|---|:---:|:---:|:---:|:---:|
| TC-DSH-001 | Dashboard accesible para admin | ✓ | ✓ | S | |
| TC-DSH-002 | Data-driven generar grafico con 4 filtros | ✓ | ✓ | R | |
| TC-DSH-003 | Generar sin filtro muestra advertencia | ✓ | ✓ | V | |
| TC-DSH-004 | Boton Sincronizar manual ejecuta sincronizacion | ✓ | ✓ | R | |
| TC-DSH-005 | Boton Generar se deshabilita durante operacion | ✓ | ✓ | V | |
| TC-DSH-006 | Boton muestra "Sincronizando..." durante operacion | ✓ | — | V | |

### HU-004 · HU-005 · HU-013 · HU-014 · HU-015 · HU-016 — Usuarios y Roles

| TC | Descripcion | Robot | Java | Tipo | D |
|---|---|:---:|:---:|:---:|:---:|
| TC-USR-001 | Solo admin accede a pantalla de usuarios | ✓ | ✓ | S | |
| TC-USR-002 | Lista muestra datos completos y badge de rol | ✓ | ✓ | R | |
| TC-USR-003 | Skeletons animados durante carga | ✓ | —² | V | |
| TC-USR-004 | Panel admin muestra tarjetas Usuarios y Redis | ✓ | ✓² | R | |
| TC-USR-005 | Data-driven editar rol de usuario | ✓ | ✓ | R | Si |
| TC-USR-006 | Edicion inline, sin modal flotante | ✓ | ✓ | V | |
| TC-USR-007 | Contrasena vacia en edicion no modifica | ✓ | ✓ | V | |
| TC-USR-008 | Eliminar usuario: modal aparece, se cancela | ✓ | ✓ | R | |
| TC-USR-009 | Solo admin ve tarjeta Redis | ✓ | ✓ | R | |
| TC-USR-010 | Limpiar Redis pide confirmacion y muestra conteo | ✓ | ✓ | R | Si |

² Java `UsersTests` usa TC-USR-003 para el caso "Panel admin" (equivalente al
  Robot TC-USR-004). El caso de skeletons no tiene equivalente en Java.

### Resumen de cobertura

| Area | Robot | Java | Casos unicos |
|---|:---:|:---:|:---:|
| Autenticacion y Registro | 10 | 8 | 10 |
| Catalogo | 12 | 9 | 12 |
| Tipos y Generos | 5 | 5 | 5 |
| Dashboard | 6 | 5 | 6 |
| Usuarios y Roles | 10 | 9 | 10 |
| **Total** | **43** | **36** | **43** |

---

## Evidencias y reportes

### Robot Framework

| Artefacto | Ruta |
|---|---|
| Reporte HTML | `robot/results/logs/report.html` |
| Log detallado | `robot/results/logs/log.html` |
| Output XML (CI) | `robot/results/logs/output.xml` |
| Capturas PNG | `robot/results/screenshots/` |
| Videos GIF | `robot/results/videos/` |

### Java / TestNG

| Artefacto | Ruta |
|---|---|
| ExtentReports HTML | `java/target/extent-reports/` |
| Surefire JUnit XML | `java/target/surefire-reports/` |
| Capturas PNG | `java/target/screenshots/<clase>/<paso>.png` |
| Videos GIF | `java/target/videos/<test>_<fecha>.gif` |

Todos estos directorios estan en `.gitignore`.

---

## Buenas practicas

### Localizadores

Robot centraliza todos en `robot/resources/variables.robot`.

Java usa Page Objects en `java/src/main/java/com/biblioteca/pages/`.

La aplicacion idealmente deberia exponer atributos `data-testid` en botones,
formularios, modales y toasts para localizadores mas estables.

### Esperas

Priorizar esperas explicitas (elemento visible, URL, toast presente, boton
habilitado/deshabilitado). Evitar `Sleep` y `Thread.sleep` sin condicion previa.

### Assertions

Cada caso debe tener al menos un `Assert.*` o keyword de verificacion que
falle el test si el criterio no se cumple.

`testFailureIgnore=false` en `pom.xml` garantiza BUILD FAILURE cuando un test falla.

### Datos

Los registros creados en el ambiente usan prefijo `QA_AUTO_` + timestamp Unix
para no colisionar con datos reales y poder identificarse facilmente.

- Smoke: sin escritura (excepto TC-TGN-001, pendiente revisar).
- Regresion: puede crear y modificar datos QA.
- Destructivo: crea, modifica o elimina datos; requiere ambiente controlado.

---

## Mejoras pendientes

Prioridad media:

- Reemplazar `Sleep` en Robot y `Thread.sleep` en Java por esperas explicitas.
- Agregar `data-testid` en la aplicacion para localizadores mas estables.
- GUI: permitir seleccionar HEADLESS, TAGS y SUITE desde la interfaz.
- GUI: leer screenshots Java de forma recursiva (actualmente solo un nivel).
- Workflow CI: dry-run Robot + compilacion Java + smoke headless en GitHub Actions.

Prioridad baja:

- Agregar TC-REG-002 y TC-REG-003 a `AuthTests.java`.
- Agregar TC-CAT-006, TC-CAT-007 y TC-CAT-009 (visual) a `CatalogTests.java`.
- Agregar TC-DSH-006 a `DashboardTests.java`.
- Revisar el tag `smoke` de TC-TGN-001 (crea datos).
- Parametrizar credenciales admin via variable de entorno para CI seguro.
- Agregar matriz de trazabilidad exportable (HU → TC → evidencia).

---

## Criterio de base QA defendible

El proyecto es una base QA defendible cuando:

- Cualquier persona instala dependencias ejecutando `run_tests.bat` y corre
  smoke sin pasos adicionales.
- Un fallo real en un assertion produce BUILD FAILURE en Maven y FAIL en Robot.
- El smoke no modifica datos del ambiente (excepcion actual: TC-TGN-001).
- Las pruebas destructivas usan datos `QA_AUTO_<ts>` que no colisionan con
  datos reales.
- Cada historia tiene casos trazables y evidencias en las rutas documentadas.
- Los datos son reproducibles: `generar_datos.py` genera un Excel con timestamp
  fresco en cada ejecucion.
- La suite corre en modo headless con `HEADLESS=true` o `mvn test -Dheadless=true`.
