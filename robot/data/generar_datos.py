"""
generar_datos.py — Genera datos_prueba.xlsx para Biblioteca Pro QA.

Estrategia anti-contaminación:
  - Un único TS (Unix timestamp) se calcula al inicio y se reutiliza en
    TODAS las hojas, garantizando coherencia entre referencias cruzadas.
  - Todo dato creado en el ambiente lleva prefijo QA_AUTO y el TS, de modo
    que cada ejecución del script produce datos únicos y trazables.
  - Las hojas clasifican cada caso con tipo_prueba y documentan precondicion,
    eliminando la dependencia implícita de ejecuciones anteriores.
  - Los emails de validación (casos error) también son únicos por TS para
    evitar colisiones si el ambiente ya los registró en una corrida anterior.

Leyenda de colores:
  Azul   = smoke        (lectura, sin modificar datos)
  Verde  = regresion    (flujos completos, puede leer datos existentes)
  Naranja= destructivo  (CRUD real: crea, edita o elimina datos)
  Amarillo= validacion  (verifica mensajes de error, no toca la BD)
  Rojo   = caso con resultado_esperado=error (overrides los anteriores)

Ejecutar: python data/generar_datos.py
"""
import os
import time
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

OUTPUT = os.path.join(os.path.dirname(__file__), "datos_prueba.xlsx")

# ── Timestamp único para TODA esta generación ─────────────────────────────────
TS = str(int(time.time()))

# ── Paleta ────────────────────────────────────────────────────────────────────
VERDE_OSCURO  = "1B5E20"
AZUL_CLARO    = "BBDEFB"   # smoke
VERDE_CLARO   = "C8E6C9"   # regresion
NARANJA_CLARO = "FFE0B2"   # destructivo
AMARILLO      = "FFF9C4"   # validacion
ROJO_CLARO    = "FFCDD2"   # error esperado
GRIS_CLARO    = "F5F5F5"   # precondiciones

COLOR_TIPO = {
    "smoke":       AZUL_CLARO,
    "regresion":   VERDE_CLARO,
    "destructivo": NARANJA_CLARO,
    "validacion":  AMARILLO,
}


# ── Helpers de estilo ─────────────────────────────────────────────────────────

def estilo_encabezado(ws, fila=1):
    for cell in ws[fila]:
        cell.font      = Font(bold=True, color="FFFFFF", size=10)
        cell.fill      = PatternFill("solid", fgColor=VERDE_OSCURO)
        cell.alignment = Alignment(horizontal="center", vertical="center",
                                   wrap_text=True)
        b = Side(style="thin", color="000000")
        cell.border = Border(left=b, right=b, top=b, bottom=b)
    ws.row_dimensions[fila].height = 22


def estilo_fila(ws, fila, color=GRIS_CLARO):
    for cell in ws[fila]:
        cell.fill      = PatternFill("solid", fgColor=color)
        cell.alignment = Alignment(vertical="center", wrap_text=True)
        b = Side(style="thin", color="CCCCCC")
        cell.border = Border(left=b, right=b, top=b, bottom=b)
    ws.row_dimensions[fila].height = 18


def autoajustar_columnas(ws):
    for col in ws.columns:
        max_len = max((len(str(c.value)) if c.value else 0) for c in col)
        ws.column_dimensions[get_column_letter(col[0].column)].width = min(
            max_len + 4, 55)


def color_fila(tipo_prueba: str, resultado_esperado: str) -> str:
    """Rojo si el resultado esperado es error; si no, color por tipo de prueba."""
    if resultado_esperado == "error":
        return ROJO_CLARO
    return COLOR_TIPO.get(tipo_prueba, GRIS_CLARO)


