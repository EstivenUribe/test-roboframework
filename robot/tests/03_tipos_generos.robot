*** Settings ***
Documentation       Suite HU-010 — Gestión de Tipos y Géneros
...                 CRUD de tipomaterial y material_genero.
...                 Datos leídos desde hoja "TiposGeneros" del Excel.
Metadata            Módulo      Tipos y Géneros
Metadata            Historias   HU-010

Resource            ../resources/keywords_comunes.robot

Suite Setup         Suite Setup Con Video    alias_video=video_tipos_generos
Suite Teardown      Suite Teardown Con Video    alias_video=video_tipos_generos
Test Setup          Test Setup Estándar
Test Teardown       Test Teardown Estándar

*** Test Cases ***

TC-TGN-001 Agregar tipos y géneros data-driven desde Excel
    [Documentation]    HU-010 · Flujo Principal paso 88-94.
    ...                Itera todos los casos de la hoja "TiposGeneros" con accion=agregar.
    [Tags]    tipos-generos    creacion    data-driven    HU-010    smoke
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_TIPOS_GENEROS}
    ${filas}=    Obtener Datos Hoja    TiposGeneros
    FOR    ${fila}    IN    @{filas}
        IF    '${fila}[accion]' == 'agregar'
            Log    Caso ${fila}[id_caso]: Agregar ${fila}[categoria] → "${fila}[nombre]}"
            IF    '${fila}[categoria]' == 'tipo'
                Wait Until Element Is Visible    ${LOC_TG_INPUT_TIPO}    ${TIMEOUT}
                Limpiar Y Escribir    ${LOC_TG_INPUT_TIPO}    ${fila}[nombre]
                Tomar Captura    ${fila}[id_caso]_tipo_antes
                Click Element    xpath=(//button[contains(text(),'Agregar')])[1]
            ELSE
                Wait Until Element Is Visible    ${LOC_TG_INPUT_GENERO}    ${TIMEOUT}
                Limpiar Y Escribir    ${LOC_TG_INPUT_GENERO}    ${fila}[nombre]
                Tomar Captura    ${fila}[id_caso]_genero_antes
                Click Element    xpath=(//button[contains(text(),'Agregar')])[2]
            END
            IF    '${fila}[resultado_esperado]' == 'exito'
                Wait Until Element Is Visible    ${LOC_TOAST}    12s
                Tomar Captura    ${fila}[id_caso]_agregado_exito
                Page Should Contain    ${fila}[nombre]
            ELSE
                Wait Until Element Is Visible    ${LOC_ERROR_MSG}    8s
                Tomar Captura    ${fila}[id_caso]_error_validacion
            END
        END
    END

TC-TGN-002 Campo vacío muestra "El nombre es obligatorio"
    [Documentation]    HU-010 · Flujo Alt paso 95.
    [Tags]    tipos-generos    validacion    HU-010
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_TIPOS_GENEROS}
    Wait Until Element Is Visible    ${LOC_TG_BTN_AGREGAR}    ${TIMEOUT}
    Click Element    ${LOC_TG_BTN_AGREGAR}
    Tomar Captura    TC-TGN-002_campo_vacio
    Page Should Contain    obligatorio

TC-TGN-003 Nombre duplicado muestra mensaje de duplicado
    [Documentation]    HU-010 · Flujo Alt paso 96 — validación case-insensitive.
    [Tags]    tipos-generos    validacion    HU-010
    ${datos}=    Obtener Fila Por Caso    TiposGeneros    TC-TGN-003
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_TIPOS_GENEROS}
    Wait Until Element Is Visible    ${LOC_TG_INPUT_TIPO}    ${TIMEOUT}
    Limpiar Y Escribir    ${LOC_TG_INPUT_TIPO}    ${datos}[nombre]
    Click Element    xpath=(//button[contains(text(),'Agregar')])[1]
    Wait Until Element Is Visible    ${LOC_TOAST}    12s
    Limpiar Y Escribir    ${LOC_TG_INPUT_TIPO}    ${datos}[nombre_duplicado]
    Click Element    xpath=(//button[contains(text(),'Agregar')])[1]
    Tomar Captura    TC-TGN-003_duplicado
    Page Should Contain    ya existe

TC-TGN-004 Editar tipo existente y actualizar
    [Documentation]    HU-010 · Flujo Alt paso 98 — botón Actualizar y Cancelar.
    [Tags]    tipos-generos    edicion    HU-010
    ${datos}=    Obtener Fila Por Caso    TiposGeneros    TC-TGN-004
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_TIPOS_GENEROS}
    Wait Until Element Is Visible    xpath=//button[contains(text(),'Editar')]    ${TIMEOUT}
    Click Element    xpath=(//button[contains(text(),'Editar')])[1]
    Wait Until Element Is Visible    ${LOC_TG_BTN_ACTUALIZAR}    10s
    Tomar Captura    TC-TGN-004_modo_edicion
    Limpiar Y Escribir    ${LOC_TG_INPUT_TIPO}    ${datos}[nombre_nuevo]
    Click Element    ${LOC_TG_BTN_ACTUALIZAR}
    Wait Until Element Is Visible    ${LOC_TOAST}    12s
    Tomar Captura    TC-TGN-004_actualizado_exito

TC-TGN-005 Eliminar tipo requiere modal de confirmación
    [Documentation]    HU-010 · Flujo Alt paso 99 — modal antes de eliminación.
    [Tags]    tipos-generos    eliminacion    HU-010
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_TIPOS_GENEROS}
    Wait Until Element Is Visible
    ...    xpath=//button[contains(text(),'Borrar') or contains(text(),'Eliminar')]    ${TIMEOUT}
    Click Element
    ...    xpath=(//button[contains(text(),'Borrar') or contains(text(),'Eliminar')])[1]
    Wait Until Element Is Visible    ${LOC_MODAL_CONFIRMAR}    8s
    Tomar Captura    TC-TGN-005_modal_confirmacion
    Element Should Be Visible    ${LOC_MODAL_CONFIRMAR}
    Confirmar Modal
    Wait Until Element Is Visible    ${LOC_TOAST}    12s
    Tomar Captura    TC-TGN-005_eliminado
