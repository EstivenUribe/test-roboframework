package com.biblioteca.pages;

import org.openqa.selenium.*;

/**
 * Page Object: Gestión de Usuarios.
 * Cubre HU-005, HU-013, HU-014, HU-015, HU-016.
 */
public class UsersPage extends BasePage {

    private static final By TABLA_USUARIOS = By.xpath("//table | //*[@class[contains(.,'users') or contains(.,'usuarios')]]");
    private static final By BTN_EDITAR_1   = By.xpath("(//button[contains(text(),'Editar')])[1]");
    private static final By BTN_ELIMINAR_1 = By.xpath("(//button[contains(text(),'Eliminar')])[1]");
    private static final By BTN_GUARDAR    = By.xpath("//button[contains(text(),'Guardar')]");
    private static final By BTN_CANCELAR   = By.xpath("//button[contains(text(),'Cancelar')]");
    private static final By SEL_ROL        = By.xpath("//select[@name='rol' or @name='role']");
    private static final By BADGES_ROL     = By.xpath("//*[@class[contains(.,'badge') or contains(.,'rol')]]");

    public UsersPage(WebDriver driver) {
        super(driver);
    }

    public void waitForTable() {
        waitVisible(TABLA_USUARIOS);
    }

    public String getTableText() {
        return waitVisible(TABLA_USUARIOS).getText();
    }

    public void clickEditFirst() {
        click(BTN_EDITAR_1);
    }

    public void changeRol(String nuevoRol) {
        waitVisible(SEL_ROL);
        selectByVisibleText(SEL_ROL, nuevoRol);
    }

    public void saveChanges() {
        click(BTN_GUARDAR);
    }

    public void cancel() {
        click(BTN_CANCELAR);
    }

    public void editUserRole(String nuevoRol) {
        clickEditFirst();
        changeRol(nuevoRol);
        saveChanges();
    }

    public void clickDeleteLast() {
        java.util.List<WebElement> btns = driver.findElements(
            By.xpath("//button[contains(text(),'Eliminar')]"));
        if (!btns.isEmpty()) btns.get(btns.size() - 1).click();
    }

    public boolean areBadgesVisible() {
        return isPresent(BADGES_ROL);
    }
}
