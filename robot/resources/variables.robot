*** Variables ***
# URL y navegador
${BASE_URL}             https://biblioteca-front-end-1satou1s-projects.vercel.app
${BROWSER}              chrome
${TIMEOUT}              25s
${SHORT_WAIT}           5s
${HEADLESS}             ${FALSE}
${RECORD_VIDEO}         ${FALSE}
${WINDOW_WIDTH}         1366
${WINDOW_HEIGHT}        900

# Credenciales de administrador (manual_usuario_v2 - Sección 3)
${ADMIN_EMAIL}          migueltroll789@gmail.com
${ADMIN_PASS}           123456

# Rutas de datos y resultados
${EXCEL_FILE}           ${CURDIR}/../data/datos_prueba.xlsx
${SCREENSHOTS_DIR}      ${CURDIR}/../results/screenshots
${VIDEOS_DIR}           ${CURDIR}/../results/videos

# ─── Localizadores: Login ───────────────────────────────────────────────────
${LOC_LOGIN_EMAIL}          xpath=//input[@type='email' or @placeholder[contains(translate(.,'CORREO','correo'),'correo')] or @name='email']
${LOC_LOGIN_PASS}           xpath=//input[@type='password']
${LOC_LOGIN_BTN}            xpath=//button[contains(translate(text(),'ENTRAR','entrar'),'entrar') or contains(text(),'Entrar') or @type='submit']
${LOC_LINK_CREAR_CUENTA}    xpath=//*[contains(text(),'Crear cuenta') or contains(text(),'crear cuenta')]

# ─── Localizadores: Registro ────────────────────────────────────────────────
${LOC_REG_NOMBRE}       xpath=//input[@placeholder[contains(translate(.,'NOMBRE','nombre'),'nombre')] or @name='nombre' or @id='nombre']
${LOC_REG_APELLIDO}     xpath=//input[@placeholder[contains(translate(.,'APELLIDO','apellido'),'apellido')] or @name='apellido']
${LOC_REG_CEDULA}       xpath=//input[@placeholder[contains(translate(.,'CÉDULACEDULA','cédulaedula'),'dula')] or @name='cedula' or @name='cc']
${LOC_REG_EMAIL}        xpath=//input[@type='email' or @name='email' or @placeholder[contains(translate(.,'CORREO','correo'),'correo')]]
${LOC_REG_PASS}         xpath=//input[@type='password' or @name='password' or @name='contraseña']
${LOC_REG_BTN}          xpath=//button[contains(text(),'Crear cuenta') or contains(text(),'Registrar')]

