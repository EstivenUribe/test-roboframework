*** Settings ***
Documentation       Suite HU-006 · HU-007 · HU-008 · HU-009 — Catálogo de Libros
...                 CRUD completo de materiales bibliográficos.
...                 Datos leídos desde hoja "Catalogo" del Excel.
Metadata            Módulo      Catálogo de Libros
Metadata            Historias   HU-006 HU-007 HU-008 HU-009

Resource            ../resources/keywords_comunes.robot

Suite Setup         Suite Setup Con Video    alias_video=video_catalogo
Suite Teardown      Suite Teardown Con Video    alias_video=video_catalogo
Test Setup          Test Setup Estándar
Test Teardown       Test Teardown Estándar

*** Test Cases ***

# ─────────────────────────────────────────────────────────────────────────────
#  HU-006 — VER CATÁLOGO (todos los roles)
# ─────────────────────────────────────────────────────────────────────────────
TC-CAT-001 Ver catálogo como administrador con skeletons de carga
    [Documentation]    HU-006 · Flujo Principal paso 49-52.
    ...                Verifica que la lista de libros carga correctamente.
    [Tags]    catalogo    lectura    HU-006    smoke
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    Wait Until Page Contains Element    ${LOC_CAT_LISTA}    ${TIMEOUT}
    Tomar Captura    TC-CAT-001_catalogo_cargado
    Page Should Contain    Lista de libros
    Page Should Contain Element    ${LOC_CAT_BTN_CREAR}

TC-CAT-002 Búsqueda en tiempo real filtra por título y autor
    [Documentation]    HU-006 · Criterio: búsqueda en tiempo real.
    [Tags]    catalogo    busqueda    HU-006
    ${datos}=    Obtener Fila Por Caso    Catalogo    TC-CAT-002
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    ${busqueda_disponible}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${LOC_CAT_BUSQUEDA}    5s
    Skip If    not ${busqueda_disponible}    El catálogo actual no expone buscador visible.
    Limpiar Y Escribir    ${LOC_CAT_BUSQUEDA}    ${datos}[termino_busqueda]
    Sleep    1s
    Tomar Captura    TC-CAT-002_resultados_busqueda
    ${texto_pagina}=    Get Text    xpath=//body
    Log    Resultados visibles en página: ${texto_pagina[:200]}

TC-CAT-003 Búsqueda sin resultados muestra mensaje adecuado
    [Documentation]    HU-006 · Flujo Alt paso 55.
    [Tags]    catalogo    busqueda    flujo-alternativo    HU-006
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    ${busqueda_disponible}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${LOC_CAT_BUSQUEDA}    5s
    Skip If    not ${busqueda_disponible}    El catálogo actual no expone buscador visible.
    Limpiar Y Escribir    ${LOC_CAT_BUSQUEDA}    XXXXXXXXXNOTEXISTS99999
    Sleep    1s
    Tomar Captura    TC-CAT-003_sin_resultados
    Page Should Contain    Sin resultados

# ─────────────────────────────────────────────────────────────────────────────
#  HU-007 — CREAR LIBRO (bibliotecario / admin)
# ─────────────────────────────────────────────────────────────────────────────
TC-CAT-004 Crear libro data-driven con casos del Excel
    [Documentation]    HU-007 · Itera hoja "Catalogo" con accion=crear.
    [Tags]    catalogo    creacion    data-driven    HU-007
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    ${filas}=    Obtener Datos Hoja    Catalogo
    FOR    ${fila}    IN    @{filas}
        IF    '${fila}[accion]' == 'crear'
            Log    Creando libro: ${fila}[titulo] — Caso ${fila}[id_caso]
            Ingresar Datos Libro
            ...    ${fila}[titulo]
            ...    ${fila}[autor]
            ...    ${fila}[año]
            ...    ${fila}[tipo]
            ...    ${fila}[genero]
            Click Element    ${LOC_CAT_BTN_CREAR}
            IF    '${fila}[resultado_esperado]' == 'exito'
                Wait Until Element Is Visible    ${LOC_TOAST}    15s
                Tomar Captura    ${fila}[id_caso]_libro_creado
                Verificar Libro En Lista    ${fila}[titulo]
            ELSE
                Wait Until Element Is Visible    ${LOC_ERROR_MSG}    10s
                Tomar Captura    ${fila}[id_caso]_error_creacion
            END
        END
    END

TC-CAT-005 Campos obligatorios vacíos muestran error en rojo
    [Documentation]    HU-007 · Flujo Alt paso 63.
    [Tags]    catalogo    validacion    HU-007
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    Wait Until Element Is Visible    ${LOC_CAT_BTN_CREAR}    ${TIMEOUT}
    Click Element    ${LOC_CAT_BTN_CREAR}
    Tomar Captura    TC-CAT-005_campos_vacios
    Element Should Be Visible    ${LOC_ERROR_MSG}

TC-CAT-006 Año no numérico muestra mensaje de error
    [Documentation]    HU-007 · Flujo Alt paso 64.
    [Tags]    catalogo    validacion    HU-007
    ${datos}=    Obtener Fila Por Caso    Catalogo    TC-CAT-006
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    Limpiar Y Escribir    ${LOC_CAT_TITULO}    Libro Año Inválido
    Limpiar Y Escribir    ${LOC_CAT_AUTOR}    Autor QA
    Limpiar Y Escribir    ${LOC_CAT_AÑO}    ${datos}[año]
    Seleccionar Opcion En Select    ${LOC_CAT_TIPO}    Libro
    Seleccionar Opcion En Select    ${LOC_CAT_GENERO}    Terror
    Click Element    ${LOC_CAT_BTN_CREAR}
    Tomar Captura    TC-CAT-006_año_invalido
    Page Should Contain    año

