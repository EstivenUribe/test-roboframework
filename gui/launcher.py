"""
launcher.py — GUI para Biblioteca Pro Test Suite
Politécnico Colombiano Jaime Isaza Cadavid
Facultad de Ingeniería · Pruebas y Gestión de la Configuración
"""
import os
import sys
import shutil
import threading
import subprocess
import time
import glob
import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
from pathlib import Path

try:
    from PIL import Image, ImageTk
    PIL_OK = True
except ImportError:
    PIL_OK = False

# ── Rutas base ───────────────────────────────────────────────────────────────
BASE    = Path(__file__).resolve().parent.parent
GUI_DIR = Path(__file__).resolve().parent
ROBOT   = BASE / "robot"
JAVA    = BASE / "java"
SS_RF   = ROBOT / "results" / "screenshots"
SS_JAV  = JAVA  / "target"  / "screenshots"
REP_RF  = ROBOT / "results" / "logs" / "report.html"
REP_JAV = JAVA  / "target"  / "extent-reports"
LOGO_PATH = GUI_DIR / "logo.png"

MAVEN_FALLBACK = Path(r"C:\maven\apache-maven-3.9.6\bin\mvn.cmd")

# ── Paleta de colores ─────────────────────────────────────────────────────────
C_BG       = "#1e1e2e"
C_PANEL    = "#2a2a3e"
C_HEADER   = "#0d3320"        # verde oscuro institucional
C_HEADER2  = "#1a4a2e"
C_ACCENT   = "#27ae60"
C_BTN_RF   = "#27ae60"
C_BTN_RF2  = "#1e8449"
C_BTN_JAV  = "#2980b9"
C_BTN_JAV2 = "#1a5276"
C_BTN_STP  = "#c0392b"
C_BTN_STP2 = "#96281b"
C_BTN_QRF  = "#d35400"   # naranja rápido RF
C_BTN_QRF2 = "#a84300"
C_BTN_QJV  = "#8e44ad"   # morado rápido Java
C_BTN_QJV2 = "#6c3483"
C_FG       = "#ecf0f1"
C_MUTED    = "#95a5a6"
C_GOLD     = "#f1c40f"
C_PASS     = "#2ecc71"
C_FAIL     = "#e74c3c"
C_WARN     = "#f39c12"
C_INFO     = "#3498db"
C_CONSOLE  = "#0d0d1a"

FONT_TITLE  = ("Segoe UI", 14, "bold")
FONT_HDR    = ("Segoe UI", 11, "bold")
FONT_HDR_SM = ("Segoe UI", 9)
FONT_BTN    = ("Segoe UI", 10, "bold")
FONT_MONO   = ("Consolas", 9)
FONT_SMALL  = ("Segoe UI", 8)
FONT_TINY   = ("Segoe UI", 7)

# ── Datos institucionales ─────────────────────────────────────────────────────
ASIGNATURA = "Pruebas y Gestión de la Configuración"
DOCENTE    = "David Mejia Tabares"
GRUPO      = "Grupo N.° 1"
INTEGRANTES = [
    ("Jeffrey Guerrero",  "jguerreromira"),
    ("Jhoan Londoño",     "jhoan636"),
    ("Estiven Uribe",     "EstivenUribe"),
]


def _find_mvn() -> str:
    mvn = shutil.which("mvn")
    if mvn:
        return mvn
    for candidate in [
        MAVEN_FALLBACK,
        Path(r"C:\maven\bin\mvn.cmd"),
        Path(r"C:\Program Files\Maven\bin\mvn.cmd"),
    ]:
        if candidate.exists():
            return str(candidate)
    return "mvn"


def _find_python() -> str:
    for name in ("python", "python3"):
        p = shutil.which(name)
        if p:
            return p
    return "python"


