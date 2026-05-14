*** Settings ***
Library     SeleniumLibrary     timeout=25s    implicit_wait=0
Library     ScreenCapLibrary
Library     ${CURDIR}/ExcelReader.py
Library     OperatingSystem
Library     Collections
Library     String
Library     DateTime

Resource    variables.robot

*** Keywords ***
# ═══════════════════════════════════════════════════════════════════════════
#  CONFIGURACIÓN DE SESIÓN
# ═══════════════════════════════════════════════════════════════════════════

Suite Setup Con Video
    [Documentation]    Abre navegador, inicia grabación de video y carga Excel.
    [Arguments]    ${alias_video}=suite_video
    Create Directory    ${SCREENSHOTS_DIR}
    Create Directory    ${VIDEOS_DIR}
    Cargar Excel    ${EXCEL_FILE}
    Abrir Navegador De Pruebas
    Set Selenium Timeout    ${TIMEOUT}
    ${grabar_video}=    Convert To Boolean    ${RECORD_VIDEO}
    IF    ${grabar_video}
        ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S
        Start Video Recording
        ...    alias=${alias_video}
        ...    name=${VIDEOS_DIR}/${alias_video}_${ts}
        ...    fps=10
        ...    size_percentage=0.75
    ELSE
        Log    Grabación de video desactivada. Use --variable RECORD_VIDEO:true para activarla.
    END

Suite Teardown Con Video
    [Documentation]    Detiene grabación y cierra el navegador.
    [Arguments]    ${alias_video}=suite_video
    ${grabar_video}=    Convert To Boolean    ${RECORD_VIDEO}
    IF    ${grabar_video}
        Run Keyword And Ignore Error    Stop Video Recording    alias=${alias_video}
    END
    Close All Browsers

Test Setup Estándar
    [Documentation]    Captura inicial del test.
    Limpiar Sesion Navegador
    ${nombre}=    Set Variable    ${TEST NAME}
    Tomar Captura    INICIO_${nombre}

Test Teardown Estándar
    [Documentation]    Captura final e imprime estado del test.
    Run Keyword If Test Failed    Tomar Captura    FALLO_${TEST NAME}
    Run Keyword If Test Passed    Tomar Captura    EXITO_${TEST NAME}

# ═══════════════════════════════════════════════════════════════════════════
#  UTILIDADES GENERALES
# ═══════════════════════════════════════════════════════════════════════════

