"""
generar_datos.py
Genera el archivo Excel de datos de prueba para Biblioteca Pro.
Ejecutar: python generar_datos.py
"""
import os
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

OUTPUT = os.path.join(os.path.dirname(__file__), "datos_prueba.xlsx")

VERDE_OSCURO  = "1B5E20"
VERDE_CLARO   = "C8E6C9"
AMARILLO      = "FFF9C4"
ROJO_CLARO    = "FFCDD2"
BLANCO        = "FFFFFF"

def estilo_encabezado(ws, fila=1):
    for cell in ws[fila]:
        cell.font      = Font(bold=True, color="FFFFFF", size=10)
        cell.fill      = PatternFill("solid", fgColor=VERDE_OSCURO)
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        borde = Side(style="thin", color="000000")
        cell.border = Border(left=borde, right=borde, top=borde, bottom=borde)
    ws.row_dimensions[fila].height = 20

def estilo_fila(ws, fila, color=BLANCO):
    for cell in ws[fila]:
        cell.fill      = PatternFill("solid", fgColor=color)
        cell.alignment = Alignment(vertical="center", wrap_text=True)
        borde = Side(style="thin", color="CCCCCC")
        cell.border = Border(left=borde, right=borde, top=borde, bottom=borde)

def autoajustar_columnas(ws):
    for col in ws.columns:
        max_len = max((len(str(c.value)) if c.value else 0) for c in col)
        ws.column_dimensions[get_column_letter(col[0].column)].width = min(max_len + 4, 40)

