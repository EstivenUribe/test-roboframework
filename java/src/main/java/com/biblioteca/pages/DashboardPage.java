package com.biblioteca.pages;

import org.openqa.selenium.*;

/**
 * Page Object: Dashboard y Estadísticas.
 * Cubre HU-011 y HU-012.
 */
public class DashboardPage extends BasePage {

    private static final By SEL_FILTRO   = By.xpath("(//select)[1]");
    private static final By BTN_GENERAR  = By.xpath("//button[contains(text(),'Generar')]");
    private static final By BTN_SYNC     = By.xpath("//button[contains(text(),'Sincronizar') or contains(text(),'↻')]");
    private static final By GRAFICO      = By.xpath("//*[contains(@class,'chart') or name()='canvas' or contains(@class,'dona')]");

    public DashboardPage(WebDriver driver) {
        super(driver);
    }

    public void waitForDashboard() {
        waitVisible(BTN_GENERAR);
    }

    public void selectFilter(String filtro) {
        selectByVisibleText(SEL_FILTRO, filtro);
    }

    public void clickGenerar() {
        click(BTN_GENERAR);
        try { Thread.sleep(2000); } catch (InterruptedException ignored) {}
    }

    public void clickSincronizar() {
        click(BTN_SYNC);
        try { Thread.sleep(2500); } catch (InterruptedException ignored) {}
    }

    public boolean isChartVisible() {
        return isPresent(GRAFICO);
    }

    public boolean isGenerarDisabled() {
        try {
            String disabled = driver.findElement(BTN_GENERAR).getAttribute("disabled");
            return disabled != null;
        } catch (Exception e) {
            return false;
        }
    }

    public void generateChart(String filtro) {
        selectFilter(filtro);
        clickGenerar();
    }
}