# ═══════════════════════════════════════════════════════════════════
#  HOJA: Login
# ═══════════════════════════════════════════════════════════════════
def hoja_login(wb):
    ws = wb.create_sheet("Login")
    ws.append([
        "id_caso", "descripcion", "email", "password",
        "resultado_esperado", "mensaje_esperado", "texto_esperado_panel",
        "tipo_prueba", "precondicion",
    ])
    datos = [
        # ── Caminos felices (smoke) ───────────────────────────────────────
        ("TC-LGN-001", "Login válido — admin",
         "migueltroll789@gmail.com", "123456",
         "exito", "", "Panel",
         "smoke", "Usuario admin existe permanentemente en el ambiente"),

        ("TC-LGN-002", "Login válido — lector con cuenta existente",
         "lector@biblioteca.com", "lector123",
         "exito", "", "Catálogo",
         "smoke", "lector@biblioteca.com debe existir con rol lector"),

        # ── Flujos alternativos (validacion — sin tocar BD) ───────────────
        ("TC-LGN-004", "Error — contraseña incorrecta",
         "migueltroll789@gmail.com", "WRONG_PASS_QA",
         "error", "Credenciales incorrectas", "",
         "validacion", "Ninguna — el usuario existe, la contraseña es incorrecta"),

        ("TC-LGN-005", "Error — email inexistente",
         f"qa_noexiste_{TS}@falso.test", "cualquier123",
         "error", "Credenciales incorrectas", "",
         "validacion", f"Ninguna — qa_noexiste_{TS}@falso.test nunca debe existir"),

        ("TC-LGN-006", "Error — email malformado (validación en cliente)",
         "no_es_un_email", "123456",
         "error", "", "",
         "validacion", "Ninguna — el cliente rechaza el formato antes del submit"),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        estilo_fila(ws, i, color_fila(fila[7], fila[4]))
    estilo_encabezado(ws)
    autoajustar_columnas(ws)


# ═══════════════════════════════════════════════════════════════════
#  HOJA: Registro
# ═══════════════════════════════════════════════════════════════════
def hoja_registro(wb):
    ws = wb.create_sheet("Registro")
    ws.append([
        "id_caso", "descripcion", "nombre", "apellido",
        "cedula", "email", "password",
        "resultado_esperado", "mensaje_error",
        "tipo_prueba", "precondicion",
    ])
    # Cédula numérica única: últimos 8 dígitos del timestamp
    cedula_qa = TS[-8:]
    datos = [
        # ── Creación real (destructivo) ───────────────────────────────────
        ("TC-REG-001", "Registro válido — usuario QA único por timestamp",
         "QAuto", "QPrueba", cedula_qa,
         f"qa_auto_reg_{TS}@qa.test", "QApass123",
         "exito", "",
         "destructivo",
         f"Email qa_auto_reg_{TS}@qa.test es único por TS; cédula {cedula_qa} no debe existir"),

        # ── Validaciones (no alcanzan la BD) ─────────────────────────────
        ("TC-REG-002", "Validación — campo nombre vacío",
         "", "QPrueba", "12345678",
         f"qa_val_{TS}_2@qa.test", "QApass123",
         "error", "obligatorio",
         "validacion", "Ninguna — falla en formulario antes del submit"),

        ("TC-REG-003", "Validación — cédula con letras (HU-001 paso 9)",
         "QAAna", "QGomez", "ABC12345",
         f"qa_val_{TS}_3@qa.test", "QApass123",
         "error", "solo debe contener números",
         "validacion", "Ninguna — falla en campo cédula"),

        ("TC-REG-004", "Validación — contraseña menor a 6 caracteres (HU-001 paso 10)",
         "QAPedro", "QLopez", "98765432",
         f"qa_val_{TS}_4@qa.test", "123",
         "error", "Mínimo 6",
         "validacion", "Ninguna — falla en campo contraseña"),

        ("TC-REG-005", "Validación — correo ya registrado (HU-001 paso 11)",
         "QAMiguel", "QAdmin", "11111111",
         "migueltroll789@gmail.com", "QApass123",
         "error", "ya está registrado",
         "validacion", "Email migueltroll789@gmail.com debe existir (admin permanente)"),

        ("TC-REG-006", "Validación — apellido vacío",
         "QALaura", "", "55667788",
         f"qa_val_{TS}_6@qa.test", "QApass123",
         "error", "obligatorio",
         "validacion", "Ninguna — falla en campo apellido"),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        estilo_fila(ws, i, color_fila(fila[9], fila[7]))
    estilo_encabezado(ws)
    autoajustar_columnas(ws)


# ═══════════════════════════════════════════════════════════════════
#  HOJA: Catalogo
# ═══════════════════════════════════════════════════════════════════
def hoja_catalogo(wb):
    ws = wb.create_sheet("Catalogo")
    ws.append([
        "id_caso", "descripcion", "accion",
        "titulo", "autor", "año", "tipo", "genero",
        "titulo_nuevo",
        "resultado_esperado", "mensaje_error", "termino_busqueda",
        "tipo_prueba", "precondicion",
    ])
    # Prefijos únicos por TS — ningún libro de ejecuciones anteriores coincide
    pfx = f"QA_AUTO_CAT_{TS}"
    datos = [
        # ── Búsqueda (regresion — depende de TC-CAT-004) ─────────────────
        ("TC-CAT-002", "Búsqueda en tiempo real — filtra por título QA", "buscar",
         "", "", "", "", "", "", "exito", "", pfx,
         "regresion",
         f"Ejecutar DESPUÉS de TC-CAT-004. El término '{pfx}' solo existe tras crear libros QA."),

        # ── Crear libros válidos (destructivo) ────────────────────────────
        ("TC-CAT-004", "Crear libro completo — Quijote QA con TS único", "crear",
         f"{pfx}_Quijote", "QA_Cervantes", "1605",
         "Libro", "Novela", "", "exito", "", "",
         "destructivo",
         "Los tipos 'Libro' y género 'Novela' deben existir en el catálogo del sistema"),

        ("TC-CAT-004B", "Crear revista técnica — IEEE QA con TS único", "crear",
         f"{pfx}_IEEE", "QA_IEEE", "2023",
         "Revista", "Tecnología", "", "exito", "", "",
         "destructivo",
         "Los tipos 'Revista' y género 'Tecnología' deben existir en el catálogo del sistema"),

        ("TC-CAT-004C", "Crear tesis — Optimización QA con TS único", "crear",
         f"{pfx}_Tesis", "QA_Carlos", "2022",
         "Tesis", "Ingeniería", "", "exito", "", "",
         "destructivo",
         "Los tipos 'Tesis' y género 'Ingeniería' deben existir en el catálogo del sistema"),

        # ── Crear libros inválidos (validacion) ───────────────────────────
        ("TC-CAT-005B", "Validación — título vacío en creación", "crear",
         "", "QA_Autor_Test", "2020", "Libro", "Terror",
         "", "error", "obligatorio", "",
         "validacion", "Ninguna — falla en validación del formulario"),

        ("TC-CAT-006", "Validación — año con letras (HU-007 paso 64)", "crear",
         f"{pfx}_AnoInv", "QA_Autor", "veinte", "Libro", "Terror",
         "", "error", "número entero positivo", "",
         "validacion", "Ninguna — falla en validación del campo año"),

        # ── Editar (destructivo) ──────────────────────────────────────────
        ("TC-CAT-008", "Editar título — renombrar primer libro de la lista", "editar",
         "", "", "", "", "",
         f"{pfx}_EditadoPro",
         "exito", "", "",
         "destructivo",
         f"Debe existir al menos un libro editable. Idealmente '{pfx}_Quijote' creado por TC-CAT-004."),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        estilo_fila(ws, i, color_fila(fila[12], fila[9]))
    estilo_encabezado(ws)
    autoajustar_columnas(ws)


# ═══════════════════════════════════════════════════════════════════
#  HOJA: TiposGeneros
# ═══════════════════════════════════════════════════════════════════
def hoja_tipos_generos(wb):
    ws = wb.create_sheet("TiposGeneros")
    ws.append([
        "id_caso", "descripcion", "accion", "categoria",
        "nombre", "nombre_duplicado", "nombre_nuevo",
        "resultado_esperado",
        "tipo_prueba", "precondicion",
    ])
    # Nombres con TS → únicos por ejecución.
    # TC-TGN-003 usa un par dedicado (QA_Dup_TS / QA_DUP_TS) distinto de TC-TGN-001
    # para evitar que TC-TGN-001 ya haya registrado el mismo nombre.
    datos = [
        ("TC-TGN-001", "Agregar tipo nuevo — nombre QA único por TS",
         "agregar", "tipo", f"QA_Tipo_{TS}", "", "", "exito",
         "destructivo", "Ninguna — el nombre es único por timestamp"),

        ("TC-TGN-001B", "Agregar tipo Manuscrito QA único por TS",
         "agregar", "tipo", f"QA_Manus_{TS}", "", "", "exito",
         "destructivo", "Ninguna — el nombre es único por timestamp"),

        ("TC-TGN-001C", "Agregar género Terror QA único por TS",
         "agregar", "genero", f"QA_Terror_{TS}", "", "", "exito",
         "destructivo", "Ninguna — el nombre es único por timestamp"),

        ("TC-TGN-001D", "Agregar género Poesía QA único por TS",
         "agregar", "genero", f"QA_Poesia_{TS}", "", "", "exito",
         "destructivo", "Ninguna — el nombre es único por timestamp"),

        ("TC-TGN-002", "Validación — campo nombre vacío",
         "agregar", "tipo", "", "", "", "error",
         "validacion", "Ninguna — falla en validación del formulario"),

        # Par exclusivo para test de duplicado; diferente prefijo que TC-TGN-001
        ("TC-TGN-003", "Validación — duplicado case-insensitive",
         "agregar", "tipo",
         f"QA_Dup_{TS}", f"QA_DUP_{TS}", "", "error",
         "validacion",
         f"El test crea QA_Dup_{TS} y luego intenta QA_DUP_{TS}. "
         f"Distinto de TC-TGN-001 (QA_Tipo_{TS}) para evitar conflicto."),

        ("TC-TGN-004", "Editar tipo — renombrar primer tipo de la lista",
         "editar", "tipo", "", "", f"QA_TipoEdit_{TS}", "exito",
         "destructivo",
         f"Debe existir al menos un tipo. Idealmente QA_Tipo_{TS} creado por TC-TGN-001."),

        ("TC-TGN-005", "Eliminar tipo — primer ítem con confirmación modal",
         "eliminar", "tipo", "", "", "", "exito",
         "destructivo",
         "Debe existir al menos un tipo. El primer tipo visible será eliminado con confirmación."),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        estilo_fila(ws, i, color_fila(fila[8], fila[7]))
    estilo_encabezado(ws)
    autoajustar_columnas(ws)


# ═══════════════════════════════════════════════════════════════════
#  HOJA: Dashboard
# ═══════════════════════════════════════════════════════════════════
def hoja_dashboard(wb):
    ws = wb.create_sheet("Dashboard")
    ws.append([
        "id_caso", "descripcion", "filtro", "resultado_esperado",
        "tipo_prueba", "precondicion",
    ])
    datos = [
        ("TC-DSH-001", "Filtrar por tipo de material", "tipo", "exito",
         "smoke",
         "Debe existir al menos un libro con tipo asignado. Correr 02_catalogo antes."),

        ("TC-DSH-002", "Filtrar por género", "genero", "exito",
         "smoke",
         "Debe existir al menos un libro con género asignado. Correr 02_catalogo antes."),

        ("TC-DSH-003", "Filtrar por autor", "autor", "exito",
         "smoke",
         "Debe existir al menos un libro con autor asignado. Correr 02_catalogo antes."),

        ("TC-DSH-004", "Filtrar por año de publicación", "año", "exito",
         "smoke",
         "Debe existir al menos un libro con año asignado. Correr 02_catalogo antes."),

        ("TC-DSH-005", "Error — generar sin filtro seleccionado", "", "error",
         "validacion",
         "Ninguna — el sistema debe rechazar la generación sin filtro"),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        estilo_fila(ws, i, color_fila(fila[4], fila[3]))
    estilo_encabezado(ws)
    autoajustar_columnas(ws)


# ═══════════════════════════════════════════════════════════════════
#  HOJA: Usuarios
# ═══════════════════════════════════════════════════════════════════
def hoja_usuarios(wb):
    ws = wb.create_sheet("Usuarios")
    ws.append([
        "id_caso", "descripcion", "accion", "nombre_usuario",
        "nombre_nuevo", "apellido_nuevo", "cc_nuevo",
        "rol_nuevo", "resultado_esperado",
        "tipo_prueba", "precondicion",
    ])
    datos = [
        ("TC-USR-001", "Ver lista de usuarios — admin autenticado",
         "ver", "", "", "", "", "", "exito",
         "smoke", "Usuario admin autenticado"),

        ("TC-USR-005", "Editar rol a bibliotecario — primer usuario de la lista",
         "editar", "primer_usuario", "", "", "", "bibliotecario", "exito",
         "destructivo",
         "Debe existir al menos un usuario no-admin. El orden puede variar; "
         "verificar que el primer usuario no sea el propio admin antes de correr."),

        ("TC-USR-005B", "Editar rol a lector — revierte TC-USR-005",
         "editar", "primer_usuario", "", "", "", "lector", "exito",
         "destructivo",
         "Depende de TC-USR-005. Revierte el rol del mismo primer usuario a lector."),

        ("TC-USR-008", "Eliminar usuario — verificar modal y CANCELAR",
         "eliminar", "ultimo_usuario", "", "", "", "", "modal",
         "smoke",
         "Debe existir al menos un usuario. "
         "El test abre el modal de confirmación pero CANCELA — no elimina datos."),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        estilo_fila(ws, i, color_fila(fila[9], fila[8]))
    estilo_encabezado(ws)
    autoajustar_columnas(ws)


# ═══════════════════════════════════════════════════════════════════
#  HOJA: Precondiciones  (referencia del equipo QA, no usada por tests)
# ═══════════════════════════════════════════════════════════════════
def hoja_precondiciones(wb):
    ws = wb.create_sheet("Precondiciones")
    ws.append(["suite", "nivel", "condicion", "como_satisfacer"])
    datos = [
        ("AMBIENTE",  "permanente",
         "Admin migueltroll789@gmail.com / 123456 existe",
         "Condición fija del ambiente compartido; no eliminar este usuario"),

        ("AMBIENTE",  "permanente",
         "Lector lector@biblioteca.com / lector123 existe",
         "Condición fija del ambiente compartido; no cambiar contraseña"),

        ("Registro",  "por-ejecucion",
         f"Email qa_auto_reg_{TS}@qa.test no debe existir",
         "Garantizado por el timestamp único; regenerar el Excel si es necesario"),

        ("Catalogo",  "destructivo",
         "Tipos 'Libro','Revista','Tesis' y géneros 'Novela','Tecnología','Ingeniería' existen",
         "Correr 03_tipos_generos.robot primero, o verificar en la app manualmente"),

        ("Catalogo",  "orden",
         "TC-CAT-002 (búsqueda) debe correr DESPUÉS de TC-CAT-004 (creación)",
         f"El término '{TS}' solo aparece tras crear libros QA en la misma ejecución"),

        ("TiposGeneros", "orden",
         "TC-TGN-004 (editar) y TC-TGN-005 (eliminar) dependen de TC-TGN-001 (crear)",
         "El primer tipo de la lista debe ser un ítem QA creado por TC-TGN-001"),

        ("Dashboard", "datos",
         "Al menos un libro con tipo, género, autor y año debe existir",
         "Correr 02_catalogo.robot antes para garantizar libros QA en el sistema"),

        ("Usuarios",  "destructivo",
         "TC-USR-005/005B edita el primer usuario visible (no determinista)",
         "Verificar que el primer usuario no sea el admin antes de ejecutar la suite"),

        ("Usuarios",  "smoke",
         "TC-USR-008 abre el modal de eliminación pero CANCELA — no borra datos",
         "No requiere precondición especial"),
    ]
    for i, fila in enumerate(datos, start=2):
        ws.append(fila)
        estilo_fila(ws, i, GRIS_CLARO)
    estilo_encabezado(ws)
    autoajustar_columnas(ws)


# ═══════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════
def main():
    wb = Workbook()
    wb.remove(wb.active)

    hoja_login(wb)
    hoja_registro(wb)
    hoja_catalogo(wb)
    hoja_tipos_generos(wb)
    hoja_dashboard(wb)
    hoja_usuarios(wb)
    hoja_precondiciones(wb)

    wb.save(OUTPUT)
    print(f"[OK] Archivo generado : {OUTPUT}")
    print(f"     Hojas            : {wb.sheetnames}")
    print(f"     Timestamp base   : {TS}")
    print(f"     Prefijo catálogo : QA_AUTO_CAT_{TS}")
    print(f"     Email registro   : qa_auto_reg_{TS}@qa.test")
    print(f"     Prefijo tipos    : QA_Tipo_{TS}")


if __name__ == "__main__":
    main()