# ═══════════════════════════════════════════════════════════════════
#  HOJA: Login
# ═══════════════════════════════════════════════════════════════════
def hoja_login(wb):
    ws = wb.create_sheet("Login")
    encabezados = [
        "id_caso", "descripcion", "email", "password",
        "resultado_esperado", "mensaje_esperado", "texto_esperado_panel"
    ]
    ws.append(encabezados)
    datos = [
        ("TC-LGN-001", "Login válido con admin",
         "migueltroll789@gmail.com", "123456",
         "exito", "", "Panel"),
        ("TC-LGN-002", "Rol lector con cuenta existente",
         "lector@biblioteca.com", "lector123",
         "exito", "", "Catálogo"),
        ("TC-LGN-004", "Contraseña incorrecta",
         "migueltroll789@gmail.com", "WRONG_PASS",
         "error", "Credenciales incorrectas", ""),
        ("TC-LGN-005", "Email inexistente",
         "no_existe@falso.com", "cualquier",
         "error", "Credenciales incorrectas", ""),
        ("TC-LGN-006", "Email malformado",
         "no_es_email", "123456",
         "error", "", ""),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        color = VERDE_CLARO if fila[4] == "exito" else ROJO_CLARO
        estilo_fila(ws, i, color)
    estilo_encabezado(ws)
    autoajustar_columnas(ws)

# ═══════════════════════════════════════════════════════════════════
#  HOJA: Registro
# ═══════════════════════════════════════════════════════════════════
def hoja_registro(wb):
    ws = wb.create_sheet("Registro")
    encabezados = [
        "id_caso", "descripcion", "nombre", "apellido",
        "cedula", "email", "password",
        "resultado_esperado", "mensaje_error"
    ]
    ws.append(encabezados)
    import time
    ts = str(int(time.time()))
    datos = [
        ("TC-REG-001", "Registro válido completo",
         "Juan", "Prueba", "12345678",
         f"junit_test_{ts}@automatizacion.test", "password123",
         "exito", ""),
        ("TC-REG-002", "Campo nombre vacío",
         "", "Prueba", "12345678",
         "test2@automatizacion.test", "password123",
         "error", "obligatorio"),
        ("TC-REG-003", "Cédula con letras — HU-001 paso 9",
         "Ana", "Gómez", "ABC123",
         "test3@automatizacion.test", "password123",
         "error", "solo debe contener números"),
        ("TC-REG-004", "Contraseña < 6 chars — HU-001 paso 10",
         "Pedro", "López", "98765432",
         "test4@automatizacion.test", "123",
         "error", "Mínimo 6"),
        ("TC-REG-005", "Correo ya existe — HU-001 paso 11",
         "Miguel", "Admin", "11111111",
         "migueltroll789@gmail.com", "password123",
         "error", ""),
        ("TC-REG-006", "Apellido vacío",
         "Laura", "", "55667788",
         "test6@automatizacion.test", "passOK123",
         "error", "obligatorio"),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        color = VERDE_CLARO if fila[7] == "exito" else ROJO_CLARO
        estilo_fila(ws, i, color)
    estilo_encabezado(ws)
    autoajustar_columnas(ws)

# ═══════════════════════════════════════════════════════════════════
#  HOJA: Catalogo
# ═══════════════════════════════════════════════════════════════════
def hoja_catalogo(wb):
    ws = wb.create_sheet("Catalogo")
    encabezados = [
        "id_caso", "descripcion", "accion",
        "titulo", "autor", "año", "tipo", "genero",
        "titulo_nuevo",
        "resultado_esperado", "mensaje_error", "termino_busqueda"
    ]
    ws.append(encabezados)
    datos = [
        # Casos búsqueda
        ("TC-CAT-002", "Búsqueda por título existente", "buscar",
         "", "", "", "", "", "", "exito", "", "Don Quijote"),
        # Casos crear (válidos)
        ("TC-CAT-004", "Crear libro completo válido", "crear",
         "Don Quijote de la Mancha", "Miguel de Cervantes", "1605",
         "Libro", "Novela", "", "exito", "", ""),
        ("TC-CAT-004B", "Crear revista técnica", "crear",
         "IEEE Software Vol 40", "IEEE", "2023",
         "Revista", "Tecnología", "", "exito", "", ""),
        ("TC-CAT-004C", "Crear tesis de grado", "crear",
         "Optimización de algoritmos", "Carlos Pérez", "2022",
         "Tesis", "Ingeniería", "", "exito", "", ""),
        # Casos crear (inválidos)
        ("TC-CAT-005B", "Título vacío en creación", "crear",
         "", "Autor Test", "2020", "Libro", "Terror",
         "", "error", "obligatorio", ""),
        ("TC-CAT-006", "Año con letras — HU-007 paso 64", "crear",
         "Libro Inválido", "Autor", "veinte", "Libro", "Terror",
         "", "error", "número entero positivo", ""),
        # Casos editar
        ("TC-CAT-008", "Editar título de libro existente", "editar",
         "", "", "", "", "", "Don Quijote — Edición Actualizada",
         "exito", "", ""),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        color = VERDE_CLARO if fila[9] == "exito" else ROJO_CLARO if fila[9] == "error" else AMARILLO
        estilo_fila(ws, i, color)
    estilo_encabezado(ws)
    autoajustar_columnas(ws)

# ═══════════════════════════════════════════════════════════════════
#  HOJA: TiposGeneros
# ═══════════════════════════════════════════════════════════════════
def hoja_tipos_generos(wb):
    ws = wb.create_sheet("TiposGeneros")
    encabezados = [
        "id_caso", "descripcion", "accion", "categoria",
        "nombre", "nombre_duplicado", "nombre_nuevo",
        "resultado_esperado"
    ]
    ws.append(encabezados)
    datos = [
        ("TC-TGN-001",  "Agregar tipo nuevo",               "agregar", "tipo",   "Ensayo",      "",        "",               "exito"),
        ("TC-TGN-001B", "Agregar tipo Manuscrito",          "agregar", "tipo",   "Manuscrito",  "",        "",               "exito"),
        ("TC-TGN-001C", "Agregar género Terror",            "agregar", "genero", "Terror",      "",        "",               "exito"),
        ("TC-TGN-001D", "Agregar género Poesía",            "agregar", "genero", "Poesía",      "",        "",               "exito"),
        ("TC-TGN-002",  "Tipo con nombre vacío",            "agregar", "tipo",   "",            "",        "",               "error"),
        ("TC-TGN-003",  "Duplicado case-insensitive",       "agregar", "tipo",   "Ensayo",      "ENSAYO",  "",               "error"),
        ("TC-TGN-004",  "Editar tipo existente",            "editar",  "tipo",   "",            "",        "Ensayo Literario","exito"),
        ("TC-TGN-005",  "Eliminar tipo con confirmación",   "eliminar","tipo",   "",            "",        "",               "exito"),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        color = VERDE_CLARO if fila[7] == "exito" else ROJO_CLARO
        estilo_fila(ws, i, color)
    estilo_encabezado(ws)
    autoajustar_columnas(ws)

# ═══════════════════════════════════════════════════════════════════
#  HOJA: Dashboard
# ═══════════════════════════════════════════════════════════════════
def hoja_dashboard(wb):
    ws = wb.create_sheet("Dashboard")
    encabezados = ["id_caso", "descripcion", "filtro", "resultado_esperado"]
    ws.append(encabezados)
    datos = [
        ("TC-DSH-001", "Filtrar por tipo de material",       "tipo",   "exito"),
        ("TC-DSH-002", "Filtrar por género",                 "genero", "exito"),
        ("TC-DSH-003", "Filtrar por autor",                  "autor",  "exito"),
        ("TC-DSH-004", "Filtrar por año de publicación",     "año",    "exito"),
        ("TC-DSH-005", "Sin filtro seleccionado → error",    "",       "error"),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        color = VERDE_CLARO if fila[3] == "exito" else ROJO_CLARO
        estilo_fila(ws, i, color)
    estilo_encabezado(ws)
    autoajustar_columnas(ws)

# ═══════════════════════════════════════════════════════════════════
#  HOJA: Usuarios
# ═══════════════════════════════════════════════════════════════════
def hoja_usuarios(wb):
    ws = wb.create_sheet("Usuarios")
    encabezados = [
        "id_caso", "descripcion", "accion", "nombre_usuario",
        "nombre_nuevo", "apellido_nuevo", "cc_nuevo",
        "rol_nuevo", "resultado_esperado"
    ]
    ws.append(encabezados)
    datos = [
        ("TC-USR-001", "Ver lista de usuarios (admin)",     "ver",      "",           "",       "",        "",         "",             "exito"),
        ("TC-USR-005", "Editar rol a bibliotecario",        "editar",   "primer usuario", "",  "",        "",         "bibliotecario","exito"),
        ("TC-USR-005B","Editar rol a lector",               "editar",   "primer usuario", "",  "",        "",         "lector",       "exito"),
        ("TC-USR-008", "Eliminar usuario (verifica modal)", "eliminar", "último usuario", "",  "",        "",         "",             "modal"),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        estilo_fila(ws, i, VERDE_CLARO)
    estilo_encabezado(ws)
    autoajustar_columnas(ws)

# ═══════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════
def main():
    wb = Workbook()
    wb.remove(wb.active)          # elimina la hoja vacía por defecto

    hoja_login(wb)
    hoja_registro(wb)
    hoja_catalogo(wb)
    hoja_tipos_generos(wb)
    hoja_dashboard(wb)
    hoja_usuarios(wb)

    wb.save(OUTPUT)
    print(f"[OK] Archivo generado: {OUTPUT}")
    print(f"     Hojas: {wb.sheetnames}")

if __name__ == "__main__":
    main()
