package com.biblioteca.utils;

import com.biblioteca.config.Config;
import org.openqa.selenium.*;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Utilidad para tomar y guardar capturas de pantalla en tests Selenium.
 * Las imágenes se almacenan en target/screenshots/<testName>/<prefijo>_<ts>.png
 */
public class ScreenshotUtils {

    private final WebDriver driver;
    private final String testFolder;

    public ScreenshotUtils(WebDriver driver, String testName) {
        this.driver     = driver;
        this.testFolder = sanitize(testName);
    }

    /**
     * Guarda una captura de pantalla del navegador.
     *
     * @param prefix nombre descriptivo (ej. "before_login", "toast_error")
     * @return ruta absoluta al archivo guardado, o null si falla
     */
    public String take(String prefix) {
        try {
            String ts   = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HHmmss_SSS"));
            Path dir    = Paths.get(Config.SCREENSHOTS, testFolder);
            Files.createDirectories(dir);
            Path dest   = dir.resolve(sanitize(prefix) + "_" + ts + ".png");

            byte[] raw  = ((TakesScreenshot) driver).getScreenshotAs(OutputType.BYTES);
            Files.write(dest, raw);
            System.out.println("[Screenshot] " + dest);
            return dest.toAbsolutePath().toString();
        } catch (Exception e) {
            System.err.println("[Screenshot] ERROR: " + e.getMessage());
            return null;
        }
    }

    /**
     * Toma captura al fallar un test; prefija con "FAILURE_".
     */
    public String takeOnFailure(String testName) {
        return take("FAILURE_" + testName);
    }

    /**
     * Embeds base64 screenshot para ExtentReports.
     */
    public String takeAsBase64() {
        try {
            return ((TakesScreenshot) driver).getScreenshotAs(OutputType.BASE64);
        } catch (Exception e) {
            return "";
        }
    }

    private static String sanitize(String s) {
        return s.replaceAll("[^a-zA-Z0-9_\\-]", "_");
    }
}
