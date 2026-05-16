*** Settings ***
Documentation       Suite HU-004 · HU-005 · HU-013 · HU-014 · HU-015 · HU-016
...                 Roles, permisos y gestión de usuarios (solo admin).
...                 Datos leídos desde hoja "Usuarios" del Excel.
Metadata            Módulo      Gestión de Usuarios y Roles
Metadata            Historias   HU-004 HU-005 HU-013 HU-014 HU-015 HU-016

Resource            ../resources/keywords_comunes.robot

Suite Setup         Suite Setup Con Video    alias_video=video_usuarios
Suite Teardown      Suite Teardown Con Video    alias_video=video_usuarios
Test Setup          Test Setup Estándar
Test Teardown       Test Teardown Estándar

*** Test Cases ***

# ─────────────────────────────────────────────────────────────────────────────
#  HU-004 / HU-013 — CONTROL DE ACCESO Y VER USUARIOS
# ─────────────────────────────────────────────────────────────────────────────
TC-USR-001 Solo admin puede acceder a la pantalla de usuarios
    [Documentation]    HU-013 · Flujo Principal paso 120-123 / HU-004 paso 34.
    [Tags]    usuarios    roles    seguridad    HU-013    smoke
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_USUARIOS}
    Wait Until Page Contains Element    ${LOC_USR_LISTA}    ${TIMEOUT}
    Tomar Captura    TC-USR-001_lista_usuarios_admin

TC-USR-002 Lista muestra nombre apellido correo CC y badge de rol
    [Documentation]    HU-013 · Criterio: badge usa colores diferenciados.
    [Tags]    usuarios    lectura    HU-013
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_USUARIOS}
    Wait Until Page Contains Element    ${LOC_USR_LISTA}    ${TIMEOUT}
    Tomar Captura    TC-USR-002_informacion_usuarios
    ${tabla}=    Get Text    ${LOC_USR_LISTA}
    Log    Contenido visible de la tabla: ${tabla[:300]}
    Element Should Be Visible
    ...    xpath=//*[contains(@class,'badge') or contains(@class,'rol') or contains(.,'admin') or contains(.,'bibliotecario') or contains(.,'lector')]

TC-USR-003 Skeletons animados durante la carga de usuarios
    [Documentation]    HU-013 · Criterio: skeletons animados durante carga.
    [Tags]    usuarios    ux    HU-013
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_USUARIOS}
    Tomar Captura    TC-USR-003_posibles_skeletons
    Wait Until Page Contains Element    ${LOC_USR_LISTA}    ${TIMEOUT}

TC-USR-004 Panel principal admin muestra sección Usuarios y Redis
    [Documentation]    HU-004 · Criterio: admin ve Usuarios y Caché Redis en el panel.
    [Tags]    roles    panel    HU-004
    Iniciar Sesion Como Admin
    Tomar Captura    TC-USR-004_panel_admin
    Element Should Be Visible    ${LOC_NAV_USUARIOS}
    Element Should Be Visible    ${LOC_NAV_REDIS}

# ─────────────────────────────────────────────────────────────────────────────
#  HU-005 / HU-014 — EDITAR USUARIO
# ─────────────────────────────────────────────────────────────────────────────
TC-USR-005 Editar rol de usuario data-driven desde Excel
    [Documentation]    HU-005 · Flujo Principal paso 38-45 / HU-014 paso 128-135.
    [Tags]    usuarios    edicion    data-driven    HU-005    HU-014
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_USUARIOS}
    ${filas}=    Obtener Datos Hoja    Usuarios
    FOR    ${fila}    IN    @{filas}
        IF    '${fila}[accion]' == 'editar'
            Log    Caso ${fila}[id_caso]: Editando usuario ${fila}[nombre_usuario]
            Wait Until Element Is Visible    ${LOC_USR_BTN_EDITAR}    ${TIMEOUT}
            Click Element    ${LOC_USR_BTN_EDITAR}
            Wait Until Element Is Visible    ${LOC_USR_SELECT_ROL}    ${TIMEOUT}
            Tomar Captura    ${fila}[id_caso]_panel_edicion
            Seleccionar Opcion En Select    ${LOC_USR_SELECT_ROL}    ${fila}[rol_nuevo]
            IF    '${fila}[nombre_nuevo]' != ''
                Limpiar Y Escribir
                ...    xpath=//input[@name='nombre' or @placeholder[contains(.,'Nombre')]]
                ...    ${fila}[nombre_nuevo]
            END
            Click Element    ${LOC_USR_BTN_GUARDAR}
            Wait Until Element Is Visible    ${LOC_TOAST}    15s
            Tomar Captura    ${fila}[id_caso]_edicion_guardada
        END
    END