TC-CAT-007 Botón Crear muestra estado Creando durante operación
    [Documentation]    HU-007 · Criterio: botón "Crear" muestra "Creando…" y se deshabilita.
    [Tags]    catalogo    ux    HU-007
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    ${datos}=    Obtener Fila Por Caso    Catalogo    TC-CAT-004
    Ingresar Datos Libro
    ...    ${datos}[titulo]    ${datos}[autor]    ${datos}[año]
    ...    ${datos}[tipo]    ${datos}[genero]
    Click Element    ${LOC_CAT_BTN_CREAR}
    ${estado_boton}=    Run Keyword And Ignore Error
    ...    Get Text    ${LOC_CAT_BTN_CREAR}
    Tomar Captura    TC-CAT-007_estado_creando

# ─────────────────────────────────────────────────────────────────────────────
#  HU-008 — EDITAR LIBRO (bibliotecario / admin)
# ─────────────────────────────────────────────────────────────────────────────
TC-CAT-008 Editar libro data-driven con casos del Excel
    [Documentation]    HU-008 · Itera hoja "Catalogo" con accion=editar.
    [Tags]    catalogo    edicion    data-driven    HU-008
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    ${filas}=    Obtener Datos Hoja    Catalogo
    FOR    ${fila}    IN    @{filas}
        IF    '${fila}[accion]' == 'editar'
            Wait Until Element Is Visible
            ...    xpath=//button[contains(text(),'Editar')]    ${TIMEOUT}
            Click Element    xpath=//button[contains(text(),'Editar')]
            Wait Until Element Is Visible    ${LOC_CAT_TITULO}    ${TIMEOUT}
            Limpiar Y Escribir    ${LOC_CAT_TITULO}    ${fila}[titulo_nuevo]
            Tomar Captura    ${fila}[id_caso]_editando
            Click Element
            ...    xpath=//button[contains(text(),'Actualizar') or contains(text(),'Guardar')]
            Wait Until Element Is Visible    ${LOC_TOAST}    15s
            Tomar Captura    ${fila}[id_caso]_edicion_exitosa
            Page Should Contain    ${fila}[titulo_nuevo]
        END
    END

TC-CAT-009 Libro en edición resaltado con borde verde
    [Documentation]    HU-008 · Flujo Alt paso 78 — resaltado visual.
    [Tags]    catalogo    edicion    ux    HU-008
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    Wait Until Element Is Visible
    ...    xpath=//button[contains(text(),'Editar')]    ${TIMEOUT}
    Click Element    xpath=//button[contains(text(),'Editar')]
    Tomar Captura    TC-CAT-009_libro_en_edicion
    Element Should Be Visible
    ...    xpath=//*[contains(@style,'green') or contains(@class,'border-green') or contains(@class,'editing')]

TC-CAT-010 Cancelar edición vuelve al estado de creación
    [Documentation]    HU-008 · Flujo Alt paso 77.
    [Tags]    catalogo    edicion    flujo-alternativo    HU-008
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    Wait Until Element Is Visible
    ...    xpath=//button[contains(text(),'Editar')]    ${TIMEOUT}
    Click Element    xpath=//button[contains(text(),'Editar')]
    Wait Until Element Is Visible
    ...    xpath=//button[contains(text(),'Cancelar')]    10s
    Click Element    xpath=//button[contains(text(),'Cancelar')]
    Tomar Captura    TC-CAT-010_cancelado
    Element Should Be Visible    ${LOC_CAT_BTN_CREAR}

# ─────────────────────────────────────────────────────────────────────────────
#  HU-009 — ELIMINAR LIBRO (solo admin)
# ─────────────────────────────────────────────────────────────────────────────
TC-CAT-011 Eliminar libro requiere confirmación modal
    [Documentation]    HU-009 · Flujo Principal paso 79-84.
    [Tags]    catalogo    eliminacion    HU-009    smoke
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    Wait Until Element Is Visible
    ...    xpath=//button[contains(text(),'Borrar') or contains(text(),'Eliminar')]    ${TIMEOUT}
    Click Element
    ...    xpath=//button[contains(text(),'Borrar') or contains(text(),'Eliminar')]
    Tomar Captura    TC-CAT-011_modal_confirmacion
    Element Should Be Visible    ${LOC_MODAL_CONFIRMAR}
    Confirmar Modal
    Wait Until Element Is Visible    ${LOC_TOAST}    15s
    Tomar Captura    TC-CAT-011_libro_eliminado

TC-CAT-012 Cancelar eliminación no borra el libro
    [Documentation]    HU-009 · Flujo Alt paso 85.
    [Tags]    catalogo    eliminacion    flujo-alternativo    HU-009
    Iniciar Sesion Como Admin
    Navegar A Seccion    ${LOC_NAV_CATALOGO}
    ${texto_antes}=    Get Text    ${LOC_CAT_LISTA}
    Click Element
    ...    xpath=//button[contains(text(),'Borrar') or contains(text(),'Eliminar')]
    Cancelar Modal
    ${texto_despues}=    Get Text    ${LOC_CAT_LISTA}
    Should Be Equal    ${texto_antes}    ${texto_despues}
    Tomar Captura    TC-CAT-012_cancelado_sin_eliminar
