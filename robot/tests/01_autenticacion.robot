*** Settings ***
Documentation       Suite HU-001 · HU-002 · HU-003 — Autenticación y Registro
...                 Pruebas data-driven desde hoja "Login" y "Registro" del Excel.
...                 Graba video de toda la suite y toma screenshots en cada test.
Metadata            Módulo          Autenticación
Metadata            Historias       HU-001 HU-002 HU-003
Metadata            Autor           QA Automatización — Biblioteca Pro

Resource            ../resources/keywords_comunes.robot

Suite Setup         Suite Setup Con Video    alias_video=video_autenticacion
Suite Teardown      Suite Teardown Con Video    alias_video=video_autenticacion
Test Setup          Test Setup Estándar
Test Teardown       Test Teardown Estándar

*** Test Cases ***

# ─────────────────────────────────────────────────────────────────────────────
#  HU-002 LOGIN — Flujo principal (camino feliz)
# ─────────────────────────────────────────────────────────────────────────────
TC-LGN-001 Login exitoso con credenciales de administrador
    [Documentation]    HU-002 · Flujo Principal paso 13-20
    ...                El admin ingresa credenciales válidas y llega al Panel Principal.
    [Tags]    login    happy-path    HU-002    smoke
    ${datos}=    Obtener Fila Por Caso    Login    TC-LGN-001
    Iniciar Sesion    ${datos}[email]    ${datos}[password]
    Esperar Panel Principal
    Page Should Contain    ${datos}[texto_esperado_panel]
    Tomar Captura    TC-LGN-001_exito

TC-LGN-002 Badge de rol visible en el header tras login
    [Documentation]    HU-004 · Criterio: el badge del rol se muestra en el header.
    [Tags]    login    roles    HU-004
    Iniciar Sesion Como Admin
    Element Should Be Visible
    ...    xpath=//*[contains(@class,'badge') or contains(text(),'admin') or contains(text(),'Admin')]
    Tomar Captura    TC-LGN-002_badge_rol

TC-LGN-003 Botón Entrar deshabilitado con campos vacíos
    [Documentation]    HU-002 · Criterio: botón deshabilitado si los campos están vacíos.
    [Tags]    login    validacion    HU-002
    Ir A Login
    ${estado}=    Get Element Attribute    ${LOC_LOGIN_BTN}    disabled
    Should Not Be Empty    ${estado}
    Tomar Captura    TC-LGN-003_boton_deshabilitado

# ─────────────────────────────────────────────────────────────────────────────
#  HU-002 LOGIN — Flujos alternativos (manejo de errores)
# ─────────────────────────────────────────────────────────────────────────────
TC-LGN-004 Error toast con credenciales incorrectas
    [Documentation]    HU-002 · Flujo Alt paso 21 — Credenciales incorrectas.
    [Tags]    login    flujo-alternativo    HU-002
    ${datos}=    Obtener Fila Por Caso    Login    TC-LGN-004
    Iniciar Sesion    ${datos}[email]    ${datos}[password]
    Wait Until Element Is Visible    ${LOC_TOAST}    15s
    ${msg}=    Get Text    ${LOC_TOAST}
    Should Contain    ${msg}    ${datos}[mensaje_esperado]    ignore_case=True
    Tomar Captura    TC-LGN-004_toast_error

TC-LGN-005 Login data-driven con múltiples escenarios
    [Documentation]    HU-002 · Itera todos los casos de la hoja "Login" del Excel.
    [Tags]    login    data-driven    HU-002
    ${filas}=    Obtener Datos Hoja    Login
    FOR    ${fila}    IN    @{filas}
        Log    Ejecutando caso: ${fila}[id_caso] — ${fila}[descripcion]
        Iniciar Sesion    ${fila}[email]    ${fila}[password]
        IF    '${fila}[resultado_esperado]' == 'exito'
            Esperar Panel Principal
            Cerrar Sesion
        ELSE
            Wait Until Element Is Visible    ${LOC_TOAST}    15s
            Tomar Captura    ${fila}[id_caso]_fallo_esperado
            Ir A Login
        END
    END

