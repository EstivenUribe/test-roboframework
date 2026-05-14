package com.biblioteca.pages;

import com.biblioteca.config.Config;
import org.openqa.selenium.*;
import org.openqa.selenium.support.ui.*;
import java.time.Duration;
import java.util.List;

/**
 * Clase base con utilidades comunes para todos los Page Objects.
 * Aplica el patrón Page Object Model (POM).
 */
public abstract class BasePage {

    protected final WebDriver driver;
    protected final WebDriverWait wait;

    public BasePage(WebDriver driver) {
        this.driver = driver;
        this.wait   = new WebDriverWait(driver, Duration.ofSeconds(Config.TIMEOUT_EXPLICIT));
    }

    // ── Espera explícita ───────────────────────────────────────────────────

    protected WebElement waitVisible(By locator) {
        return wait.until(ExpectedConditions.visibilityOfElementLocated(locator));
    }

    protected WebElement waitClickable(By locator) {
        return wait.until(ExpectedConditions.elementToBeClickable(locator));
    }

    protected void waitInvisible(By locator) {
        wait.until(ExpectedConditions.invisibilityOfElementLocated(locator));
    }

    protected boolean isPresent(By locator) {
        try {
            driver.findElement(locator);
            return true;
        } catch (NoSuchElementException e) {
            return false;
        }
    }

    // ── Interacciones de alto nivel ─────────────────────────────────────────

    protected void clearAndType(By locator, String text) {
        WebElement el = waitVisible(locator);
        el.clear();
        el.sendKeys(text);
    }

    protected void click(By locator) {
        waitClickable(locator).click();
    }

    protected String getText(By locator) {
        return waitVisible(locator).getText().trim();
    }

    protected void selectByVisibleText(By locator, String text) {
        new Select(waitVisible(locator)).selectByVisibleText(text);
    }

    // ── Utilidades de página ───────────────────────────────────────────────

    protected void navigate(String path) {
        driver.get(Config.BASE_URL + path);
    }

    protected String currentUrl() {
        return driver.getCurrentUrl();
    }

    protected void scrollToTop() {
        ((JavascriptExecutor) driver).executeScript("window.scrollTo(0,0)");
    }

    public String getLocalStorageItem(String key) {
        return (String) ((JavascriptExecutor) driver)
            .executeScript("return localStorage.getItem(arguments[0]);", key);
    }

    // ── Toast / notificaciones ─────────────────────────────────────────────

    private static final By TOAST_LOCATOR = By.xpath(
        "//*[contains(@class,'Toastify__toast') or contains(@class,'toast') " +
        "or contains(@class,'notification') or contains(@class,'alert')]" +
        "[string-length(normalize-space(text()))>0 or " +
        "string-length(normalize-space(.))>0]"
    );

    public String waitForToast() {
        WebElement toast = waitVisible(TOAST_LOCATOR);
        return toast.getText().trim();
    }

    public boolean toastContains(String fragment) {
        try {
            String msg = waitForToast();
            return msg.toLowerCase().contains(fragment.toLowerCase());
        } catch (TimeoutException e) {
            return false;
        }
    }

    // ── Modal de confirmación ──────────────────────────────────────────────

    private static final By MODAL_CONFIRM = By.xpath(
        "//button[contains(translate(text(),'SÍSI','sísi'),'í') " +
        "or contains(text(),'Confirmar') or contains(text(),'eliminar')]"
    );
    private static final By MODAL_CANCEL = By.xpath(
        "//button[contains(text(),'Cancelar') or contains(text(),'No')]"
    );

    public void confirmModal() {
        click(MODAL_CONFIRM);
    }

    public void cancelModal() {
        click(MODAL_CANCEL);
    }

    // ── Errores de validación ──────────────────────────────────────────────

    public boolean hasValidationError() {
        List<WebElement> errors = driver.findElements(By.xpath(
            "//*[contains(@class,'error') or contains(@class,'invalid') " +
            "or contains(@class,'danger')][string-length(normalize-space(.))>0]"
        ));
        return !errors.isEmpty();
    }

    public String getValidationErrorText() {
        return getText(By.xpath(
            "(//*[contains(@class,'error') or contains(@class,'invalid') " +
            "or contains(@class,'danger')][string-length(normalize-space(.))>0])[1]"
        ));
    }
}
