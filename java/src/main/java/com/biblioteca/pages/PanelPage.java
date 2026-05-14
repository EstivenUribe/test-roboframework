package com.biblioteca.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

/**
 * Page Object: Panel Principal después del login.
 * Cubre HU-003 (logout), HU-004 (roles/tarjetas visibles).
 */
public class PanelPage extends BasePage {

    private static final By BTN_SALIR     = By.xpath("//button[contains(text(),'Salir') or contains(text(),'Cerrar')]");
    private static final By CARD_CATALOGO = By.xpath("//*[contains(text(),'Catálogo') or contains(text(),'catalogo')]");
    private static final By CARD_TIPOS    = By.xpath("//*[contains(text(),'Géneros') or contains(text(),'Tipos')]");
    private static final By CARD_DASHBOARD= By.xpath("//*[contains(text(),'Dashboard') or contains(text(),'Estadísticas') or contains(text(),'Buscar')]");
    private static final By CARD_USUARIOS = By.xpath("//*[contains(text(),'Usuario') and not(contains(text(),'Cerrar'))]");
    private static final By CARD_REDIS    = By.xpath("//*[contains(text(),'Redis') or contains(text(),'Caché')]");
    private static final By BADGE_ROL     = By.xpath("//*[contains(@class,'badge') or contains(text(),'admin') or contains(text(),'bibliotecario') or contains(text(),'lector')]");

    public PanelPage(WebDriver driver) {
        super(driver);
    }

    public void waitForPanel() {
        waitVisible(CARD_CATALOGO);
    }

    public void goToCatalog() {
        click(CARD_CATALOGO);
    }

    public void goToTypesGenres() {
        click(CARD_TIPOS);
    }

    public void goToDashboard() {
        click(CARD_DASHBOARD);
    }

    public void goToUsers() {
        click(CARD_USUARIOS);
    }

    public void clickRedisCard() {
        click(CARD_REDIS);
    }

    public void logout() {
        click(BTN_SALIR);
        waitVisible(By.xpath("//input[@type='email']"));
    }

    public boolean isRolBadgeVisible() {
        return isPresent(BADGE_ROL);
    }

    public boolean isUsersCardVisible() {
        return isPresent(CARD_USUARIOS);
    }

    public boolean isRedisCardVisible() {
        return isPresent(CARD_REDIS);
    }

    public boolean isTypesCardVisible() {
        return isPresent(CARD_TIPOS);
    }
}