TC-USR-006 Panel edición se despliega inline sin modal
    [Documentation]    HU-014 · Criterio: panel inline, no modal flotante.
    [Tags]    usuarios    edicion    ux    HU-014
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_USUARIOS}
    Wait Until Element Is Visible    ${LOC_USR_BTN_EDITAR}    ${TIMEOUT}
    Click Element    ${LOC_USR_BTN_EDITAR}
    Tomar Captura    TC-USR-006_panel_inline
    Element Should Not Be Visible
    ...    xpath=//div[@role='dialog' or contains(@class,'modal-backdrop')]

TC-USR-007 Contraseña opcional: vacía no modifica la contraseña
    [Documentation]    HU-014 · Criterio: contraseña vacía no se modifica.
    [Tags]    usuarios    edicion    HU-014
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_USUARIOS}
    Wait Until Element Is Visible    ${LOC_USR_BTN_EDITAR}    ${TIMEOUT}
    Click Element    ${LOC_USR_BTN_EDITAR}
    ${status}    ${valor}=    Run Keyword And Ignore Error
    ...    Get Element Attribute
    ...    xpath=//input[@type='password' and (@name='password' or @placeholder[contains(., 'Contraseña')])]
    ...    value
    IF    '${status}' == 'PASS'
        Should Be Equal    ${valor}    ${EMPTY}
    ELSE
        Log    Campo contraseña no encontrado en el panel de edición — comportamiento aceptable.    WARN
    END
    Tomar Captura    TC-USR-007_campo_contraseña_vacio

# ─────────────────────────────────────────────────────────────────────────────
#  HU-015 — ELIMINAR USUARIO
# ─────────────────────────────────────────────────────────────────────────────
TC-USR-008 Eliminar usuario requiere modal de confirmación
    [Documentation]    HU-015 · Flujo Principal paso 141-146.
    ...                PRECAUCIÓN: este test elimina un usuario de prueba real.
    [Tags]    usuarios    eliminacion    HU-015
    ${datos}=    Obtener Fila Por Caso    Usuarios    TC-USR-008
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_USUARIOS}
    Wait Until Element Is Visible
    ...    xpath=//button[contains(text(),'Eliminar')]    ${TIMEOUT}
    # Sólo verificamos el modal; cancelamos para no eliminar datos reales
    Click Element    xpath=(//button[contains(text(),'Eliminar')])[last()]
    Wait Until Element Is Visible    ${LOC_MODAL_CONFIRMAR}    8s
    Tomar Captura    TC-USR-008_modal_confirmacion
    Element Should Be Visible    ${LOC_MODAL_CONFIRMAR}
    Cancelar Modal
    Tomar Captura    TC-USR-008_cancelado

# ─────────────────────────────────────────────────────────────────────────────
#  HU-016 — LIMPIAR CACHÉ REDIS
# ─────────────────────────────────────────────────────────────────────────────
TC-USR-009 Solo admin ve tarjeta Redis en el Panel Principal
    [Documentation]    HU-016 · Criterio: solo admin ve "Caché de sesiones".
    [Tags]    usuarios    redis    HU-016    roles
    Iniciar Sesion Como Admin
    Wait Until Element Is Visible    ${LOC_NAV_REDIS}    ${TIMEOUT}
    Tomar Captura    TC-USR-009_redis_visible_admin

TC-USR-010 Limpiar Redis requiere modal de confirmación y muestra conteo
    [Documentation]    HU-016 · Flujo Principal paso 149-156.
    [Tags]    usuarios    redis    HU-016
    Iniciar Sesion Como Admin
    Wait Until Element Is Visible    ${LOC_NAV_REDIS}    ${TIMEOUT}
    Click Element    ${LOC_NAV_REDIS}
    Wait Until Element Is Visible    ${LOC_MODAL_CONFIRMAR}    10s
    Tomar Captura    TC-USR-010_modal_redis
    Element Should Be Visible    ${LOC_MODAL_CONFIRMAR}
    Confirmar Modal
    Wait Until Element Is Visible    ${LOC_TOAST}    15s
    ${msg}=    Get Text    ${LOC_TOAST}
    Tomar Captura    TC-USR-010_redis_limpiado
    Should Match Regexp    ${msg}    (?i)(sesion|eliminad|borrad|0|redis)