Abrir Navegador De Pruebas
    [Documentation]    Abre Chrome con opciones estables para ejecución local o headless.
    ${options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    ${window_size}=    Set Variable    --window-size=${WINDOW_WIDTH},${WINDOW_HEIGHT}
    Call Method    ${options}    add_argument    ${window_size}
    Call Method    ${options}    add_argument    --disable-gpu
    Call Method    ${options}    add_argument    --disable-dev-shm-usage
    Call Method    ${options}    add_argument    --no-sandbox
    ${usar_headless}=    Convert To Boolean    ${HEADLESS}
    IF    ${usar_headless}
        ${headless_arg}=    Set Variable    --headless=new
        Call Method    ${options}    add_argument    ${headless_arg}
    END
    Open Browser    ${BASE_URL}    ${BROWSER}    options=${options}
    Set Window Size    ${WINDOW_WIDTH}    ${WINDOW_HEIGHT}
    IF    not ${usar_headless}
        Maximize Browser Window
    END

Limpiar Sesion Navegador
    [Documentation]    Limpia estado de navegador para aislar cada caso.
    Run Keyword And Ignore Error    Execute Javascript    window.localStorage.clear(); window.sessionStorage.clear();
    Run Keyword And Ignore Error    Delete All Cookies

Tomar Captura
    [Documentation]    Guarda screenshot con nombre descriptivo + timestamp.
    [Arguments]    ${prefijo}=captura
    ${ts}=    Get Current Date    result_format=%Y%m%d_%H%M%S%f
    ${nombre_limpio}=    Replace String    ${prefijo}    ${SPACE}    _
    ${ruta}=    Set Variable    ${SCREENSHOTS_DIR}/${nombre_limpio}_${ts}.png
    Capture Page Screenshot    ${ruta}
    Log    Screenshot guardado: ${ruta}

Esperar Toast Y Verificar
    [Documentation]    Espera el mensaje toast y verifica que contenga el texto esperado.
    [Arguments]    ${texto_esperado}    ${timeout}=12s
    Wait Until Element Is Visible    ${LOC_TOAST}    ${timeout}
    ${mensaje}=    Get Text    ${LOC_TOAST}
    Should Contain    ${mensaje}    ${texto_esperado}    ignore_case=True
    Tomar Captura    toast_${texto_esperado}

Esperar Toast Desaparecer
    Wait Until Element Is Not Visible    ${LOC_TOAST}    20s

Esperar Carga Pagina
    [Documentation]    Espera que la página cargue completamente (SPA React).
    [Arguments]    ${selector_esperado}    ${timeout}=20s
    Wait Until Element Is Visible    ${selector_esperado}    ${timeout}
    Sleep    0.5s

Confirmar Modal
    [Documentation]    Confirma un modal de confirmación destructiva.
    Wait Until Element Is Visible    ${LOC_MODAL_CONFIRMAR}    10s
    Tomar Captura    modal_confirmacion
    Click Element    ${LOC_MODAL_CONFIRMAR}

Cancelar Modal
    [Documentation]    Cancela un modal sin ejecutar la acción.
    Wait Until Element Is Visible    ${LOC_MODAL_CANCELAR}    10s
    Click Element    ${LOC_MODAL_CANCELAR}

Limpiar Y Escribir
    [Documentation]    Limpia un campo y escribe el texto dado.
    [Arguments]    ${localizador}    ${texto}
    Wait Until Element Is Visible    ${localizador}    ${TIMEOUT}
    Clear Element Text    ${localizador}
    Input Text    ${localizador}    ${texto}

Seleccionar Opcion En Select
    [Documentation]    Selecciona una opción en un desplegable <select>.
    [Arguments]    ${localizador}    ${texto_visible}
    Wait Until Element Is Visible    ${localizador}    ${TIMEOUT}
    Select From List By Label    ${localizador}    ${texto_visible}

# ═══════════════════════════════════════════════════════════════════════════
#  FLUJOS DE AUTENTICACIÓN
# ═══════════════════════════════════════════════════════════════════════════

Ir A Login
    [Documentation]    Navega a la pantalla de login.
    Go To    ${BASE_URL}
    Wait Until Element Is Visible    ${LOC_LOGIN_EMAIL}    ${TIMEOUT}
    Tomar Captura    pantalla_login

Iniciar Sesion
    [Documentation]    Realiza el flujo completo de login.
    [Arguments]    ${email}    ${password}
    Ir A Login
    Limpiar Y Escribir    ${LOC_LOGIN_EMAIL}    ${email}
    Limpiar Y Escribir    ${LOC_LOGIN_PASS}     ${password}
    Tomar Captura    login_antes_click
    Click Element    ${LOC_LOGIN_BTN}

Iniciar Sesion Como Admin
    [Documentation]    Login con las credenciales del administrador del sistema.
    Iniciar Sesion    ${ADMIN_EMAIL}    ${ADMIN_PASS}
    Esperar Panel Principal

Esperar Panel Principal
    [Documentation]    Verifica que el Panel Principal es visible después del login.
    Wait Until Page Contains Element
    ...    xpath=//*[contains(text(),'Panel') or contains(text(),'Catálogo') or contains(text(),'Dashboard')]
    ...    ${TIMEOUT}
    Tomar Captura    panel_principal

Cerrar Sesion
    [Documentation]    Hace logout desde el panel.
    Wait Until Element Is Visible    ${LOC_BTN_SALIR}    ${TIMEOUT}
    Click Element    ${LOC_BTN_SALIR}
    Wait Until Element Is Visible    ${LOC_LOGIN_EMAIL}    ${TIMEOUT}
    Tomar Captura    logout_exitoso

Navegar A Seccion
    [Documentation]    Hace clic en una tarjeta/enlace del panel para ir a una sección.
    [Arguments]    ${localizador_seccion}
    Wait Until Element Is Visible    ${localizador_seccion}    ${TIMEOUT}
    Click Element    ${localizador_seccion}
    Sleep    1.5s
    Tomar Captura    navegacion_seccion

# ═══════════════════════════════════════════════════════════════════════════
#  FLUJOS DE CATÁLOGO
# ═══════════════════════════════════════════════════════════════════════════

Ingresar Datos Libro
    [Documentation]    Rellena el formulario de libro con los datos proporcionados.
    [Arguments]    ${titulo}    ${autor}    ${año}    ${tipo}    ${genero}
    Limpiar Y Escribir    ${LOC_CAT_TITULO}    ${titulo}
    Limpiar Y Escribir    ${LOC_CAT_AUTOR}     ${autor}
    Limpiar Y Escribir    ${LOC_CAT_AÑO}       ${año}
    Run Keyword And Ignore Error    Seleccionar Opcion En Select    ${LOC_CAT_TIPO}      ${tipo}
    Run Keyword And Ignore Error    Seleccionar Opcion En Select    ${LOC_CAT_GENERO}    ${genero}
    Tomar Captura    formulario_libro_relleno

Verificar Libro En Lista
    [Documentation]    Comprueba que el título del libro aparece en la lista del catálogo.
    [Arguments]    ${titulo}
    Wait Until Page Contains    ${titulo}    ${TIMEOUT}
    Tomar Captura    libro_en_lista_${titulo}