class App(tk.Tk):

    def __init__(self):
        super().__init__()
        self.title("Biblioteca Pro — Test Launcher · Politécnico Colombiano")
        self.configure(bg=C_BG)
        self.resizable(True, True)
        self.minsize(960, 640)

        self._proc: subprocess.Popen | None = None
        self._running    = False
        self._cur_mode   = "rf"
        self._ss_images: list = []
        self._ss_index  = 0
        self._ss_paths  : list[str] = []
        self._ss_source = "rf"

        self._build_ui()
        self.geometry("1280x780")
        self.after(500, self._poll_screenshots)

    # ── UI principal ──────────────────────────────────────────────────────────

    def _build_ui(self):
        self._build_header()

        ttk.Separator(self, orient="horizontal").pack(fill="x")

        main = tk.Frame(self, bg=C_BG)
        main.pack(fill="both", expand=True, padx=8, pady=8)

        left = tk.Frame(main, bg=C_PANEL, width=390,
                        highlightbackground="#3a3a5e", highlightthickness=1)
        left.pack(side="left", fill="y", padx=(0, 6))
        left.pack_propagate(False)

        right = tk.Frame(main, bg=C_PANEL,
                         highlightbackground="#3a3a5e", highlightthickness=1)
        right.pack(side="left", fill="both", expand=True)

        self._build_left(left)
        self._build_right(right)

    # ── Header institucional ──────────────────────────────────────────────────

    def _build_header(self):
        header = tk.Frame(self, bg=C_HEADER, height=90)
        header.pack(fill="x")
        header.pack_propagate(False)

        # ─ Lado izquierdo: logo ───────────────────────────────────────────────
        logo_frame = tk.Frame(header, bg=C_HEADER)
        logo_frame.pack(side="left", padx=(16, 8), pady=8)

        logo_loaded = False
        if PIL_OK and LOGO_PATH.exists():
            try:
                img = Image.open(LOGO_PATH)
                img.thumbnail((220, 74), Image.LANCZOS)
                self._logo_img = ImageTk.PhotoImage(img)
                tk.Label(logo_frame, image=self._logo_img,
                         bg=C_HEADER).pack()
                logo_loaded = True
            except Exception:
                pass

        if not logo_loaded:
            # Fallback de texto con escudo en ASCII
            tk.Label(logo_frame,
                     text="POLITÉCNICO COLOMBIANO",
                     bg=C_HEADER, fg="#f1c40f",
                     font=("Segoe UI", 11, "bold")).pack(anchor="w")
            tk.Label(logo_frame,
                     text="Jaime Isaza Cadavid",
                     bg=C_HEADER, fg=C_FG,
                     font=("Segoe UI", 9)).pack(anchor="w")
            tk.Label(logo_frame,
                     text="Facultad de Ingeniería",
                     bg=C_HEADER, fg="#a8d8a8",
                     font=("Segoe UI", 9, "italic")).pack(anchor="w", pady=(4, 0))

        # Separador vertical
        tk.Frame(header, bg="#2d6a40", width=1).pack(
            side="left", fill="y", pady=12, padx=8)

        # ─ Centro: nombre del proyecto ────────────────────────────────────────
        center = tk.Frame(header, bg=C_HEADER)
        center.pack(side="left", fill="both", expand=True, padx=8)

        tk.Label(center, text="Biblioteca Pro",
                 bg=C_HEADER, fg=C_GOLD,
                 font=("Segoe UI", 15, "bold")).pack(anchor="w")
        tk.Label(center, text="Suite de Automatización de Pruebas",
                 bg=C_HEADER, fg=C_FG,
                 font=("Segoe UI", 10)).pack(anchor="w")

        tags_frame = tk.Frame(center, bg=C_HEADER)
        tags_frame.pack(anchor="w", pady=(6, 0))
        self._tag(tags_frame, "Robot Framework", "#27ae60")
        self._tag(tags_frame, "Java / Selenium", "#2980b9")
        self._tag(tags_frame, "Data-Driven", "#8e44ad")
        self._tag(tags_frame, "Excel", "#d35400")

        # Separador vertical
        tk.Frame(header, bg="#2d6a40", width=1).pack(
            side="left", fill="y", pady=12, padx=8)

        # ─ Lado derecho: info académica ───────────────────────────────────────
        right = tk.Frame(header, bg=C_HEADER)
        right.pack(side="right", padx=(8, 16), pady=8, fill="y")

        # Asignatura y docente
        info_top = tk.Frame(right, bg=C_HEADER)
        info_top.pack(anchor="e")

        tk.Label(info_top, text=ASIGNATURA,
                 bg=C_HEADER, fg=C_GOLD,
                 font=("Segoe UI", 9, "bold")).pack(anchor="e")
        tk.Label(info_top, text=f"Docente: {DOCENTE}",
                 bg=C_HEADER, fg="#a8d8a8",
                 font=("Segoe UI", 8, "italic")).pack(anchor="e")

        # Separador
        tk.Frame(right, bg="#2d6a40", height=1).pack(fill="x", pady=4)

        # Grupo e integrantes
        tk.Label(right, text=GRUPO,
                 bg=C_HEADER, fg=C_FG,
                 font=("Segoe UI", 8, "bold")).pack(anchor="e")

        for nombre, gh in INTEGRANTES:
            row = tk.Frame(right, bg=C_HEADER)
            row.pack(anchor="e")
            tk.Label(row, text="• " + nombre,
                     bg=C_HEADER, fg=C_FG,
                     font=("Segoe UI", 8)).pack(side="left")
            tk.Label(row, text=f"  @{gh}",
                     bg=C_HEADER, fg=C_MUTED,
                     font=("Segoe UI", 7, "italic")).pack(side="left")

    @staticmethod
    def _tag(parent: tk.Frame, text: str, color: str):
        tk.Label(parent, text=f" {text} ",
                 bg=color, fg="white",
                 font=("Segoe UI", 7, "bold"),
                 relief="flat", padx=4, pady=2).pack(side="left", padx=2)

    # ── Panel izquierdo ───────────────────────────────────────────────────────

    def _build_left(self, parent):
        tk.Label(parent, text="🔬  Control de Ejecución",
                 bg=C_PANEL, fg=C_FG, font=FONT_TITLE,
                 pady=10).pack(fill="x", padx=12)

        ttk.Separator(parent).pack(fill="x", padx=12)

        # ── Sección: ejecución completa ───────────────────────────────────────
        tk.Label(parent, text="Suite completa (browser visible)",
                 bg=C_PANEL, fg=C_MUTED, font=FONT_SMALL,
                 anchor="w", pady=4).pack(fill="x", padx=14)

        btn_frame = tk.Frame(parent, bg=C_PANEL)
        btn_frame.pack(fill="x", padx=12, pady=(0, 4))

        self.btn_rf = self._make_btn(
            btn_frame, "▶   Robot Framework",
            C_BTN_RF, C_BTN_RF2, lambda: self._run("rf"))
        self.btn_rf.pack(fill="x", pady=(0, 6))

        self.btn_jav = self._make_btn(
            btn_frame, "▶   Java / Maven",
            C_BTN_JAV, C_BTN_JAV2, lambda: self._run("java"))
        self.btn_jav.pack(fill="x")

        ttk.Separator(parent).pack(fill="x", padx=12, pady=(10, 0))

        # ── Sección: ejecución rápida ─────────────────────────────────────────
        hdr_q = tk.Frame(parent, bg=C_PANEL)
        hdr_q.pack(fill="x", padx=14, pady=(4, 2))
        tk.Label(hdr_q, text="⚡  Ejecución Rápida",
                 bg=C_PANEL, fg="#f39c12", font=("Segoe UI", 9, "bold")
                 ).pack(side="left")
        tk.Label(hdr_q, text=" headless · sin ventana",
                 bg=C_PANEL, fg=C_MUTED, font=FONT_TINY
                 ).pack(side="left", pady=1)

        btn_q = tk.Frame(parent, bg=C_PANEL)
        btn_q.pack(fill="x", padx=12, pady=(0, 4))

        self.btn_rf_quick = self._make_btn(
            btn_q, "⚡  Robot · Smoke  (7 tests)",
            C_BTN_QRF, C_BTN_QRF2, lambda: self._run("rf_quick"))
        self.btn_rf_quick.pack(fill="x", pady=(0, 6))
        tk.Label(btn_q, text="   headless · solo smoke · loglevel WARN",
                 bg=C_PANEL, fg=C_MUTED, font=FONT_TINY, anchor="w"
                 ).pack(fill="x", pady=(0, 4))

        self.btn_jav_quick = self._make_btn(
            btn_q, "⚡  Java · Headless  (36 tests)",
            C_BTN_QJV, C_BTN_QJV2, lambda: self._run("java_quick"))
        self.btn_jav_quick.pack(fill="x")
        tk.Label(btn_q, text="   headless · suite completa",
                 bg=C_PANEL, fg=C_MUTED, font=FONT_TINY, anchor="w"
                 ).pack(fill="x", pady=(0, 2))

        ttk.Separator(parent).pack(fill="x", padx=12, pady=(6, 0))

        stop_frame = tk.Frame(parent, bg=C_PANEL)
        stop_frame.pack(fill="x", padx=12, pady=(6, 4))

        self.btn_stop = self._make_btn(
            stop_frame, "⏹   Detener",
            C_BTN_STP, C_BTN_STP2, self._stop)
        self.btn_stop.pack(fill="x")
        self.btn_stop.config(state="disabled")

        # Estado + progreso
        self.lbl_status = tk.Label(
            parent, text="Listo para ejecutar",
            bg=C_PANEL, fg=C_MUTED, font=FONT_SMALL)
        self.lbl_status.pack(fill="x", padx=12, pady=(8, 2))

        self.progress = ttk.Progressbar(parent, mode="indeterminate")
        self.progress.pack(fill="x", padx=12, pady=(0, 8))

        ttk.Separator(parent).pack(fill="x", padx=12)

        tk.Label(parent, text="Consola de ejecución",
                 bg=C_PANEL, fg=C_MUTED, font=FONT_SMALL,
                 anchor="w", pady=4).pack(fill="x", padx=12)

        self.console = scrolledtext.ScrolledText(
            parent, bg=C_CONSOLE, fg=C_FG, font=FONT_MONO,
            wrap="word", insertbackground=C_FG,
            state="disabled", relief="flat", bd=0)
        self.console.pack(fill="both", expand=True, padx=6)

        self.console.tag_config("info",  foreground=C_INFO)
        self.console.tag_config("ok",    foreground=C_PASS)
        self.console.tag_config("error", foreground=C_FAIL)
        self.console.tag_config("warn",  foreground=C_WARN)
        self.console.tag_config("plain", foreground=C_FG)
        self.console.tag_config("dim",   foreground=C_MUTED)

        tk.Button(parent, text="Limpiar consola",
                  bg=C_PANEL, fg=C_MUTED, font=FONT_TINY,
                  relief="flat", bd=0, cursor="hand2",
                  activeforeground=C_FG, activebackground=C_PANEL,
                  command=self._clear_console
                  ).pack(anchor="e", padx=12, pady=(2, 8))

    # ── Panel derecho ─────────────────────────────────────────────────────────

    def _build_right(self, parent):
        toolbar = tk.Frame(parent, bg=C_PANEL)
        toolbar.pack(fill="x", padx=8, pady=(8, 4))

        tk.Label(toolbar, text="Panel de resultados",
                 bg=C_PANEL, fg=C_FG,
                 font=("Segoe UI", 11, "bold")).pack(side="left", padx=4)

        src_frame = tk.Frame(toolbar, bg=C_PANEL)
        src_frame.pack(side="left", padx=16)
        tk.Label(src_frame, text="Fuente:",
                 bg=C_PANEL, fg=C_MUTED, font=FONT_SMALL).pack(side="left")
        self.var_src = tk.StringVar(value="rf")
        for val, txt in (("rf", "Robot FW"), ("java", "Java")):
            tk.Radiobutton(src_frame, text=txt, variable=self.var_src,
                           value=val, bg=C_PANEL, fg=C_FG,
                           selectcolor=C_BG, activebackground=C_PANEL,
                           font=FONT_SMALL,
                           command=self._change_source
                           ).pack(side="left", padx=2)

        self._make_small_btn(toolbar, "📊 Abrir Reporte",
                              self._open_report).pack(side="right", padx=4)
        self.lbl_ss_count = tk.Label(
            toolbar, text="0 / 0", bg=C_PANEL, fg=C_MUTED, font=FONT_SMALL)
        self.lbl_ss_count.pack(side="right", padx=4)
        self._make_small_btn(toolbar, "▶", self._next_ss).pack(side="right", padx=2)
        self._make_small_btn(toolbar, "◀", self._prev_ss).pack(side="right", padx=2)

        # Notebook
        style = ttk.Style()
        style.theme_use("clam")
        style.configure("TNotebook",     background=C_PANEL, borderwidth=0)
        style.configure("TNotebook.Tab", background=C_BG, foreground=C_FG,
                        padding=[10, 4])
        style.map("TNotebook.Tab",
                  background=[("selected", C_PANEL)],
                  foreground=[("selected", C_PASS)])

        nb = ttk.Notebook(parent)
        nb.pack(fill="both", expand=True, padx=8, pady=(0, 8))

        tab_ss  = tk.Frame(nb, bg=C_BG)
        tab_res = tk.Frame(nb, bg=C_BG)
        nb.add(tab_ss,  text="📸  Capturas en tiempo real")
        nb.add(tab_res, text="📋  Resultados")

        self._build_tab_screenshots(tab_ss)
        self._build_tab_results(tab_res)

    def _build_tab_screenshots(self, parent):
        self.ss_label = tk.Label(
            parent, bg=C_BG,
            text="Las capturas aparecerán aquí durante la ejecución",
            fg=C_MUTED, font=("Segoe UI", 11))
        self.ss_label.pack(fill="both", expand=True)
        self.ss_name = tk.Label(parent, bg=C_BG, fg=C_MUTED, font=FONT_SMALL)
        self.ss_name.pack(fill="x", padx=8, pady=4)

    def _build_tab_results(self, parent):
        cols = ("test", "estado", "hora")
        self.tree = ttk.Treeview(parent, columns=cols, show="headings")

        ts = ttk.Style()
        ts.configure("Treeview",
                     background=C_BG, foreground=C_FG,
                     fieldbackground=C_BG, rowheight=26)
        ts.configure("Treeview.Heading",
                     background=C_PANEL, foreground=C_FG, relief="flat")
        ts.map("Treeview", background=[("selected", "#3a3a5e")])

        self.tree.heading("test",   text="Caso de prueba")
        self.tree.heading("estado", text="Estado")
        self.tree.heading("hora",   text="Hora")
        self.tree.column("test",   width=440, anchor="w")
        self.tree.column("estado", width=90,  anchor="center")
        self.tree.column("hora",   width=80,  anchor="center")
        self.tree.tag_configure("PASS", foreground=C_PASS)
        self.tree.tag_configure("FAIL", foreground=C_FAIL)
        self.tree.tag_configure("WARN", foreground=C_WARN)

        vsb = ttk.Scrollbar(parent, orient="vertical",
                             command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        vsb.pack(side="right", fill="y")
        self.tree.pack(fill="both", expand=True, padx=(8, 0), pady=8)

        tk.Button(parent, text="Limpiar resultados",
                  bg=C_PANEL, fg=C_MUTED, font=FONT_TINY,
                  relief="flat", cursor="hand2",
                  activeforeground=C_FG, activebackground=C_PANEL,
                  command=lambda: self.tree.delete(*self.tree.get_children())
                  ).pack(anchor="e", padx=8, pady=(0, 8))

    # ── Helpers de widgets ────────────────────────────────────────────────────

    @staticmethod
    def _make_btn(parent, text, bg, active_bg, cmd) -> tk.Button:
        return tk.Button(parent, text=text, bg=bg, fg="white",
                         activebackground=active_bg, activeforeground="white",
                         font=FONT_BTN, relief="flat", bd=0,
                         cursor="hand2", pady=9, command=cmd)

    @staticmethod
    def _make_small_btn(parent, text, cmd) -> tk.Button:
        return tk.Button(parent, text=text, bg=C_BG, fg=C_FG,
                         activebackground="#3a3a5e", activeforeground=C_FG,
                         font=FONT_SMALL, relief="flat", bd=0,
                         cursor="hand2", padx=6, pady=3, command=cmd)

    # ── Ejecución ─────────────────────────────────────────────────────────────

    # Maps mode → (ss_source, display label)
    _MODE_META = {
        "rf":        ("rf",   "Robot Framework (completo)"),
        "java":      ("java", "Java / Maven (completo)"),
        "rf_quick":  ("rf",   "⚡ Robot · Smoke headless"),
        "java_quick":("java", "⚡ Java · Headless"),
    }

    def _all_run_buttons(self):
        return [self.btn_rf, self.btn_jav, self.btn_rf_quick, self.btn_jav_quick]

    def _run(self, mode: str):
        if self._running:
            return
        self._running   = True
        self._cur_mode  = mode
        src, label      = self._MODE_META[mode]
        self._ss_source = src
        self.var_src.set(src)
        self._ss_paths.clear()
        self._ss_index = 0

        for b in self._all_run_buttons():
            b.config(state="disabled")
        self.btn_stop.config(state="normal")
        self.progress.start(12)
        self.lbl_status.config(fg=C_INFO, text=f"Ejecutando {label}…")

        self._log("=" * 52, "dim")
        self._log(f"▶  {label}", "info")
        self._log("=" * 52, "dim")

        threading.Thread(target=self._worker, args=(mode,), daemon=True).start()

    def _worker(self, mode: str):
        try:
            builders = {
                "rf":         self._build_cmd_rf,
                "java":       self._build_cmd_java,
                "rf_quick":   self._build_cmd_rf_quick,
                "java_quick": self._build_cmd_java_quick,
            }
            cmd, cwd = builders[mode]()

            self._log(f"Dir : {cwd}", "dim")
            self._log(f"Cmd : {' '.join(str(c) for c in cmd)}\n", "dim")

            env = os.environ.copy()
            mvn_bin = str(MAVEN_FALLBACK.parent)
            if mvn_bin not in env.get("PATH", ""):
                env["PATH"] = mvn_bin + os.pathsep + env.get("PATH", "")

            self._proc = subprocess.Popen(
                cmd, cwd=str(cwd),
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, encoding="utf-8", errors="replace",
                env=env,
                creationflags=(subprocess.CREATE_NO_WINDOW
                               if sys.platform == "win32" else 0),
            )
            for line in self._proc.stdout:
                self._dispatch_line(line.rstrip())
            self._proc.wait()
            rc = self._proc.returncode
        except Exception as exc:
            self._log(f"[ERROR] {exc}", "error")
            rc = -1

        self.after(0, self._on_done, rc)

    def _build_cmd_rf(self):
        venv_robot = ROBOT / "venv" / "Scripts" / "robot.exe"
        robot_cmd  = str(venv_robot) if venv_robot.exists() else "robot"
        cmd = [
            robot_cmd,
            "--outputdir", str(ROBOT / "results" / "logs"),
            "--pythonpath", str(ROBOT / "resources"),
            "--log",    "log.html",
            "--report", "report.html",
            "--variable", "BROWSER:chrome",
            "--variable", "HEADLESS:false",
            "--variable", "RECORD_VIDEO:false",
            "--variable", f"SCREENSHOTS_DIR:{ROBOT / 'results' / 'screenshots'}",
            "--variable", f"VIDEOS_DIR:{ROBOT / 'results' / 'videos'}",
            "--loglevel", "INFO",
            "tests",
        ]
        return cmd, ROBOT

    def _build_cmd_java(self):
        mvn = _find_mvn()
        cmd = [mvn, "test",
               "-Dfile.encoding=UTF-8",
               "-Dsurefire.useFile=false"]
        return cmd, JAVA

    def _build_cmd_rf_quick(self):
        """Robot Framework: solo smoke, Chrome headless, log WARN (más rápido)."""
        venv_robot = ROBOT / "venv" / "Scripts" / "robot.exe"
        robot_cmd  = str(venv_robot) if venv_robot.exists() else "robot"
        cmd = [
            robot_cmd,
            "--outputdir", str(ROBOT / "results" / "logs"),
            "--pythonpath", str(ROBOT / "resources"),
            "--log",    "log.html",
            "--report", "report.html",
            "--variable", "BROWSER:chrome",
            "--variable", "HEADLESS:true",
            "--variable", "RECORD_VIDEO:false",
            "--variable", f"SCREENSHOTS_DIR:{ROBOT / 'results' / 'screenshots'}",
            "--variable", f"VIDEOS_DIR:{ROBOT / 'results' / 'videos'}",
            "--loglevel", "WARN",
            "--include",  "smoke",
            "tests",
        ]
        return cmd, ROBOT

    def _build_cmd_java_quick(self):
        """Java/Maven: suite completa en Chrome headless."""
        mvn = _find_mvn()
        cmd = [mvn, "test",
               "-Dfile.encoding=UTF-8",
               "-Dsurefire.useFile=false",
               "-Dheadless=true"]
        return cmd, JAVA

    def _dispatch_line(self, line: str):
        tag  = "plain"
        low  = line.lower()
        stat = None

        if any(k in line for k in ("| PASS |", "PASSED")):
            tag, stat = "ok", "PASS"
        elif "Tests run:" in line and "Failures: 0, Errors: 0" in line:
            tag, stat = "ok", "PASS"
        elif "Tests run:" in line:
            tag, stat = "warn", "WARN"
        elif any(k in line for k in ("| FAIL |", "FAILED",
                                      "BUILD FAILURE", "Exception")):
            tag, stat = "error", "FAIL"
        elif any(k in low for k in ("warn", "skip")):
            tag = "warn"
        elif any(k in low for k in ("[info]", "running", "ok", "pass",
                                     "ejecutando")):
            tag = "info"

        self.after(0, self._append_console, line, tag)
        if stat:
            ts = time.strftime("%H:%M:%S")
            self.after(0, self._insert_result, line.strip()[:90], stat, ts)

    def _on_done(self, rc: int):
        self._running = False
        self._proc    = None
        for b in self._all_run_buttons():
            b.config(state="normal")
        self.btn_stop.config(state="disabled")
        self.progress.stop()
        _, label = self._MODE_META.get(self._cur_mode, ("rf", self._cur_mode))
        if rc == 0:
            self.lbl_status.config(fg=C_PASS,
                                    text=f"✔  {label} — todos pasaron")
            self._log(f"\n✔  BUILD SUCCESS — {label}.", "ok")
        else:
            self.lbl_status.config(fg=C_FAIL,
                                    text=f"✖  {label} — errores (rc={rc})")
            self._log(f"\n✖  {label} finalizó con código {rc}. Revisa el reporte.", "error")

    # ── Consola ───────────────────────────────────────────────────────────────

    def _log(self, text: str, tag: str = "plain"):
        self.after(0, self._append_console, text, tag)

    def _append_console(self, text: str, tag: str):
        self.console.config(state="normal")
        self.console.insert("end", text + "\n", tag)
        self.console.see("end")
        self.console.config(state="disabled")

    def _clear_console(self):
        self.console.config(state="normal")
        self.console.delete("1.0", "end")
        self.console.config(state="disabled")

    # ── Tabla de resultados ───────────────────────────────────────────────────

    def _insert_result(self, test: str, status: str, ts: str):
        self.tree.insert("", "end",
                          values=(test, status, ts),
                          tags=(status,))

    # ── Capturas ──────────────────────────────────────────────────────────────

    def _change_source(self):
        self._ss_source = self.var_src.get()
        self._ss_paths.clear()
        self._ss_index = 0
        self._refresh_ss_list()

    def _poll_screenshots(self):
        old = len(self._ss_paths)
        self._refresh_ss_list()
        if self._ss_paths and len(self._ss_paths) != old:
            self._ss_index = len(self._ss_paths) - 1
            self._show_ss()
        self.after(1500, self._poll_screenshots)

    def _refresh_ss_list(self):
        folder = SS_RF if self._ss_source == "rf" else SS_JAV
        paths  = []
        for ext in ("*.png", "*.jpg", "*.jpeg"):
            paths.extend(glob.glob(str(folder / ext)))
        paths.sort(key=os.path.getmtime)
        self._ss_paths = paths
        total = len(paths)
        idx   = (self._ss_index + 1) if paths else 0
        self.lbl_ss_count.config(text=f"{idx} / {total}")

    def _show_ss(self):
        if not self._ss_paths:
            return
        idx  = max(0, min(self._ss_index, len(self._ss_paths) - 1))
        path = self._ss_paths[idx]
        name = os.path.basename(path)

        if PIL_OK:
            try:
                img    = Image.open(path)
                max_w  = max(self.ss_label.winfo_width(),  100)
                max_h  = max(self.ss_label.winfo_height(), 100)
                img.thumbnail((max_w, max_h), Image.LANCZOS)
                photo  = ImageTk.PhotoImage(img)
                self._ss_images = [photo]
                self.ss_label.config(image=photo, text="")
            except Exception:
                self.ss_label.config(image="",
                                      text=f"[No se pudo cargar: {name}]")
        else:
            self.ss_label.config(image="",
                                  text=f"📸 {name}\n(instala Pillow para previsualizar)")

        self.ss_name.config(text=f"  {name}  [{idx+1}/{len(self._ss_paths)}]")
        self.lbl_ss_count.config(text=f"{idx+1} / {len(self._ss_paths)}")

    def _prev_ss(self):
        if self._ss_paths:
            self._ss_index = (self._ss_index - 1) % len(self._ss_paths)
            self._show_ss()

    def _next_ss(self):
        if self._ss_paths:
            self._ss_index = (self._ss_index + 1) % len(self._ss_paths)
            self._show_ss()

    # ── Reporte ───────────────────────────────────────────────────────────────

    def _open_report(self):
        import webbrowser
        if self._ss_source == "rf":
            path = REP_RF
        else:
            htmls = sorted(REP_JAV.glob("*.html"),
                           key=os.path.getmtime, reverse=True)
            path  = htmls[0] if htmls else None

        if path and Path(path).exists():
            webbrowser.open(Path(path).as_uri())
        else:
            messagebox.showinfo("Reporte",
                                "No se encontró el reporte.\n"
                                "Ejecuta las pruebas primero.")

    # ── Detener ───────────────────────────────────────────────────────────────

    def _stop(self):
        if self._proc:
            try:
                if sys.platform == "win32":
                    subprocess.call(
                        ["taskkill", "/F", "/T", "/PID", str(self._proc.pid)],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                else:
                    self._proc.terminate()
            except Exception:
                pass
        self._log("\n⏹  Ejecución detenida por el usuario.", "warn")
        self.lbl_status.config(fg=C_WARN, text="⏹  Detenido por el usuario")
        self.progress.stop()
        for b in self._all_run_buttons():
            b.config(state="normal")
        self.btn_stop.config(state="disabled")
        self._running = False


if __name__ == "__main__":
    app = App()
    app.mainloop()