# ─── Localizadores: Panel Principal ─────────────────────────────────────────
${LOC_BTN_SALIR}            xpath=//button[contains(normalize-space(.),'Salir') or contains(normalize-space(.),'Cerrar sesión')]
${LOC_NAV_CATALOGO}         xpath=(//button[contains(normalize-space(.),'Ver catálogo') or contains(normalize-space(.),'Ver catalogo')] | //a[contains(normalize-space(.),'Ver catálogo') or contains(normalize-space(.),'Ver catalogo')])[1]
${LOC_NAV_TIPOS_GENEROS}    xpath=(//button[normalize-space(.)='Agregar'] | //a[normalize-space(.)='Agregar'])[1]
${LOC_NAV_DASHBOARD}        xpath=(//button[normalize-space(.)='Buscar'] | //a[normalize-space(.)='Buscar'])[1]
${LOC_NAV_USUARIOS}         xpath=(//button[normalize-space(.)='Gestionar'] | //a[normalize-space(.)='Gestionar'])[1]
${LOC_NAV_REDIS}            xpath=//button[contains(normalize-space(.),'Borrar sesiones Redis') or contains(normalize-space(.),'Redis')]

# ─── Localizadores: Catálogo ─────────────────────────────────────────────────
${LOC_CAT_TITULO}       xpath=(//input[@name='titulo' or @name='title'] | //label[contains(normalize-space(.),'Título')]/following::input[1] | //input[@placeholder[contains(translate(.,'TÍTULO','título'),'tulo')]])[1]
${LOC_CAT_AUTOR}        xpath=(//input[@name='autor' or @name='author'] | //label[contains(normalize-space(.),'Autor')]/following::input[1] | //input[@placeholder[contains(translate(.,'AUTOR','autor'),'autor')]])[1]
${LOC_CAT_AÑO}          xpath=(//input[@name='año' or @name='year' or @type='number'] | //label[contains(normalize-space(.),'Año')]/following::input[1] | //input[@placeholder[contains(translate(.,'AÑO','año'),'año')]])[1]
${LOC_CAT_TIPO}         xpath=(//select[@name='tipo' or @name='type'] | //label[contains(normalize-space(.),'Tipo')]/following::select[1] | //div[contains(@class,'select')][contains(.,'Tipo')])[1]
${LOC_CAT_GENERO}       xpath=(//select[@name='genero' or @name='genre'] | //label[contains(normalize-space(.),'Género')]/following::select[1] | //div[contains(@class,'select')][contains(.,'Género')])[1]
${LOC_CAT_BTN_CREAR}    xpath=//button[contains(text(),'Crear') or @type='submit'][not(contains(text(),'Cuenta'))]
${LOC_CAT_BUSQUEDA}     xpath=//input[@placeholder[contains(translate(.,'BUSCAR','buscar'),'buscar')] or @type='search']
${LOC_CAT_LISTA}        xpath=//*[contains(normalize-space(.),'Lista de libros') and contains(normalize-space(.),'Editar') and contains(normalize-space(.),'Borrar')]

# ─── Localizadores: Dashboard ────────────────────────────────────────────────
${LOC_DASH_FILTRO}          xpath=//select[1] | //div[contains(@class,'select')][1]
${LOC_DASH_BTN_GENERAR}     xpath=//button[contains(text(),'Generar')]
${LOC_DASH_BTN_SYNC}        xpath=//button[contains(text(),'Sincronizar') or contains(text(),'↻')]
${LOC_DASH_GRAFICO}         xpath=//*[contains(@class,'chart') or contains(@class,'dona') or name()='canvas']

# ─── Localizadores: Tipos / Géneros ──────────────────────────────────────────
${LOC_TG_INPUT_TIPO}        xpath=(//input[@placeholder[contains(translate(.,'TIPO','tipo'),'tipo')] or @name='tipo'])[1]
${LOC_TG_INPUT_GENERO}      xpath=(//input[@placeholder[contains(translate(.,'GÉNERO','género'),'nero')] or @name='genero'])[1]
${LOC_TG_BTN_AGREGAR}       xpath=//button[contains(text(),'Agregar')]
${LOC_TG_BTN_ACTUALIZAR}    xpath=//button[contains(text(),'Actualizar')]

# ─── Localizadores: Usuarios ─────────────────────────────────────────────────
${LOC_USR_LISTA}        xpath=//*[contains(normalize-space(.),'Gestión de Usuarios') or (contains(normalize-space(.),'Editar') and contains(normalize-space(.),'Eliminar') and contains(normalize-space(.),'CC:'))]
${LOC_USR_BTN_EDITAR}   xpath=(//button[contains(text(),'Editar')])[1]
${LOC_USR_BTN_GUARDAR}  xpath=//button[contains(text(),'Guardar')]
${LOC_USR_SELECT_ROL}   xpath=//select[@name='rol' or @name='role'] | //select[contains(.,'admin') or contains(.,'lector')]

# ─── Localizadores: Mensajes ─────────────────────────────────────────────────
${LOC_TOAST}            xpath=//*[contains(@class,'toast') or contains(@class,'alert') or contains(@class,'notification') or contains(@class,'Toastify')]
${LOC_MODAL_CONFIRMAR}  xpath=//button[contains(text(),'Sí') or contains(text(),'Confirmar')]
${LOC_MODAL_CANCELAR}   xpath=//button[contains(text(),'Cancelar') or contains(text(),'No')]
${LOC_ERROR_MSG}        xpath=//*[contains(@class,'error') or contains(@class,'invalid') or contains(@class,'danger') or contains(normalize-space(.),'obligatorio') or contains(normalize-space(.),'inválido') or contains(normalize-space(.),'número')][string-length(normalize-space(.))>0]
