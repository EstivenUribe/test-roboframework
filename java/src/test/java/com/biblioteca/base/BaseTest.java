package com.biblioteca.base;

import com.aventstack.extentreports.*;
import com.aventstack.extentreports.reporter.ExtentSparkReporter;
import com.biblioteca.config.Config;
import com.biblioteca.pages.*;
import com.biblioteca.utils.*;
import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.testng.ITestResult;
import org.testng.annotations.*;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Clase base para todos los tests. Gestiona:
 * - Ciclo de vida de ChromeDriver
 * - VideoRecorder (GIF animado por test)
 * - ScreenshotUtils (capture en fallos y pasos clave)
 * - ExcelReader (datos de prueba compartidos)
 * - ExtentReports (HTML report)
 * - Page Objects pre-construidos
 */
public abstract class BaseTest {

    // ── WebDriver & utilidades ────────────────────────────────────────────
    protected WebDriver       driver;
    protected ScreenshotUtils screenshots;
    protected VideoRecorder   video;
    protected ExcelReader     excel;

    // ── Page Objects ───────────────────────────────────────────────────────
    protected LoginPage    loginPage;
    protected RegisterPage registerPage;
    protected PanelPage    panelPage;
    protected CatalogPage  catalogPage;
    protected DashboardPage dashboardPage;
    protected UsersPage    usersPage;

    // ── Extent Reports ─────────────────────────────────────────────────────
    protected static ExtentReports extent;
    protected ExtentTest test;

    // ── Parámetros TestNG ──────────────────────────────────────────────────
    @Parameters({"browser", "headless"})
    @BeforeSuite(alwaysRun = true)
    public void initSuite(
            @Optional("chrome") String browser,
            @Optional("false")  String headless) throws IOException {

        Files.createDirectories(Paths.get(Config.SCREENSHOTS));
        Files.createDirectories(Paths.get(Config.VIDEOS));
        Files.createDirectories(Paths.get(Config.REPORTS));

        String ts = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        ExtentSparkReporter spark = new ExtentSparkReporter(
            Config.REPORTS + "/report_" + ts + ".html");
        spark.config().setDocumentTitle("Biblioteca Pro — Test Report");
        spark.config().setReportName("Automatización Selenium Java");
        extent = new ExtentReports();
        extent.attachReporter(spark);
        extent.setSystemInfo("URL",       Config.BASE_URL);
        extent.setSystemInfo("Browser",   browser);
        extent.setSystemInfo("Ejecutado", LocalDateTime.now().toString());
    }

    @BeforeMethod(alwaysRun = true)
    public void setUp(java.lang.reflect.Method method) throws IOException {
        // Configurar ChromeDriver
        WebDriverManager.chromedriver().setup();
        ChromeOptions opts = new ChromeOptions();
        opts.addArguments("--start-maximized");
        opts.addArguments("--disable-notifications");
        opts.addArguments("--disable-popup-blocking");
        // opts.addArguments("--headless=new");  // descomentar para CI

        driver = new ChromeDriver(opts);
        driver.manage().timeouts()
            .implicitlyWait(java.time.Duration.ofSeconds(Config.TIMEOUT_IMPLICIT));

        // Utilidades
        String name    = method.getName();
        screenshots    = new ScreenshotUtils(driver, name);
        video          = new VideoRecorder(driver, name);

        // Excel
        try {
            excel = new ExcelReader(Config.EXCEL_PATH);
        } catch (IOException e) {
            System.err.println("[BaseTest] Excel no encontrado: " + Config.EXCEL_PATH);
        }

        // Page objects
        loginPage     = new LoginPage(driver);
        registerPage  = new RegisterPage(driver);
        panelPage     = new PanelPage(driver);
        catalogPage   = new CatalogPage(driver);
        dashboardPage = new DashboardPage(driver);
        usersPage     = new UsersPage(driver);

        // ExtentReports test node
        test = extent.createTest(name);
        test.info("Iniciando test: " + name);

        // Iniciar grabación de video
        video.start();
        screenshots.take("00_inicio_" + name);
    }

    @AfterMethod(alwaysRun = true)
    public void tearDown(ITestResult result) {
        // Captura final
        String label = result.isSuccess() ? "99_exito" : "99_fallo";
        String path  = screenshots.take(label + "_" + result.getName());

        // ExtentReports: adjuntar screenshot y estado
        try {
            String b64 = screenshots.takeAsBase64();
            if (!b64.isEmpty() && test != null) {
                test.addScreenCaptureFromBase64String(b64, label);
            }
            if (result.isSuccess()) {
                test.pass("Test PASADO");
            } else {
                test.fail("Test FALLADO: " + result.getThrowable().getMessage());
                test.fail(com.aventstack.extentreports.MediaEntityBuilder
                    .createScreenCaptureFromBase64String(b64).build());
            }
        } catch (Exception ignored) {}

        // Detener video
        video.stop();

        // Cerrar driver
        if (driver != null) {
            driver.quit();
            driver = null;
        }
    }

    @AfterSuite(alwaysRun = true)
    public void flushReports() {
        if (extent != null) extent.flush();
        System.out.println("[BaseTest] Reporte generado en: " + Config.REPORTS);
    }

    // ── Helpers de test ───────────────────────────────────────────────────

    protected void loginAsAdmin() {
        loginPage.loginAsAdmin();
        panelPage.waitForPanel();
        screenshots.take("login_admin_exitoso");
        test.info("Login como admin completado");
    }

    protected void step(String description) {
        screenshots.take(description.replaceAll("\\s+", "_").toLowerCase());
        if (test != null) test.info(description);
    }

    protected void sleep(int ms) {
        try { Thread.sleep(ms); } catch (InterruptedException ignored) {}
    }
}
