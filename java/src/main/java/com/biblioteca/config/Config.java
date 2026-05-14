package com.biblioteca.config;

/**
 * Constantes de configuración del proyecto.
 * Centraliza URL, credenciales y rutas de artefactos.
 */
public final class Config {

    private Config() {}

    public static final String BASE_URL =
        "https://biblioteca-front-end-1satou1s-projects.vercel.app";

    // Credenciales de admin (manual_usuario_v2 – Sección 3)
    public static final String ADMIN_EMAIL    = "migueltroll789@gmail.com";
    public static final String ADMIN_PASSWORD = "123456";

    // Timeouts (segundos)
    public static final int TIMEOUT_IMPLICIT  = 0;
    public static final int TIMEOUT_EXPLICIT  = 25;
    public static final int TIMEOUT_PAGE_LOAD = 30;

    // Rutas de artefactos (relativas al directorio de ejecución Maven)
    public static final String EXCEL_PATH    = "src/test/resources/datos_prueba.xlsx";
    public static final String SCREENSHOTS   = "target/screenshots";
    public static final String VIDEOS        = "target/videos";
    public static final String REPORTS       = "target/extent-reports";
}
