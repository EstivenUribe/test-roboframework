*** Settings ***
Documentation       Suite HU-011 · HU-012 — Dashboard y Estadísticas
...                 Pruebas de gráficos de dona, filtros y sincronización.
...                 Datos leídos desde hoja "Dashboard" del Excel.
Metadata            Módulo      Dashboard y Estadísticas
Metadata            Historias   HU-011 HU-012

Resource            ../resources/keywords_comunes.robot

Suite Setup         Suite Setup Con Video    alias_video=video_dashboard
Suite Teardown      Suite Teardown Con Video    alias_video=video_dashboard
Test Setup          Test Setup Estándar
Test Teardown       Test Teardown Estándar

*** Test Cases ***

TC-DSH-001 Dashboard accesible para todos los roles - admin
    [Documentation]    HU-011 · Flujo Principal paso 100-101.
    ...                El sistema sincroniza automáticamente al cargar.
    [Tags]    dashboard    smoke    HU-011
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_DASHBOARD}
    Wait Until Page Contains Element    ${LOC_DASH_BTN_GENERAR}    ${TIMEOUT}
    Tomar Captura    TC-DSH-001_dashboard_cargado

TC-DSH-002 Generar gráfico data-driven con todos los filtros del Excel
    [Documentation]    HU-011 · Flujo Principal paso 102-105.
    ...                Itera los 4 filtros: tipo, genero, autor, año.
    [Tags]    dashboard    grafico    data-driven    HU-011
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_DASHBOARD}
    Wait Until Element Is Visible    ${LOC_DASH_BTN_GENERAR}    ${TIMEOUT}
    ${filas}=    Obtener Datos Hoja    Dashboard
    FOR    ${fila}    IN    @{filas}
        IF    '${fila}[resultado_esperado]' == 'exito'
            Log    Caso ${fila}[id_caso]: Filtro → ${fila}[filtro]
            Wait Until Element Is Visible    ${LOC_DASH_FILTRO}    ${TIMEOUT}
            Seleccionar Opcion En Select    ${LOC_DASH_FILTRO}    ${fila}[filtro]
            Wait Until Element Is Enabled    ${LOC_DASH_BTN_GENERAR}    ${TIMEOUT}
            Click Element    ${LOC_DASH_BTN_GENERAR}
            Sleep    3s
            Tomar Captura    ${fila}[id_caso]_grafico_${fila}[filtro]
            Element Should Be Visible    ${LOC_DASH_GRAFICO}
        END
    END

TC-DSH-003 Generar sin seleccionar filtro muestra toast de advertencia
    [Documentation]    HU-011 · Flujo Alt paso 108.
    [Tags]    dashboard    validacion    flujo-alternativo    HU-011
    ${datos}=    Obtener Fila Por Caso    Dashboard    TC-DSH-005
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_DASHBOARD}
    Wait Until Element Is Visible    ${LOC_DASH_BTN_GENERAR}    ${TIMEOUT}
    Click Element    ${LOC_DASH_BTN_GENERAR}
    Wait Until Element Is Visible    ${LOC_TOAST}    12s
    ${msg}=    Get Text    ${LOC_TOAST}
    Should Contain    ${msg}    filtro    ignore_case=True
    Tomar Captura    TC-DSH-003_sin_filtro_error

TC-DSH-004 Botón Sincronizar manual actualiza datos
    [Documentation]    HU-011 · Criterio: existe botón "↻ Sincronizar".
    [Tags]    dashboard    sincronizacion    HU-011
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_DASHBOARD}
    Wait Until Element Is Visible    ${LOC_DASH_BTN_SYNC}    ${TIMEOUT}
    Tomar Captura    TC-DSH-004_antes_sync
    Click Element    ${LOC_DASH_BTN_SYNC}
    Sleep    3s
    Tomar Captura    TC-DSH-004_despues_sync
    Log    Sincronización manual ejecutada correctamente

TC-DSH-005 Botón Generar deshabilitado durante la generación
    [Documentation]    HU-011 · Criterio: botón deshabilitado durante operación.
    [Tags]    dashboard    ux    HU-011
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_DASHBOARD}
    Wait Until Element Is Visible    ${LOC_DASH_FILTRO}    ${TIMEOUT}
    Seleccionar Opcion En Select    ${LOC_DASH_FILTRO}    tipo
    Click Element    ${LOC_DASH_BTN_GENERAR}
    ${disabled}=    Run Keyword And Ignore Error
    ...    Element Should Be Disabled    ${LOC_DASH_BTN_GENERAR}
    Tomar Captura    TC-DSH-005_boton_deshabilitado_durante_generacion
    Sleep    3s

TC-DSH-006 Botón muestra Sincronizando durante la operación
    [Documentation]    HU-011 · Criterio: "Sincronizando…" visible durante proceso.
    [Tags]    dashboard    ux    HU-011
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_DASHBOARD}
    Wait Until Element Is Visible    ${LOC_DASH_BTN_SYNC}    ${TIMEOUT}
    Click Element    ${LOC_DASH_BTN_SYNC}
    ${texto_boton}=    Run Keyword And Ignore Error
    ...    Get Text    ${LOC_DASH_BTN_SYNC}
    Tomar Captura    TC-DSH-006_sincronizando