# ─────────────────────────────────────────────────────────────────────────────
#  HU-003 LOGOUT
# ─────────────────────────────────────────────────────────────────────────────
TC-LGT-001 Cerrar sesión limpia localStorage y redirige a login
    [Documentation]    HU-003 · Flujo Principal paso 25-28.
    [Tags]    logout    HU-003    smoke
    Iniciar Sesion Como Admin
    Cerrar Sesion
    ${rol_storage}=    Execute Javascript    return localStorage.getItem('user_rol');
    Should Be Equal    ${rol_storage}    ${None}
    Tomar Captura    TC-LGT-001_localStorage_limpio

TC-LGT-002 Ruta protegida redirige a login sin sesión activa
    [Documentation]    HU-003 · Criterio: ProtectedRoute redirige sin sesión.
    [Tags]    logout    seguridad    HU-003
    Go To    ${BASE_URL}/catalogo
    Wait Until Element Is Visible    ${LOC_LOGIN_EMAIL}    ${TIMEOUT}
    Tomar Captura    TC-LGT-002_protectedroute

# ─────────────────────────────────────────────────────────────────────────────
#  HU-001 REGISTRO
# ─────────────────────────────────────────────────────────────────────────────
TC-REG-001 Registro data-driven con todos los escenarios del Excel
    [Documentation]    HU-001 · Itera todos los casos de la hoja "Registro".
    [Tags]    registro    data-driven    HU-001
    ${filas}=    Obtener Datos Hoja    Registro
    FOR    ${fila}    IN    @{filas}
        Log    Caso: ${fila}[id_caso] — ${fila}[descripcion]
        Ir A Login
        Click Element    ${LOC_LINK_CREAR_CUENTA}
        Wait Until Element Is Visible    ${LOC_REG_NOMBRE}    ${TIMEOUT}
        Limpiar Y Escribir    ${LOC_REG_NOMBRE}      ${fila}[nombre]
        Limpiar Y Escribir    ${LOC_REG_APELLIDO}    ${fila}[apellido]
        Limpiar Y Escribir    ${LOC_REG_CEDULA}      ${fila}[cedula]
        Limpiar Y Escribir    ${LOC_REG_EMAIL}       ${fila}[email]
        Limpiar Y Escribir    ${LOC_REG_PASS}        ${fila}[password]
        Tomar Captura    ${fila}[id_caso]_formulario_registro
        Click Element    ${LOC_REG_BTN}
        IF    '${fila}[resultado_esperado]' == 'exito'
            Wait Until Element Is Visible    ${LOC_TOAST}    15s
            Tomar Captura    ${fila}[id_caso]_registro_exitoso
        ELSE
            Wait Until Element Is Visible    ${LOC_ERROR_MSG}    10s
            ${error_txt}=    Get Text    ${LOC_ERROR_MSG}
            Log    Error esperado visible: ${error_txt}
            Tomar Captura    ${fila}[id_caso]_error_validacion
        END
    END

TC-REG-002 Cédula solo acepta caracteres numéricos
    [Documentation]    HU-001 · Flujo Alt paso 9.
    [Tags]    registro    validacion    HU-001
    ${datos}=    Obtener Fila Por Caso    Registro    TC-REG-002
    Ir A Login
    Click Element    ${LOC_LINK_CREAR_CUENTA}
    Wait Until Element Is Visible    ${LOC_REG_CEDULA}    ${TIMEOUT}
    Limpiar Y Escribir    ${LOC_REG_CEDULA}    ${datos}[cedula]
    Tomar Captura    TC-REG-002_cedula_invalida
    Page Should Contain    ${datos}[mensaje_error]

TC-REG-003 Contraseña mínimo 6 caracteres
    [Documentation]    HU-001 · Flujo Alt paso 10.
    [Tags]    registro    validacion    HU-001
    ${datos}=    Obtener Fila Por Caso    Registro    TC-REG-003
    Ir A Login
    Click Element    ${LOC_LINK_CREAR_CUENTA}
    Wait Until Element Is Visible    ${LOC_REG_PASS}    ${TIMEOUT}
    Limpiar Y Escribir    ${LOC_REG_PASS}    ${datos}[password]
    Click Element    ${LOC_REG_BTN}
    Tomar Captura    TC-REG-003_pass_corta
    Page Should Contain    ${datos}[mensaje_error]
